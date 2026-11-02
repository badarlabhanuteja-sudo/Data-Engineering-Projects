"""
load_to_bigquery.py — Loads CSV files into BigQuery raw tables.
"""

import os
import time
from pathlib import Path
from dotenv import load_dotenv
from google.cloud import bigquery
import pandas as pd

load_dotenv(Path(__file__).resolve().parent.parent / ".env")
DATA_DIR = Path(__file__).resolve().parent.parent / "synthetic_data"

PROJECT_ID = os.environ["GCP_PROJECT_ID"]
DATASET    = "raw"
client     = bigquery.Client(project=PROJECT_ID)

CSV_FILES = [
    ("raw_cities.csv",   "raw_cities"),
    ("raw_drivers.csv",  "raw_drivers"),
    ("raw_riders.csv",   "raw_riders"),
    ("raw_trips.csv",    "raw_trips"),
    ("raw_payments.csv", "raw_payments"),
]

JSONL_FILE = ("raw_location_pings.jsonl", "raw_location_pings")


def load_csv(fname, table_name):
    path = DATA_DIR / fname
    if not path.exists():
        print(f"  skip {fname} (not found)")
        return
    t0 = time.time()
    table_id = f"{PROJECT_ID}.{DATASET}.{table_name}"
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


def load_pings_jsonl(fname, table_name):
    path = DATA_DIR / fname
    if not path.exists():
        print(f"  skip {fname} (not found)")
        return
    t0 = time.time()
    table_id = f"{PROJECT_ID}.{DATASET}.{table_name}"

    # Read JSONL, normalize payload column
    rows = []
    with open(path, "r") as f:
        import json
        for line in f:
            obj = json.loads(line.strip())
            payload = obj.get("payload", {})
            rows.append({
                "ping_id":       obj.get("ping_id"),
                "driver_id":     obj.get("driver_id"),
                "ping_timestamp": obj.get("ping_timestamp"),
                "lat":           payload.get("lat"),
                "lng":           payload.get("lng"),
                "speed_kmph":    payload.get("speed_kmph"),
                "heading":       payload.get("heading"),
                "is_on_trip":    payload.get("is_on_trip"),
                "battery_pct":   payload.get("battery_pct"),
            })

    df = pd.DataFrame(rows)
    job_config = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )
    job = client.load_table_from_dataframe(df, table_id, job_config=job_config)
    job.result()
    table = client.get_table(table_id)
    print(f"  OK {fname:<28} rows={table.num_rows:>10,}  ({time.time()-t0:.1f}s)")


def main():
    print(f"Loading data into BigQuery project: {PROJECT_ID}")
    for fname, table in CSV_FILES:
        load_csv(fname, table)
    fname, table = JSONL_FILE
    load_pings_jsonl(fname, table)
    print("\nLoad complete. Next: cd dbt && dbt deps && dbt seed && dbt run && dbt test")


if __name__ == "__main__":
    main()


