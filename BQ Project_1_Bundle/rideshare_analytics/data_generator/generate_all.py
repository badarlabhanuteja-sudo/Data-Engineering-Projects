"""
generate_all.py — Master entry point for synthetic ride-sharing data.
"""

import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

from generate_cities import generate_cities
from generate_drivers_riders import generate_drivers, generate_riders
from generate_trips import generate_trips_and_payments
from generate_pings import generate_pings


OUT = Path(__file__).resolve().parent.parent / "synthetic_data"
OUT.mkdir(exist_ok=True)


def main():
    seed       = int(os.getenv("DATA_RANDOM_SEED", "42"))
    n_drivers  = int(os.getenv("DATA_NUM_DRIVERS", "50000"))
    n_riders   = int(os.getenv("DATA_NUM_RIDERS", "200000"))
    n_trips    = int(os.getenv("DATA_NUM_TRIPS", "5000000"))
    n_pings    = int(os.getenv("DATA_NUM_PINGS", "10000000"))

    print(f"=== synthetic ride-sharing data generation ===")
    print(f"  seed       = {seed}")
    print(f"  drivers    = {n_drivers:,}")
    print(f"  riders     = {n_riders:,}")
    print(f"  trips      = {n_trips:,}")
    print(f"  pings      = {n_pings:,}")
    print(f"  out dir    = {OUT}\n")

    cities  = generate_cities(out_dir=OUT)
    drivers = generate_drivers(out_dir=OUT, n=n_drivers, cities_df=cities, seed=seed)
    riders  = generate_riders(out_dir=OUT, n=n_riders, cities_df=cities, seed=seed)
    trips   = generate_trips_and_payments(
        out_dir=OUT, n=n_trips,
        drivers_df=drivers, riders_df=riders, cities_df=cities, seed=seed)
    generate_pings(out_dir=OUT, n=n_pings, drivers_df=drivers, trips_df=trips, seed=seed)

    print("\n=== generation complete ===")
    print("next: python /workspace/data_generator/load_to_bigquery.py")


if __name__ == "__main__":
    main()
