from datetime import datetime
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from common import DEFAULT_ARGS, GCP_PROJECT


def _load_web_events(**context):
    """Load raw_web_events.jsonl directly into BigQuery from local disk."""
    import json
    from pathlib import Path
    import pandas as pd
    from google.cloud import bigquery

    DATA_DIR = Path("/workspace/synthetic_data")
    path     = DATA_DIR / "raw_web_events.jsonl"
    table_id = f"{GCP_PROJECT}.raw.raw_web_events"
    client   = bigquery.Client(project=GCP_PROJECT)

    rows = []
    with open(path, "r") as f:
        for line in f:
            obj     = json.loads(line.strip())
            payload = obj.get("payload", {})
            rows.append({
                "event_id":        obj.get("event_id"),
                "customer_id":     obj.get("customer_id"),
                "event_timestamp": obj.get("event_timestamp"),
                "event_type":      payload.get("event_type"),
                "page_url":        payload.get("page_url"),
                "product_id":      payload.get("product_id"),
                "session_id":      payload.get("session_id"),
                "device_type":     payload.get("device_type"),
                "referrer":        payload.get("referrer"),
            })

    df         = pd.DataFrame(rows)
    job_config = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
    )
    job = client.load_table_from_dataframe(df, table_id, job_config=job_config)
    job.result()
    if job.errors:
        raise RuntimeError(f"BQ load errors: {job.errors}")
    print(f"Loaded {client.get_table(table_id).num_rows:,} rows into {table_id}")


with DAG(
    dag_id="extract_web_events_dag",
    default_args=DEFAULT_ARGS,
    description="Hourly web-events JSONL load → BigQuery RAW",
    schedule="0 * * * *",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["extract", "web_events", "bigquery"],
) as dag:

    load_events = PythonOperator(
        task_id="load_web_events",
        python_callable=_load_web_events,
    )

    notify = BashOperator(
        task_id="log_completion",
        bash_command='echo "web events load complete: {{ ds }}"',
    )

    load_events >> notify