"""
generate_drivers_riders.py — Indian-locale drivers and riders.
"""

import pandas as pd
import numpy as np
from faker import Faker
from datetime import datetime, timedelta


VEHICLE_TYPES   = ["auto", "mini", "sedan", "suv", "electric"]
VEHICLE_PROBS   = [0.35,  0.40,   0.15,    0.05,  0.05]
DRIVER_STATUSES = ["active", "active", "active", "inactive", "suspended"]
RIDER_TIERS     = ["bronze", "silver", "gold", "platinum"]
RIDER_TIER_PROBS = [0.55, 0.30, 0.12, 0.03]


def generate_drivers(out_dir, n, cities_df, seed=42):
    rng  = np.random.default_rng(seed)
    fake = Faker("en_IN")
    Faker.seed(seed)

    today = datetime(2025, 12, 31).date()
    earliest = datetime(2022, 1, 1).date()

    rows = []
    for did in range(1, n + 1):
        first = fake.first_name()
        last  = fake.last_name()
        onboard = earliest + timedelta(days=int(rng.integers(0, (today - earliest).days)))
        rows.append({
            "driver_id":      did,
            "first_name":     first,
            "last_name":      last,
            "phone":          fake.phone_number()[:20],
            "license_number": f"DL{rng.integers(10000000, 99999999)}",
            "vehicle_type":   str(rng.choice(VEHICLE_TYPES, p=VEHICLE_PROBS)),
            "vehicle_number": f"{str(rng.choice(['MH','DL','KA','TN','WB','TG','GJ','RJ','KL'])):s}{rng.integers(1, 99):02d}{chr(rng.integers(65,91))}{chr(rng.integers(65,91))}{rng.integers(1000,9999)}",
            "rating":         round(float(rng.uniform(3.5, 5.0)), 2),
            "home_city_id":   int(rng.choice(cities_df["city_id"].values)),
            "onboarding_date": onboard.isoformat(),
            "status":         str(rng.choice(DRIVER_STATUSES, p=[0.4, 0.4, 0.1, 0.07, 0.03])),
            "is_active":      bool(rng.random() < 0.85),
            "created_at":     datetime.combine(onboard, datetime.min.time()).isoformat(),
            "updated_at":     datetime.combine(onboard, datetime.min.time()).isoformat(),
            "_activity":      float(rng.beta(3, 2)),    # internal: drives trip-frequency
        })

    df = pd.DataFrame(rows)
    df.to_parquet(out_dir / "_drivers_with_activity.parquet", index=False)
    df.drop(columns=["_activity"]).to_csv(out_dir / "raw_drivers.csv", index=False)
    print(f"  wrote {len(df):,} drivers → raw_drivers.csv")
    return df


def generate_riders(out_dir, n, cities_df, seed=42):
    rng  = np.random.default_rng(seed + 1)
    fake = Faker("en_IN")
    Faker.seed(seed + 1)

    today = datetime(2025, 12, 31).date()
    earliest = datetime(2022, 1, 1).date()

    rows = []
    for rid in range(1, n + 1):
        first = fake.first_name()
        last  = fake.last_name()
        signup = earliest + timedelta(days=int(rng.integers(0, (today - earliest).days)))
        rows.append({
            "rider_id":     rid,
            "first_name":   first,
            "last_name":    last,
            "email":        f"{first.lower()}.{last.lower()}.{rid}@example.in",
            "phone":        fake.phone_number()[:20],
            "home_city_id": int(rng.choice(cities_df["city_id"].values)),
            "signup_date":  signup.isoformat(),
            "rider_tier":   str(rng.choice(RIDER_TIERS, p=RIDER_TIER_PROBS)),
            "is_active":    bool(rng.random() < 0.90),
            "created_at":   datetime.combine(signup, datetime.min.time()).isoformat(),
            "updated_at":   datetime.combine(signup, datetime.min.time()).isoformat(),
            "_propensity":  float(rng.beta(2, 4)),
        })

    df = pd.DataFrame(rows)
    df.to_parquet(out_dir / "_riders_with_propensity.parquet", index=False)
    df.drop(columns=["_propensity"]).to_csv(out_dir / "raw_riders.csv", index=False)
    print(f"  wrote {len(df):,} riders → raw_riders.csv")
    return df
