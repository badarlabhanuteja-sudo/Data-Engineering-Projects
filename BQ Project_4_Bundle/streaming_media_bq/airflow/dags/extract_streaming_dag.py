"""extract_streaming_dag — every 30 min, ingest catalogue + sessions + view events.

BigQuery edition: calls load_to_bigquery.py instead of load_to_snowflake.py.
"""

from datetime import datetime
from airflow import DAG
from airflow.operators.python import PythonOperator
from common import DEFAULT_ARGS


def _extract():
    import subprocess
    r = subprocess.run(
        ["python", "/workspace/data_generator/load_to_bigquery.py"],
        capture_output=True, text=True, check=False
    )
    print(r.stdout); print(r.stderr)
    if r.returncode != 0:
        raise RuntimeError("extract failed")


with DAG(
    dag_id="extract_streaming_dag",
    default_args=DEFAULT_ARGS,
    description="Every 30 min: ingest catalogue + sessions + view events (BigQuery)",
    schedule="*/30 * * * *",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["extract", "streaming"],
) as dag:
    PythonOperator(task_id="extract", python_callable=_extract)
