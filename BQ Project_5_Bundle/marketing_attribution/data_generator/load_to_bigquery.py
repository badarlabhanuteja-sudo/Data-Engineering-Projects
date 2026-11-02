"""
load_to_bigquery.py
Loads synthetic CSV data into BigQuery raw dataset.

Prerequisites:
  pip install google-cloud-bigquery google-cloud-bigquery-storage pandas pyarrow python-dotenv

Usage:
  python data_generator/load_to_bigquery.py
"""

import os
import time
from pathlib import Path
from dotenv import load_dotenv
from google.cloud import bigquery

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

DATA_DIR = Path(__file__).resolve().parent.parent / "synthetic_data"

PROJECT  = os.environ["GCP_PROJECT"]
DATASET  = "raw"
LOCATION = os.environ.get("GCP_LOCATION", "US")

# Map CSV filename → BigQuery table name
CSV_FILES = [
    ("raw_google_ads.csv",     "raw_google_ads"),
    ("raw_meta_ads.csv",       "raw_meta_ads"),
    ("raw_tiktok_ads.csv",     "raw_tiktok_ads"),
    ("raw_email_events.csv",   "raw_email_events"),
    ("raw_web_events.csv",     "raw_web_events"),
    ("raw_conversions.csv",    "raw_conversions"),
    ("raw_user_identity.csv",  "raw_user_identity"),
    ("raw_ad_spend.csv",       "raw_ad_spend"),
]

# BigQuery schema per table (matches DDL in bigquery/02_setup_raw_tables.sql)
TABLE_SCHEMAS = {
    "raw_google_ads": [
        bigquery.SchemaField("google_event_id",  "STRING"),
        bigquery.SchemaField("user_id",          "STRING"),
        bigquery.SchemaField("google_click_id",  "STRING"),
        bigquery.SchemaField("campaign_id",      "STRING"),
        bigquery.SchemaField("ad_group_id",      "STRING"),
        bigquery.SchemaField("creative_id",      "STRING"),
        bigquery.SchemaField("keyword",          "STRING"),
        bigquery.SchemaField("event_type",       "STRING"),
        bigquery.SchemaField("event_timestamp",  "TIMESTAMP"),
        bigquery.SchemaField("cost",             "NUMERIC"),
    ],
    "raw_meta_ads": [
        bigquery.SchemaField("meta_event_id",    "STRING"),
        bigquery.SchemaField("user_id",          "STRING"),
        bigquery.SchemaField("fbclid",           "STRING"),
        bigquery.SchemaField("campaign_id",      "STRING"),
        bigquery.SchemaField("ad_set_id",        "STRING"),
        bigquery.SchemaField("ad_id",            "STRING"),
        bigquery.SchemaField("placement",        "STRING"),
        bigquery.SchemaField("event_type",       "STRING"),
        bigquery.SchemaField("event_timestamp",  "TIMESTAMP"),
        bigquery.SchemaField("cost",             "NUMERIC"),
    ],
    "raw_tiktok_ads": [
        bigquery.SchemaField("tiktok_event_id",  "STRING"),
        bigquery.SchemaField("user_id",          "STRING"),
        bigquery.SchemaField("ttclid",           "STRING"),
        bigquery.SchemaField("campaign_id",      "STRING"),
        bigquery.SchemaField("ad_group_id",      "STRING"),
        bigquery.SchemaField("creative_id",      "STRING"),
        bigquery.SchemaField("event_type",       "STRING"),
        bigquery.SchemaField("event_timestamp",  "TIMESTAMP"),
        bigquery.SchemaField("cost",             "NUMERIC"),
    ],
    "raw_email_events": [
        bigquery.SchemaField("email_event_id",   "STRING"),
        bigquery.SchemaField("user_id",          "STRING"),
        bigquery.SchemaField("campaign_id",      "STRING"),
        bigquery.SchemaField("event_type",       "STRING"),
        bigquery.SchemaField("event_timestamp",  "TIMESTAMP"),
        bigquery.SchemaField("subject_line",     "STRING"),
    ],
    "raw_web_events": [
        bigquery.SchemaField("event_id",         "STRING"),
        bigquery.SchemaField("user_id",          "STRING"),
        bigquery.SchemaField("session_id",       "STRING"),
        bigquery.SchemaField("event_type",       "STRING"),
        bigquery.SchemaField("page_url",         "STRING"),
        bigquery.SchemaField("referrer",         "STRING"),
        bigquery.SchemaField("utm_source",       "STRING"),
        bigquery.SchemaField("utm_medium",       "STRING"),
        bigquery.SchemaField("utm_campaign",     "STRING"),
        bigquery.SchemaField("event_timestamp",  "TIMESTAMP"),
        bigquery.SchemaField("payload",          "JSON"),
    ],
    "raw_conversions": [
        bigquery.SchemaField("conversion_id",        "STRING"),
        bigquery.SchemaField("user_id",              "STRING"),
        bigquery.SchemaField("conversion_type",      "STRING"),
        bigquery.SchemaField("revenue",              "NUMERIC"),
        bigquery.SchemaField("conversion_timestamp", "TIMESTAMP"),
    ],
    "raw_ad_spend": [
        bigquery.SchemaField("spend_id",     "STRING"),
        bigquery.SchemaField("spend_date",   "DATE"),
        bigquery.SchemaField("channel",      "STRING"),
        bigquery.SchemaField("campaign_id",  "STRING"),
        bigquery.SchemaField("spend_amount", "NUMERIC"),
        bigquery.SchemaField("impressions",  "INT64"),
        bigquery.SchemaField("clicks",       "INT64"),
    ],
    "raw_user_identity": [
        bigquery.SchemaField("user_id",           "STRING"),
        bigquery.SchemaField("canonical_user_id", "STRING"),
        bigquery.SchemaField("email_hash",        "STRING"),
        bigquery.SchemaField("first_seen_at",     "TIMESTAMP"),
        bigquery.SchemaField("last_seen_at",      "TIMESTAMP"),
    ],
}


def main():
    client = bigquery.Client(project=PROJECT)
    print(f"Connected to BigQuery project: {PROJECT}")

    for fname, table_name in CSV_FILES:
        path = DATA_DIR / fname
        if not path.exists():
            print(f"  skip {fname} (not found)")
            continue

        table_id = f"{PROJECT}.{DATASET}.{table_name}"
        schema   = TABLE_SCHEMAS[table_name]

        t0 = time.time()

        job_config = bigquery.LoadJobConfig(
            schema=schema,
            source_format=bigquery.SourceFormat.CSV,
            skip_leading_rows=1,
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
            null_marker="",
            allow_quoted_newlines=True,
        )

        with open(path, "rb") as f:
            job = client.load_table_from_file(f, table_id, job_config=job_config)

        job.result()  # Wait for completion

        table  = client.get_table(table_id)
        rows   = table.num_rows
        print(f"  ✔ {fname:<28} rows={rows:>10,}  ({time.time()-t0:.1f}s)")

    print("\nLoad complete. Next: cd dbt && dbt deps && dbt seed && dbt run && dbt test")


if __name__ == "__main__":
    main()
