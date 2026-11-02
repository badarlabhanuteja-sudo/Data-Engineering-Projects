"""extract_pings_dag — hourly clickstream-equivalent ingestion."""
from datetime import datetime
from airflow import DAG
from airflow.operators.python import PythonOperator
from common import DEFAULT_ARGS


def _ingest():
    print("ping ingestion — Snowpipe-equivalent placeholder")


with DAG(
    dag_id="extract_pings_dag",
    default_args=DEFAULT_ARGS,
    schedule="@hourly",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["extract", "pings"],
) as dag:
    PythonOperator(task_id="ingest", python_callable=_ingest)
