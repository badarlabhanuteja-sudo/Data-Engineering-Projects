"""
generate_journeys.py
Markov-chain user-journey simulator.

Each user has a sequence of touchpoints across channels (Google Ads, Meta,
TikTok, email, web), drawn from a transition matrix that gives realistic
funnel patterns. A subset of users converts; conversions get a revenue
amount drawn from a log-normal distribution.

This produces the per-channel CSV/JSONL files that map to the 6 RAW tables.
"""

import json
import uuid
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from tqdm import tqdm

CHANNELS = ["google_ads", "meta_ads", "tiktok_ads", "email", "web"]

# Transition matrix between channels (rows = from, cols = to + END).
# Row 'START' picks the entry channel.
# Higher diagonal = same-channel sticky; off-diagonal = cross-channel.
TRANSITION = {
    "START":     {"google_ads": 0.35, "meta_ads": 0.25, "tiktok_ads": 0.10, "email": 0.05, "web": 0.25},
    "google_ads":{"google_ads": 0.20, "meta_ads": 0.15, "tiktok_ads": 0.05, "email": 0.10, "web": 0.30, "END": 0.20},
    "meta_ads":  {"google_ads": 0.10, "meta_ads": 0.25, "tiktok_ads": 0.15, "email": 0.10, "web": 0.20, "END": 0.20},
    "tiktok_ads":{"google_ads": 0.10, "meta_ads": 0.20, "tiktok_ads": 0.20, "email": 0.05, "web": 0.20, "END": 0.25},
    "email":     {"google_ads": 0.05, "meta_ads": 0.10, "tiktok_ads": 0.05, "email": 0.10, "web": 0.50, "END": 0.20},
    "web":       {"google_ads": 0.05, "meta_ads": 0.10, "tiktok_ads": 0.05, "email": 0.05, "web": 0.20, "END": 0.55},
}


def _next_state(current, rng):
    options = TRANSITION[current]
    keys, probs = list(options.keys()), list(options.values())
    return str(rng.choice(keys, p=probs))


def generate_journeys(out_dir, n_users, n_touchpoints, n_conversions, seed=42):
    rng = np.random.default_rng(seed)

    # Approximate per-user touchpoint count
    avg_per_user = n_touchpoints / n_users
    today    = datetime(2025, 12, 31)
    earliest = datetime(2025, 9, 1)        # 4-month window

    google_rows, meta_rows, tiktok_rows, email_rows, web_rows = [], [], [], [], []
    conv_rows = []
    identity_rows = []

    converters = set(rng.choice(n_users, size=n_conversions, replace=False))
    print(f"  generating journeys for {n_users:,} users …")

    for u in tqdm(range(n_users), unit="users", ncols=80):
        user_id = f"user_{u:08d}"
        n_tp = max(1, int(rng.poisson(avg_per_user)))

        # journey timestamps roughly evenly distributed across window
        start_offset = int(rng.integers(0, int((today - earliest).total_seconds())))
        start_ts = earliest + timedelta(seconds=start_offset)

        # Walk the chain
        cur = "START"
        path = []
        for _ in range(n_tp):
            cur = _next_state(cur, rng)
            if cur == "END":
                break
            path.append(cur)

        if not path:
            path = [str(rng.choice(CHANNELS))]

        # Spread timestamps across path
        for i, ch in enumerate(path):
            offset = i * int(rng.exponential(3600 * 6))    # ~6h between touchpoints
            ts = start_ts + timedelta(seconds=offset)
            if ts > today:
                ts = today - timedelta(minutes=int(rng.integers(1, 1440)))

            campaign_id = f"camp_{ch}_{ts.strftime('%Y%m')}"
            event_id    = uuid.uuid4().hex
            cost = round(float(rng.uniform(0.10, 5.00)), 4) if ch != "email" and ch != "web" else 0.0

            common = (event_id, user_id, campaign_id, ts.isoformat())

            if ch == "google_ads":
                google_rows.append({
                    "google_event_id": event_id,
                    "user_id": user_id,
                    "google_click_id": uuid.uuid4().hex[:16],
                    "campaign_id": campaign_id,
                    "ad_group_id": f"adgrp_{int(rng.integers(1,100))}",
                    "creative_id": f"cre_{int(rng.integers(1,500))}",
                    "keyword": str(rng.choice(["coffee","shampoo","milk","laptop","bag","shoes"])),
                    "event_type": str(rng.choice(["impression","click"], p=[0.7, 0.3])),
                    "event_timestamp": ts.isoformat(),
                    "cost": cost,
                })
            elif ch == "meta_ads":
                meta_rows.append({
                    "meta_event_id": event_id,
                    "user_id": user_id,
                    "fbclid": uuid.uuid4().hex[:16],
                    "campaign_id": campaign_id,
                    "ad_set_id": f"adset_{int(rng.integers(1,100))}",
                    "ad_id": f"ad_{int(rng.integers(1,500))}",
                    "placement": str(rng.choice(["feed","stories","reels"])),
                    "event_type": str(rng.choice(["impression","click"], p=[0.7, 0.3])),
                    "event_timestamp": ts.isoformat(),
                    "cost": cost,
                })
            elif ch == "tiktok_ads":
                tiktok_rows.append({
                    "tiktok_event_id": event_id,
                    "user_id": user_id,
                    "ttclid": uuid.uuid4().hex[:16],
                    "campaign_id": campaign_id,
                    "ad_group_id": f"ttgrp_{int(rng.integers(1,100))}",
                    "creative_id": f"ttcre_{int(rng.integers(1,500))}",
                    "event_type": str(rng.choice(["impression","click","view"], p=[0.6, 0.2, 0.2])),
                    "event_timestamp": ts.isoformat(),
                    "cost": cost,
                })
            elif ch == "email":
                email_rows.append({
                    "email_event_id": event_id,
                    "user_id": user_id,
                    "campaign_id": campaign_id,
                    "event_type": str(rng.choice(["sent","open","click"], p=[0.55, 0.30, 0.15])),
                    "event_timestamp": ts.isoformat(),
                    "subject_line": f"{ts.strftime('%b %Y')} newsletter",
                })
            elif ch == "web":
                web_rows.append({
                    "event_id": event_id,
                    "user_id": user_id,
                    "session_id": uuid.uuid4().hex[:16],
                    "event_type": str(rng.choice(["page_view","product_view","add_to_cart"], p=[0.7, 0.25, 0.05])),
                    "page_url": f"https://shop.example.com/path/{int(rng.integers(1, 1000))}",
                    "referrer": str(rng.choice(["direct","https://google.com","https://facebook.com","https://tiktok.com"])),
                    "utm_source": ch,
                    "utm_medium": str(rng.choice(["organic","cpc","social"])),
                    "utm_campaign": campaign_id,
                    "event_timestamp": ts.isoformat(),
                    "payload": json.dumps({"device": str(rng.choice(["desktop","mobile","tablet"]))}),
                })

        # Identity row
        identity_rows.append({
            "user_id": user_id,
            "canonical_user_id": user_id,
            "email_hash": uuid.uuid4().hex,
            "first_seen_at": start_ts.isoformat(),
            "last_seen_at":  (start_ts + timedelta(days=int(rng.integers(0, 90)))).isoformat(),
        })

        # Conversion (if applicable) — happens AFTER the last touchpoint
        if u in converters:
            last_ts = start_ts + timedelta(seconds=int(rng.integers(3600, 86400 * 14)))
            if last_ts > today:
                last_ts = today - timedelta(minutes=int(rng.integers(1, 1440)))
            revenue = round(float(rng.lognormal(mean=6.5, sigma=0.8)), 2)   # ~INR 600-3000
            conv_rows.append({
                "conversion_id": uuid.uuid4().hex,
                "user_id": user_id,
                "conversion_type": str(rng.choice(["purchase","signup","lead"], p=[0.7, 0.2, 0.1])),
                "revenue": revenue,
                "conversion_timestamp": last_ts.isoformat(),
            })

    # Write all to disk
    pd.DataFrame(google_rows).to_csv(out_dir / "raw_google_ads.csv", index=False)
    pd.DataFrame(meta_rows).to_csv(out_dir / "raw_meta_ads.csv", index=False)
    pd.DataFrame(tiktok_rows).to_csv(out_dir / "raw_tiktok_ads.csv", index=False)
    pd.DataFrame(email_rows).to_csv(out_dir / "raw_email_events.csv", index=False)
    pd.DataFrame(web_rows).to_csv(out_dir / "raw_web_events.csv", index=False)
    pd.DataFrame(conv_rows).to_csv(out_dir / "raw_conversions.csv", index=False)
    pd.DataFrame(identity_rows).to_csv(out_dir / "raw_user_identity.csv", index=False)

    print(f"  ✓ raw_google_ads.csv     {len(google_rows):,}")
    print(f"  ✓ raw_meta_ads.csv       {len(meta_rows):,}")
    print(f"  ✓ raw_tiktok_ads.csv     {len(tiktok_rows):,}")
    print(f"  ✓ raw_email_events.csv   {len(email_rows):,}")
    print(f"  ✓ raw_web_events.csv     {len(web_rows):,}")
    print(f"  ✓ raw_conversions.csv    {len(conv_rows):,}")
    print(f"  ✓ raw_user_identity.csv  {len(identity_rows):,}")
