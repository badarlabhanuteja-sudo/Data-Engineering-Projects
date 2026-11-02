"""load_to_bigquery.py — Bulk-load CSVs into raw.* tables via the BigQuery client."""
 
import os, time
from pathlib import Path
from dotenv import load_dotenv
from google.cloud import bigquery
from google.oauth2 import service_account
 
load_dotenv(Path(__file__).resolve().parent.parent / ".env")
DATA_DIR = Path(__file__).resolve().parent.parent / "synthetic_data"
 
PROJECT  = os.environ["BQ_PROJECT"]
DATASET  = "raw"
KEYFILE  = os.environ.get("BQ_KEYFILE_PATH", "")
 
CSV_FILES = [
    ("raw_patients.csv",     "raw_patients"),
    ("raw_encounters.csv",   "raw_encounters"),
    ("raw_observations.csv", "raw_observations"),
    ("raw_conditions.csv",   "raw_conditions"),
    ("raw_medications.csv",  "raw_medications"),
    ("raw_procedures.csv",   "raw_procedures"),
]
 
 
def get_client() -> bigquery.Client:
    if KEYFILE:
        creds = service_account.Credentials.from_service_account_file(KEYFILE)
        return bigquery.Client(project=PROJECT, credentials=creds)
    # Falls back to Application Default Credentials (e.g. gcloud auth)
    return bigquery.Client(project=PROJECT)
 
 
def main():
    client = get_client()
    print(f"connected to project {PROJECT}")
 
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        autodetect=True,               # infer schema from CSV headers (excludes _loaded_at)
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        null_marker="",
        allow_quoted_newlines=True,
        ignore_unknown_values=True,
    )
 
    for fname, table_name in CSV_FILES:
        path = DATA_DIR / fname
        if not path.exists():
            print(f"  skip {fname}")
            continue
        t0 = time.time()
        table_ref = f"{PROJECT}.{DATASET}.{table_name}"
        with open(path, "rb") as f:
            load_job = client.load_table_from_file(f, table_ref, job_config=job_config)
        load_job.result()  # wait for completion
        dest = client.get_table(table_ref)
        print(f"  ✓ {fname:<28} rows={dest.num_rows:>10,}  ({time.time()-t0:.1f}s)")
 
    print("\nload complete. next: cd dbt && dbt deps && dbt seed && dbt run && dbt test")
 
 
if __name__ == "__main__":
    main()