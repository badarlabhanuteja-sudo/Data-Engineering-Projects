"""
generate_clickstream.py
Synthetic web-event stream with realistic session structure.
Output: JSONL file (one JSON event per line) — mimics what would land in MinIO/S3.
"""

import json
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from tqdm import tqdm
import uuid

EVENT_TYPES = [
    ("page_view",        0.55),
    ("product_view",     0.20),
    ("search",           0.08),
    ("add_to_cart",      0.07),
    ("remove_from_cart", 0.02),
    ("begin_checkout",   0.04),
    ("complete_purchase", 0.02),
    ("login",            0.01),
    ("signup",           0.005),
    ("wishlist_add",     0.005),
]

DEVICES = ["desktop", "mobile_web", "ios_app", "android_app"]
DEVICE_PROBS = [0.30, 0.25, 0.22, 0.23]


def generate_web_events(out_dir, n, customers_df, products_df, seed=42):
    rng = np.random.default_rng(seed)

    customer_ids = customers_df["customer_id"].to_numpy()
    propensity   = customers_df["_churn_propensity"].to_numpy()
    activity_weight = 1.0 - propensity
    activity_weight = activity_weight / activity_weight.sum()

    product_ids = products_df["product_id"].to_numpy()
    signup_dates = pd.to_datetime(customers_df["signup_date"]).dt.date.to_numpy()

    today = datetime(2025, 12, 31).date()

    event_names = [t[0] for t in EVENT_TYPES]
    event_probs = [t[1] for t in EVENT_TYPES]

    fname = out_dir / "raw_web_events.jsonl"
    print(f"  generating {n:,} web events → {fname.name} …")

    chosen_customers = rng.choice(len(customer_ids), size=n, p=activity_weight)

    with open(fname, "w") as f:
        for i in tqdm(range(n), unit="evts", ncols=80):
            cust_idx = int(chosen_customers[i])
            cid = int(customer_ids[cust_idx])
            signup = signup_dates[cust_idx]
            max_horizon = (today - signup).days
            if max_horizon < 1:
                continue
            evt_date = signup + timedelta(days=int(rng.exponential(60)) % max(1, max_horizon))
            evt_ts = datetime.combine(evt_date, datetime.min.time()) + timedelta(
                hours=int(rng.integers(0, 24)),
                minutes=int(rng.integers(0, 60)),
                seconds=int(rng.integers(0, 60))
            )

            etype = str(rng.choice(event_names, p=event_probs))

            payload = {"device": str(rng.choice(DEVICES, p=DEVICE_PROBS))}
            if etype in ("product_view", "add_to_cart", "remove_from_cart", "wishlist_add"):
                payload["product_id"] = int(product_ids[int(rng.integers(0, len(product_ids)))])
            elif etype == "search":
                payload["query"] = str(rng.choice(["coffee", "shampoo", "milk", "diapers", "rice", "bread", "tea", "biscuits"]))
            elif etype in ("begin_checkout", "complete_purchase"):
                payload["cart_value"] = round(float(rng.uniform(100, 5000)), 2)
                payload["cart_size"] = int(rng.integers(1, 12))

            event = {
                "event_id": uuid.uuid4().hex,
                "customer_id": cid,
                "session_id": uuid.uuid4().hex[:16],
                "event_timestamp": evt_ts.isoformat(),
                "event_type": etype,
                "payload": payload,
                "user_agent": "Mozilla/5.0 …",
                "ip_address": f"10.{int(rng.integers(0,256))}.{int(rng.integers(0,256))}.{int(rng.integers(0,256))}",
                "referrer": str(rng.choice([None, "https://google.com", "https://facebook.com",
                                            "https://instagram.com", "direct"]))
            }
            f.write(json.dumps(event) + "\n")

    # Also produce a smaller CSV-friendly flat version for direct table loads
    # (Snowflake will COPY INTO from this for the demo path)
    print(f"  wrote {n:,} events → {fname.name}")
