"""generate_all.py — Master entry point."""

import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

from generate_titles import generate_titles
from generate_users import generate_users
from generate_sessions_and_views import generate_sessions_and_views
from generate_ratings import generate_ratings


OUT = Path(__file__).resolve().parent.parent / "synthetic_data"
OUT.mkdir(exist_ok=True)


def main():
    seed       = int(os.getenv("DATA_RANDOM_SEED", "42"))
    n_users    = int(os.getenv("DATA_NUM_USERS", "100000"))
    n_titles   = int(os.getenv("DATA_NUM_TITLES", "25000"))
    n_sessions = int(os.getenv("DATA_NUM_SESSIONS", "2000000"))
    n_views    = int(os.getenv("DATA_NUM_VIEW_EVENTS", "6000000"))
    n_ratings  = int(os.getenv("DATA_NUM_RATINGS", "1500000"))

    print(f"=== streaming-media data generation ===")
    print(f"  seed         = {seed}")
    print(f"  users        = {n_users:,}")
    print(f"  titles       = {n_titles:,}")
    print(f"  sessions     = {n_sessions:,}")
    print(f"  view events  = {n_views:,}")
    print(f"  ratings      = {n_ratings:,}\n")

    titles = generate_titles(out_dir=OUT, n=n_titles, seed=seed)
    users  = generate_users(out_dir=OUT, n=n_users, seed=seed)
    sessions = generate_sessions_and_views(
        out_dir=OUT, n_sessions=n_sessions, n_views=n_views,
        users_df=users, titles_df=titles, seed=seed)
    generate_ratings(out_dir=OUT, n=n_ratings, users_df=users, titles_df=titles, seed=seed)

    print("\n=== generation complete ===")
    print("next: python /workspace/data_generator/load_to_bigquery.py")


if __name__ == "__main__":
    main()
