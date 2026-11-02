"""generate_titles.py — synthetic content catalogue."""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from faker import Faker


GENRES = ["Action", "Adventure", "Animation", "Comedy", "Crime", "Documentary",
          "Drama", "Family", "Fantasy", "History", "Horror", "Music", "Mystery",
          "Romance", "Sci-Fi", "Thriller", "War", "Western"]

LANGUAGES = ["en", "hi", "es", "ja", "ko", "fr", "de", "pt", "it", "zh"]
LANG_PROBS = [0.50, 0.10, 0.10, 0.05, 0.05, 0.05, 0.05, 0.04, 0.03, 0.03]

CONTENT_TYPES = ["movie", "show"]


def generate_titles(out_dir, n, seed=42):
    rng = np.random.default_rng(seed)
    fake = Faker(); Faker.seed(seed)

    today = datetime(2025, 12, 31).date()
    rows = []
    series_counter = 1

    # First create series then expand to episodes
    n_movies = int(n * 0.4)
    n_shows  = int(n * 0.1)
    # Remaining are episodes belonging to shows

    title_id = 1

    # Movies
    for _ in range(n_movies):
        n_genres = int(rng.integers(1, 4))
        gset = sorted(set(rng.choice(GENRES, size=n_genres, replace=False)))
        rows.append({
            "title_id": title_id,
            "title_name": fake.catch_phrase(),
            "content_type": "movie",
            "series_id": None,
            "season_number": None,
            "episode_number": None,
            "genres": ",".join(gset),
            "primary_language": str(rng.choice(LANGUAGES, p=LANG_PROBS)),
            "release_year": int(rng.integers(1980, 2026)),
            "runtime_minutes": int(rng.integers(70, 200)),
            "is_original": bool(rng.random() < 0.30),
            "licence_start_date": (today - timedelta(days=int(rng.integers(30, 1500)))).isoformat(),
            "licence_end_date": (today + timedelta(days=int(rng.integers(30, 1500)))).isoformat(),
            "created_at": datetime(2025, 1, 1).isoformat(),
            "updated_at": datetime(2025, 1, 1).isoformat(),
        })
        title_id += 1

    # Shows + episodes
    while title_id <= n:
        # Create one show
        sid = title_id
        gset = sorted(set(rng.choice(GENRES, size=int(rng.integers(1, 4)), replace=False)))
        show_lang = str(rng.choice(LANGUAGES, p=LANG_PROBS))
        rows.append({
            "title_id": title_id,
            "title_name": fake.catch_phrase(),
            "content_type": "show",
            "series_id": None,
            "season_number": None,
            "episode_number": None,
            "genres": ",".join(gset),
            "primary_language": show_lang,
            "release_year": int(rng.integers(1990, 2026)),
            "runtime_minutes": None,
            "is_original": bool(rng.random() < 0.40),
            "licence_start_date": (today - timedelta(days=int(rng.integers(30, 1500)))).isoformat(),
            "licence_end_date": (today + timedelta(days=int(rng.integers(30, 1500)))).isoformat(),
            "created_at": datetime(2025, 1, 1).isoformat(),
            "updated_at": datetime(2025, 1, 1).isoformat(),
        })
        title_id += 1
        # Episodes
        n_seasons = int(rng.integers(1, 5))
        for season in range(1, n_seasons + 1):
            n_eps = int(rng.integers(6, 13))
            for ep in range(1, n_eps + 1):
                if title_id > n:
                    break
                rows.append({
                    "title_id": title_id,
                    "title_name": f"S{season}E{ep}: {fake.bs()}",
                    "content_type": "episode",
                    "series_id": sid,
                    "season_number": season,
                    "episode_number": ep,
                    "genres": ",".join(gset),
                    "primary_language": show_lang,
                    "release_year": int(rng.integers(2010, 2026)),
                    "runtime_minutes": int(rng.integers(20, 65)),
                    "is_original": bool(rng.random() < 0.40),
                    "licence_start_date": (today - timedelta(days=int(rng.integers(30, 1000)))).isoformat(),
                    "licence_end_date": (today + timedelta(days=int(rng.integers(30, 1000)))).isoformat(),
                    "created_at": datetime(2025, 1, 1).isoformat(),
                    "updated_at": datetime(2025, 1, 1).isoformat(),
                })
                title_id += 1
            if title_id > n:
                break
        if title_id > n:
            break

    df = pd.DataFrame(rows)
    df.to_csv(out_dir / "raw_titles.csv", index=False)
    print(f"  ✓ raw_titles.csv          {len(df):,}")
    return df
