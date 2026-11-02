"""
generate_pings.py — GPS pings as JSONL events (one per active driver per minute).
"""

import json
import uuid
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from tqdm import tqdm


def generate_pings(out_dir, n, drivers_df, trips_df, seed=42):
    rng = np.random.default_rng(seed + 2)

    driver_ids = drivers_df["driver_id"].to_numpy()
    activity   = drivers_df["_activity"].to_numpy()
    activity_w = activity / activity.sum()

    today = datetime(2025, 12, 31)
    earliest = datetime(2025, 11, 1)        # ~2-month ping window

    fname = out_dir / "raw_location_pings.jsonl"
    print(f"  generating {n:,} location pings → {fname.name} …")

    chosen = rng.choice(len(driver_ids), size=n, p=activity_w)

    with open(fname, "w") as f:
        for i in tqdm(range(n), unit="pings", ncols=80):
            did = int(driver_ids[int(chosen[i])])
            seconds_offset = int(rng.integers(0, int((today - earliest).total_seconds())))
            ping_ts = earliest + timedelta(seconds=seconds_offset)
            payload = {
                "lat":         round(float(rng.uniform(8.5, 28.7)), 6),
                "lng":         round(float(rng.uniform(72.5, 88.4)), 6),
                "speed_kmph":  round(float(rng.uniform(0, 80)), 2),
                "heading":     int(rng.integers(0, 360)),
                "is_on_trip":  bool(rng.random() < 0.55),
                "battery_pct": int(rng.integers(15, 100)),
            }
            event = {
                "ping_id":        uuid.uuid4().hex,
                "driver_id":      did,
                "ping_timestamp": ping_ts.isoformat(),
                "payload":        payload,
            }
            f.write(json.dumps(event) + "\n")

    print(f"  ✓ {fname.name}")
