"""generate_all.py — Markov-chain-driven multi-channel marketing data."""

import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

from generate_journeys import generate_journeys
from generate_ad_spend import generate_ad_spend


OUT = Path(__file__).resolve().parent.parent / "synthetic_data"
OUT.mkdir(exist_ok=True)


def main():
    seed = int(os.getenv("DATA_RANDOM_SEED", "42"))
    n_users        = int(os.getenv("DATA_NUM_USERS", "500000"))
    n_touchpoints  = int(os.getenv("DATA_NUM_TOUCHPOINTS", "3000000"))
    n_conversions  = int(os.getenv("DATA_NUM_CONVERSIONS", "50000"))

    print(f"=== marketing-attribution data generation ===")
    print(f"  seed         = {seed}")
    print(f"  users        = {n_users:,}")
    print(f"  touchpoints  = {n_touchpoints:,}")
    print(f"  conversions  = {n_conversions:,}\n")

    generate_journeys(out_dir=OUT, n_users=n_users,
                      n_touchpoints=n_touchpoints,
                      n_conversions=n_conversions,
                      seed=seed)
    generate_ad_spend(out_dir=OUT, seed=seed)

    print("\n=== generation complete ===")
    print("next: python /workspace/data_generator/load_to_bigquery.py")


if __name__ == "__main__":
    main()
