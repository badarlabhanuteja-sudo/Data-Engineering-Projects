"""
generate_trips.py — Realistic ride-sharing trips with surge-pricing,
peak-hour patterns, and weekly seasonality.
"""

import pandas as pd
import numpy as np
import uuid
from datetime import datetime, timedelta
from tqdm import tqdm

from generate_cities import CITIES

PAYMENT_METHODS = ["upi", "credit_card", "debit_card", "wallet", "cash"]
PAYMENT_PROBS   = [0.45, 0.20, 0.15, 0.12, 0.08]

VEHICLE_BASE_FARES = {     # base fare per km per vehicle type, in INR
    "auto":     8.0,
    "mini":     12.0,
    "sedan":    16.0,
    "suv":      22.0,
    "electric": 14.0,
}


def _surge_multiplier(hour, dow, rng):
    """Realistic surge model: high during peak hours and weekends."""
    base = 1.0
    # morning peak (8-10am)
    if 8 <= hour < 10:   base += rng.uniform(0.2, 0.8)
    # evening peak (5-9pm)
    elif 17 <= hour < 21: base += rng.uniform(0.3, 1.5)
    # late night (10pm-2am)
    elif hour >= 22 or hour < 2: base += rng.uniform(0.0, 0.5)
    # weekend bump
    if dow >= 5: base += rng.uniform(0.0, 0.3)
    return round(min(3.5, base), 2)


def generate_trips_and_payments(out_dir, n, drivers_df, riders_df, cities_df, seed=42):
    rng = np.random.default_rng(seed)

    # Coords for each city
    city_coords = {c[0]: (c[6], c[7]) for c in CITIES}

    rider_ids = riders_df["rider_id"].to_numpy()
    rider_props = riders_df["_propensity"].to_numpy()
    rider_weights = (1.0 - rider_props); rider_weights /= rider_weights.sum()
    rider_home = riders_df["home_city_id"].to_numpy()

    driver_ids = drivers_df["driver_id"].to_numpy()
    driver_act = drivers_df["_activity"].to_numpy()
    driver_act_w = driver_act / driver_act.sum()
    driver_home = drivers_df["home_city_id"].to_numpy()
    driver_vt = drivers_df["vehicle_type"].to_numpy()

    today = datetime(2025, 12, 31)
    earliest = datetime(2025, 6, 1)        # 7-month trip window

    print(f"  generating {n:,} trips …")

    trip_rows = []
    payment_rows = []

    chosen_riders  = rng.choice(len(rider_ids),  size=n, p=rider_weights)
    chosen_drivers = rng.choice(len(driver_ids), size=n, p=driver_act_w)

    for tid in tqdm(range(1, n + 1), unit="trips", ncols=80):
        rix = int(chosen_riders[tid - 1])
        dix = int(chosen_drivers[tid - 1])

        rid = int(rider_ids[rix])
        did = int(driver_ids[dix])
        # Use rider's home city most of the time
        cid = int(rider_home[rix]) if rng.random() < 0.85 else int(rng.choice(cities_df["city_id"].values))
        clat, clng = city_coords[cid]

        # Random timestamp in the window
        seconds_offset = int(rng.integers(0, int((today - earliest).total_seconds())))
        request_ts = earliest + timedelta(seconds=seconds_offset)

        hour = request_ts.hour
        dow  = request_ts.weekday()
        surge = _surge_multiplier(hour, dow, rng)

        # Pickup near city center (within ~10km)
        pickup_lat = round(clat + float(rng.normal(0, 0.05)), 6)
        pickup_lng = round(clng + float(rng.normal(0, 0.05)), 6)
        # Dropoff: same area but offset
        distance_km = round(float(max(0.5, rng.exponential(5.0))), 2)
        bearing = float(rng.uniform(0, 360))
        # crude lat/lng offset
        dropoff_lat = round(pickup_lat + (distance_km * np.cos(np.radians(bearing)) * 0.009), 6)
        dropoff_lng = round(pickup_lng + (distance_km * np.sin(np.radians(bearing)) * 0.009), 6)

        # Trip duration in minutes — average 25 km/h in city
        duration_min = round(distance_km / 25.0 * 60.0 * (1.0 + float(rng.uniform(0, 0.3))), 1)

        accept_delay = int(rng.exponential(60))      # seconds
        pickup_ts  = request_ts + timedelta(seconds=accept_delay)
        dropoff_ts = pickup_ts + timedelta(minutes=duration_min)

        vehicle_type = str(driver_vt[dix])
        per_km = VEHICLE_BASE_FARES.get(vehicle_type, 12.0)
        base_fare = round(per_km * distance_km + 30.0, 2)
        final_fare = round(base_fare * surge, 2)

        # Trip status
        status = str(rng.choice(["completed", "completed", "completed", "completed",
                                  "cancelled"], p=[0.85, 0.04, 0.04, 0.04, 0.03]))

        rating_rider = round(float(rng.uniform(3.5, 5.0)), 2) if status == "completed" else None
        rating_drv   = round(float(rng.uniform(3.5, 5.0)), 2) if status == "completed" else None

        pm = str(rng.choice(PAYMENT_METHODS, p=PAYMENT_PROBS))
        trip_rows.append({
            "trip_id":          tid,
            "rider_id":         rid,
            "driver_id":        did,
            "city_id":          cid,
            "request_timestamp": request_ts.isoformat(),
            "pickup_timestamp":  pickup_ts.isoformat() if status != "cancelled" else None,
            "dropoff_timestamp": dropoff_ts.isoformat() if status == "completed" else None,
            "pickup_lat":       pickup_lat,
            "pickup_lng":       pickup_lng,
            "dropoff_lat":      dropoff_lat if status == "completed" else None,
            "dropoff_lng":      dropoff_lng if status == "completed" else None,
            "distance_km":      distance_km if status == "completed" else None,
            "duration_min":     duration_min if status == "completed" else None,
            "base_fare":        base_fare,
            "surge_multiplier": surge,
            "final_fare":       final_fare if status == "completed" else 0.0,
            "payment_method":   pm,
            "trip_status":      status,
            "rating_by_rider":  rating_rider,
            "rating_by_driver": rating_drv,
            "created_at":       request_ts.isoformat(),
            "updated_at":       (dropoff_ts if status == "completed" else request_ts).isoformat(),
        })

        # Payment record (only for completed)
        if status == "completed":
            pay_status = str(rng.choice(["success", "failed", "refunded"], p=[0.95, 0.04, 0.01]))
            payment_rows.append({
                "payment_id":        uuid.uuid4().hex,
                "trip_id":           tid,
                "payment_status":    pay_status,
                "amount":            final_fare if pay_status == "success" else 0.0,
                "payment_method":    pm,
                "payment_timestamp": (dropoff_ts + timedelta(seconds=int(rng.integers(1, 60)))).isoformat(),
                "failure_reason":    None if pay_status == "success" else str(rng.choice(["insufficient_balance", "network_error", "user_cancelled"])),
            })

    print(f"  writing {len(trip_rows):,} trips and {len(payment_rows):,} payments …")
    pd.DataFrame(trip_rows).to_csv(out_dir / "raw_trips.csv", index=False)
    pd.DataFrame(payment_rows).to_csv(out_dir / "raw_payments.csv", index=False)
    print(f"  ✓ raw_trips.csv, raw_payments.csv")
    return pd.DataFrame(trip_rows)
