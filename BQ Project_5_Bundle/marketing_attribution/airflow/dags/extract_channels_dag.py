"""extract_channels_dag — daily extract from all 6 channels into Snowflake RAW."""

from datetime import datetime
from airflow import DAG
from airflow.operators.python import PythonOperator
from common import DEFAULT_ARGS


def _load_all():
    import subprocess
    r = subprocess.run(
        ["python", "/workspace/data_generator/load_to_snowflake.py"],
        capture_output=True, text=True, check=False
    )
    print(r.stdout); print(r.stderr)
    if r.returncode != 0:
        raise RuntimeError("load failed")


with DAG(
    dag_id="extract_channels_dag",
    default_args=DEFAULT_ARGS,
    description="Daily ingest of Google/Meta/TikTok/Email/Web/CRM/AdSpend → Snowflake RAW",
    schedule="0 1 * * *",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["extract", "marketing"],
) as dag:
    PythonOperator(task_id="load_all_channels", python_callable=_load_all)
