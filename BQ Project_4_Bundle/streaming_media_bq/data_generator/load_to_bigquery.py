"""load_to_bigquery.py — Bulk-load CSVs + JSONL into BigQuery raw.* tables.

BigQuery Sandbox compatible.  Requires:
    pip install google-cloud-bigquery pandas pyarrow python-dotenv

Authentication:
    gcloud auth application-default login
    -- OR --
    Set GOOGLE_APPLICATION_CREDENTIALS=/path/to/service_account.json
"""

import os
import time
import json
from pathlib import Path
from dotenv import load_dotenv
from google.cloud import bigquery
from google.cloud.exceptions import NotFound
import pandas as pd

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

PROJECT_ID = os.environ["GCP_PROJECT_ID"]
DATASET    = os.environ.get("BQ_DATASET_RAW", "raw")
DATA_DIR   = Path(__file__).resolve().parent.parent / "synthetic_data"

# (filename, table_name, file_format)
CSV_FILES = [
    ("raw_titles.csv",   "raw_titles"),
    ("raw_users.csv",    "raw_users"),
    ("raw_sessions.csv", "raw_sessions"),
    ("raw_ratings.csv",  "raw_ratings"),
]

JSONL_FILES = [
    ("raw_view_events.jsonl", "raw_view_events"),
]

# BigQuery type overrides for columns that pandas would mis-detect
SCHEMA_OVERRIDES = {
    "raw_titles": {
        "title_id": bigquery.SchemaField("title_id", "INT64"),
        "is_original": bigquery.SchemaField("is_original", "BOOL"),
        "_loaded_at": bigquery.SchemaField("_loaded_at", "TIMESTAMP"),
    },
    "raw_users": {
        "user_id": bigquery.SchemaField("user_id", "INT64"),
        "is_active": bigquery.SchemaField("is_active", "BOOL"),
        "_loaded_at": bigquery.SchemaField("_loaded_at", "TIMESTAMP"),
    },
    "raw_sessions": {
        "user_id": bigquery.SchemaField("user_id", "INT64"),
        "_loaded_at": bigquery.SchemaField("_loaded_at", "TIMESTAMP"),
    },
    "raw_ratings": {
        "user_id": bigquery.SchemaField("user_id", "INT64"),
        "title_id": bigquery.SchemaField("title_id", "INT64"),
        "_loaded_at": bigquery.SchemaField("_loaded_at", "TIMESTAMP"),
    },
    "raw_view_events": {
        "user_id": bigquery.SchemaField("user_id", "INT64"),
        "title_id": bigquery.SchemaField("title_id", "INT64"),
        "payload": bigquery.SchemaField("payload", "JSON"),
        "_loaded_at": bigquery.SchemaField("_loaded_at", "TIMESTAMP"),
    },
}


def get_client() -> bigquery.Client:
    return bigquery.Client(project=PROJECT_ID)


def load_csv(client: bigquery.Client, fname: str, table_name: str) -> None:
    path = DATA_DIR / fname
    if not path.exists():
        print(f"  skip {fname} (not found)")
        return

    table_ref = f"{PROJECT_ID}.{DATASET}.{table_name}"
    t0 = time.time()

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        autodetect=True,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        null_marker="",
        allow_quoted_newlines=True,
    )

    with open(path, "rb") as f:
        job = client.load_table_from_file(f, table_ref, job_config=job_config)

    job.result()  # wait for completion

    table = client.get_table(table_ref)
    print(f"  ✓ {fname:<28} rows={table.num_rows:>10,}  ({time.time()-t0:.1f}s)")


def load_jsonl(client: bigquery.Client, fname: str, table_name: str) -> None:
    """Load JSONL.  BigQuery NEWLINE_DELIMITED_JSON handles VARIANT → JSON naturally."""
    path = DATA_DIR / fname
    if not path.exists():
        print(f"  skip {fname} (not found)")
        return

    table_ref = f"{PROJECT_ID}.{DATASET}.{table_name}"
    t0 = time.time()

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
        autodetect=True,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        ignore_unknown_values=True,
    )

    with open(path, "rb") as f:
        job = client.load_table_from_file(f, table_ref, job_config=job_config)

    job.result()

    table = client.get_table(table_ref)
    print(f"  ✓ {fname:<28} rows={table.num_rows:>10,}  ({time.time()-t0:.1f}s)")


def main() -> None:
    client = get_client()
    print(f"connected to project: {PROJECT_ID}  dataset: {DATASET}\n")

    print("Loading CSV files...")
    for fname, table_name in CSV_FILES:
        load_csv(client, fname, table_name)

    print("\nLoading JSONL files...")
    for fname, table_name in JSONL_FILES:
        load_jsonl(client, fname, table_name)

    print("\nload complete. next: cd dbt && dbt deps && dbt seed && dbt run && dbt test")


if __name__ == "__main__":
    main()
