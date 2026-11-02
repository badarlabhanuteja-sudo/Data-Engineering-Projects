"""generate_users.py — synthetic user master."""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from faker import Faker


COUNTRIES = ["IN", "US", "GB", "BR", "JP", "DE", "FR", "MX", "CA", "AU"]
COUNTRY_PROBS = [0.30, 0.20, 0.10, 0.08, 0.06, 0.05, 0.05, 0.05, 0.06, 0.05]

PLAN_TIERS    = ["basic", "standard", "premium", "family"]
PLAN_PROBS    = [0.30, 0.40, 0.20, 0.10]

AGE_BANDS = ["18-24", "25-34", "35-44", "45-54", "55-64", "65+"]
AGE_PROBS = [0.18, 0.30, 0.22, 0.15, 0.10, 0.05]


def generate_users(out_dir, n, seed=42):
    rng  = np.random.default_rng(seed)
    fake = Faker(); Faker.seed(seed)

    today = datetime(2025, 12, 31).date()
    earliest = datetime(2022, 1, 1).date()

    rows = []
    for uid in range(1, n + 1):
        signup = earliest + timedelta(days=int(rng.integers(0, (today - earliest).days)))
        plan = str(rng.choice(PLAN_TIERS, p=PLAN_PROBS))
        rows.append({
            "user_id":           uid,
            "email":             fake.email(),
            "country":           str(rng.choice(COUNTRIES, p=COUNTRY_PROBS)),
            "plan_tier":         plan,
            "signup_date":       signup.isoformat(),
            "is_active":         bool(rng.random() < 0.85),
            "age_band":          str(rng.choice(AGE_BANDS, p=AGE_PROBS)),
            "profile_count":     int({"basic": 1, "standard": 2, "premium": 4, "family": 5}[plan]),
            "preferred_language": str(rng.choice(["en", "hi", "es", "fr", "ja"], p=[0.55, 0.15, 0.10, 0.10, 0.10])),
            "created_at":        datetime.combine(signup, datetime.min.time()).isoformat(),
            "updated_at":        datetime.combine(signup, datetime.min.time()).isoformat(),
            "_activity":         float(rng.beta(2.5, 2)),  # engagement weight
        })

    df = pd.DataFrame(rows)
    df.to_parquet(out_dir / "_users_with_activity.parquet", index=False)
    df.drop(columns=["_activity"]).to_csv(out_dir / "raw_users.csv", index=False)
    print(f"  ✓ raw_users.csv           {len(df):,}")
    return df
