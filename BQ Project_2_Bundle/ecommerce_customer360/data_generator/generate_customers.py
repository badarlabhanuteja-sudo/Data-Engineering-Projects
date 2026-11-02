"""
generate_customers.py
Synthetic customer master with realistic acquisition curve and churn signal.

Embeds a churn-propensity attribute that downstream order/event generation
respects, so the rule-based-vs-ML comparison has a real signal to detect.
"""

import pandas as pd
import numpy as np
from faker import Faker
from datetime import datetime, timedelta


def generate_customers(out_dir, n, seed=42):
    rng = np.random.default_rng(seed)
    fake = Faker(["en_GB", "en_IN", "en_US"])
    Faker.seed(seed)

    today = datetime(2025, 12, 31).date()
    earliest_signup = datetime(2022, 1, 1).date()

    SIGNUP_CHANNELS = ["organic", "google_ads", "meta_ads", "email_referral",
                       "tiktok", "affiliate", "podcast", "direct"]
    TIERS = ["bronze", "silver", "gold", "platinum"]
    TIER_PROBS = [0.55, 0.30, 0.12, 0.03]

    rows = []
    for cid in range(1, n + 1):
        # Acquisition curve: growing month-over-month, with promotions spikes
        signup_offset = int(rng.beta(2.5, 1.5) * (today - earliest_signup).days)
        signup = earliest_signup + timedelta(days=signup_offset)

        gender = str(rng.choice(["M", "F", "non-binary", "undisclosed"], p=[0.46, 0.46, 0.04, 0.04]))
        if gender == "M":   first = fake.first_name_male()
        elif gender == "F": first = fake.first_name_female()
        else:               first = fake.first_name()

        last = fake.last_name()
        tier = str(rng.choice(TIERS, p=TIER_PROBS))

        rows.append({
            "customer_id": cid,
            "email": f"{first.lower()}.{last.lower()}.{cid}@example.com",
            "first_name": first,
            "last_name": last,
            "gender": gender,
            "date_of_birth": (today - timedelta(days=int(rng.integers(18*365, 75*365)))).isoformat(),
            "country": str(rng.choice(["IN", "GB", "US", "CA", "AU"], p=[0.5, 0.2, 0.2, 0.05, 0.05])),
            "state_or_region": fake.state(),
            "city": fake.city(),
            "postal_code": fake.postcode(),
            "signup_date": signup.isoformat(),
            "signup_channel": str(rng.choice(SIGNUP_CHANNELS)),
            "is_email_subscriber": bool(rng.random() < 0.78),
            "customer_tier": tier,
            "created_at": datetime.combine(signup, datetime.min.time()).isoformat(),
            "updated_at": datetime.combine(signup, datetime.min.time()).isoformat(),
            # internal — controls downstream churn behaviour. Not loaded.
            "_churn_propensity": float(rng.beta(2, 5))   # most customers low-churn
        })

    df = pd.DataFrame(rows)
    # Persist propensity for the order generator; do not load to Snowflake
    df.to_parquet(out_dir / "_customers_with_propensity.parquet", index=False)
    df.drop(columns=["_churn_propensity"]).to_csv(out_dir / "raw_customers.csv", index=False)
    print(f"  wrote {len(df):,} customers → raw_customers.csv")
    return df
