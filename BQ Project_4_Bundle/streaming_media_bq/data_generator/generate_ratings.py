"""generate_ratings.py — synthetic user ratings."""

import uuid
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from tqdm import tqdm


def generate_ratings(out_dir, n, users_df, titles_df, seed=42):
    rng = np.random.default_rng(seed + 2)

    user_ids = users_df["user_id"].to_numpy()
    activity = users_df["_activity"].to_numpy()
    activity_w = activity / activity.sum()
    title_ids = titles_df["title_id"].to_numpy()

    today = datetime(2025, 12, 31)
    earliest = datetime(2025, 9, 1)

    print(f"  generating {n:,} ratings …")

    chosen_users  = rng.choice(len(user_ids),  size=n, p=activity_w)
    chosen_titles = rng.choice(len(title_ids), size=n)

    rows = []
    for i in tqdm(range(n), unit="ratings", ncols=80):
        uix = int(chosen_users[i])
        tix = int(chosen_titles[i])
        # Bias rating distribution by user-activity (more engaged users rate higher)
        mean_rating = 3.5 + float(activity[uix]) * 0.8
        rating = round(min(5.0, max(0.5, float(rng.normal(mean_rating, 0.6)))) * 2) / 2
        rated_at = earliest + timedelta(seconds=int(rng.integers(0, int((today - earliest).total_seconds()))))
        rows.append({
            "rating_id": uuid.uuid4().hex,
            "user_id":   int(user_ids[uix]),
            "title_id":  int(title_ids[tix]),
            "rating":    rating,
            "rated_at":  rated_at.isoformat(),
        })

    df = pd.DataFrame(rows)
    df.to_csv(out_dir / "raw_ratings.csv", index=False)
    print(f"  ✓ raw_ratings.csv         {len(df):,}")
