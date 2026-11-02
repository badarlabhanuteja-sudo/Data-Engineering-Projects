"""
generate_email_events.py
Synthetic email-marketing engagement events.
Higher-tier customers and lower-churn-propensity customers engage more.
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from tqdm import tqdm
import uuid


CAMPAIGN_TYPES = ["welcome", "weekly_newsletter", "promotion", "abandonment", "winback", "loyalty"]


def generate_email_events(out_dir, n, customers_df, seed=42):
    rng = np.random.default_rng(seed)

    customer_ids = customers_df["customer_id"].to_numpy()
    is_subscriber = customers_df["is_email_subscriber"].to_numpy()
    propensity   = customers_df["_churn_propensity"].to_numpy()
    signup_dates = pd.to_datetime(customers_df["signup_date"]).dt.date.to_numpy()

    # Activity weight: only subscribers; weighted by inverse churn
    weight = (1.0 - propensity) * is_subscriber.astype(float)
    if weight.sum() == 0:
        return
    weight = weight / weight.sum()

    today = datetime(2025, 12, 31).date()

    rows = []
    chosen = rng.choice(len(customer_ids), size=n, p=weight)
    for i in tqdm(range(n), unit="emails", ncols=80, desc="email events"):
        cust_idx = int(chosen[i])
        cid = int(customer_ids[cust_idx])
        signup = signup_dates[cust_idx]
        max_horizon = (today - signup).days
        if max_horizon < 1:
            continue
        evt_date = signup + timedelta(days=int(rng.uniform(0, max_horizon)))
        evt_ts = datetime.combine(evt_date, datetime.min.time()) + timedelta(
            hours=int(rng.integers(6, 23)),
            minutes=int(rng.integers(0, 60))
        )
        etype = str(rng.choice(["sent", "open", "click", "unsubscribe"], p=[0.50, 0.30, 0.18, 0.02]))
        camp_type = str(rng.choice(CAMPAIGN_TYPES))
        rows.append({
            "email_event_id": uuid.uuid4().hex,
            "customer_id": cid,
            "campaign_id": f"camp_{camp_type}_{evt_date.strftime('%Y%m')}",
            "event_type": etype,
            "event_timestamp": evt_ts.isoformat(),
            "subject_line": f"{camp_type.title()} — {evt_date.strftime('%b %Y')}"
        })

    df = pd.DataFrame(rows)
    df.to_csv(out_dir / "raw_email_events.csv", index=False)
    print(f"  wrote {len(df):,} email events → raw_email_events.csv")
