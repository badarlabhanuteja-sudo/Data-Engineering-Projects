"""generate_ad_spend.py — Daily per-channel ad spend over the journey window."""

import uuid
import pandas as pd
import numpy as np
from datetime import datetime, timedelta


CHANNELS_PAID = ["google_ads", "meta_ads", "tiktok_ads"]


def generate_ad_spend(out_dir, seed=42):
    rng = np.random.default_rng(seed + 100)
    today    = datetime(2025, 12, 31).date()
    earliest = datetime(2025, 9, 1).date()

    rows = []
    cur = earliest
    while cur <= today:
        for ch in CHANNELS_PAID:
            base_spend = {"google_ads": 8000, "meta_ads": 6000, "tiktok_ads": 3000}[ch]
            # Weekly seasonality: weekends slightly lower for B2C, higher for content
            wd = cur.weekday()
            multiplier = 1.05 if wd in (4, 5, 6) else 0.98
            spend = round(float(rng.normal(base_spend * multiplier, base_spend * 0.15)), 2)
            spend = max(spend, 100.0)
            n_camps = int(rng.integers(2, 6))
            per_camp = spend / n_camps
            for k in range(n_camps):
                campaign_id = f"camp_{ch}_{cur.strftime('%Y%m')}"
                impressions = int(rng.integers(5000, 50000))
                clicks      = int(impressions * float(rng.uniform(0.005, 0.05)))
                rows.append({
                    "spend_id":     uuid.uuid4().hex,
                    "spend_date":   cur.isoformat(),
                    "channel":      ch,
                    "campaign_id":  f"{campaign_id}_{k}",
                    "spend_amount": round(per_camp, 2),
                    "impressions":  impressions,
                    "clicks":       clicks,
                })
        cur += timedelta(days=1)

    df = pd.DataFrame(rows)
    df.to_csv(out_dir / "raw_ad_spend.csv", index=False)
    print(f"  ✓ raw_ad_spend.csv         {len(df):,}")
