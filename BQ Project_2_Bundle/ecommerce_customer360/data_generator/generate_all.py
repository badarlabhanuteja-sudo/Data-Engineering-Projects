"""
generate_all.py
Master data-generation entry point.

Generates synthetic e-commerce data with realistic distributions, churn signal,
seasonality, and cross-table referential integrity.

Outputs CSV (and JSONL for events) to ./synthetic_data/.

Usage (inside dbt-runner container):
    python /workspace/data_generator/generate_all.py
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Load .env from project root
load_dotenv(Path(__file__).resolve().parent.parent / ".env")

from generate_categories_products import generate_categories, generate_products
from generate_customers import generate_customers
from generate_orders import generate_orders_and_items
from generate_clickstream import generate_web_events
from generate_email_events import generate_email_events


OUT = Path(__file__).resolve().parent.parent / "synthetic_data"
OUT.mkdir(exist_ok=True)


def main():
    seed = int(os.getenv("DATA_RANDOM_SEED", "42"))
    n_customers = int(os.getenv("DATA_NUM_CUSTOMERS", "50000"))
    n_products  = int(os.getenv("DATA_NUM_PRODUCTS", "10000"))
    n_orders    = int(os.getenv("DATA_NUM_ORDERS", "500000"))
    n_events    = int(os.getenv("DATA_NUM_WEB_EVENTS", "2000000"))

    print(f"=== synthetic data generation ===")
    print(f"seed         = {seed}")
    print(f"customers    = {n_customers:,}")
    print(f"products     = {n_products:,}")
    print(f"orders       = {n_orders:,}")
    print(f"web events   = {n_events:,}")
    print(f"output dir   = {OUT}\n")

    # 1. Categories and Products (no foreign-key dependencies)
    cats = generate_categories(out_dir=OUT, seed=seed)
    prods = generate_products(out_dir=OUT, n=n_products, categories_df=cats, seed=seed)

    # 2. Customers (independent)
    custs = generate_customers(out_dir=OUT, n=n_customers, seed=seed)

    # 3. Orders & Order Items (FK: customers, products)
    orders = generate_orders_and_items(
        out_dir=OUT, n_orders=n_orders,
        customers_df=custs, products_df=prods, seed=seed
    )

    # 4. Web events (FK: customers; optionally products)
    generate_web_events(
        out_dir=OUT, n=n_events,
        customers_df=custs, products_df=prods, seed=seed
    )

    # 5. Email events (FK: customers)
    generate_email_events(
        out_dir=OUT, n=int(n_customers * 8),
        customers_df=custs, seed=seed
    )

    print("\n=== generation complete ===")
    print("next: python /workspace/data_generator/load_to_bigquery.py")


if __name__ == "__main__":
    main()
