"""
load_to_bigquery.py — Loads CSV/JSONL files into BigQuery RAW tables.
"""

import json
import os
import time
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from google.cloud import bigquery

load_dotenv(Path(__file__).resolve().parent.parent / ".env")
DATA_DIR = Path(__file__).resolve().parent.parent / "synthetic_data"

PROJECT_ID = os.environ["GCP_PROJECT_ID"]
DATASET    = "raw"
client     = bigquery.Client(project=PROJECT_ID)

CSV_FILES = [
    ("raw_categories.csv",   "raw_categories"),
    ("raw_products.csv",     "raw_products"),
    ("raw_customers.csv",    "raw_customers"),
    ("raw_orders.csv",       "raw_orders"),
    ("raw_order_items.csv",  "raw_order_items"),
    ("raw_email_events.csv", "raw_email_events"),
]

JSONL_FILE = ("raw_web_events.jsonl", "raw_web_events")


def load_csv(fname, table_name):
    path = DATA_DIR / fname
    if not path.exists():
        print(f"  skip {fname} (not found)")
        return
    t0 = time.time()
    table_id   = f"{PROJECT_ID}.{DATASET}.{table_name}"
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        autodetect=True,
        ignore_unknown_values=True,
        allow_quoted_newlines=True,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )
    with open(path, "rb") as f:
        job = client.load_table_from_file(f, table_id, job_config=job_config)
    job.result()
    table = client.get_table(table_id)
    print(f"  OK {fname:<28} rows={table.num_rows:>10,}  ({time.time()-t0:.1f}s)")


def load_web_events_jsonl(fname, table_name):
    path = DATA_DIR / fname
    if not path.exists():
        print(f"  skip {fname} (not found)")
        return
    t0 = time.time()
    table_id = f"{PROJECT_ID}.{DATASET}.{table_name}"

    rows = []
    with open(path, "r") as f:
        for line in f:
            obj     = json.loads(line.strip())
            payload = obj.get("payload", {})
            rows.append({
                "event_id":        obj.get("event_id"),
                "customer_id":     obj.get("customer_id"),
                "event_timestamp": obj.get("event_timestamp"),
                "event_type":      obj.get("event_type"),
                "page_url":        payload.get("page_url"),
                "product_id":      payload.get("product_id"),
                "session_id":      obj.get("session_id"),
                "device_type":     payload.get("device"),
                "referrer":        obj.get("referrer"),
            })

    df         = pd.DataFrame(rows)
    job_config = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )
    job = client.load_table_from_dataframe(df, table_id, job_config=job_config)
    job.result()
    table = client.get_table(table_id)
    print(f"   {fname:<28} rows={table.num_rows:>10,}  ({time.time()-t0:.1f}s)")


def main():
    print(f"Loading data into BigQuery project: {PROJECT_ID}")
    for fname, table in CSV_FILES:
        load_csv(fname, table)
    fname, table = JSONL_FILE
    load_web_events_jsonl(fname, table)
    print("\nLoad complete. Next: cd dbt && dbt deps && dbt seed && dbt run && dbt test")


if __name__ == "__main__":
    main()
