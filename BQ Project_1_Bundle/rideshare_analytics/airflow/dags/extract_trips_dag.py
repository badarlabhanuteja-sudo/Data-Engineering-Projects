"""extract_trips_dag — every 15 min, polls OLTP and refreshes the Stream."""

from datetime import datetime
from airflow import DAG
from airflow.operators.python import PythonOperator
from common import DEFAULT_ARGS


def _extract():
    import subprocess
    r = subprocess.run(
        ["python", "/workspace/data_generator/load_to_snowflake.py"],
        capture_output=True, text=True, check=False
    )
    print(r.stdout); print(r.stderr)
    if r.returncode != 0:
        raise RuntimeError("extraction failed")


with DAG(
    dag_id="extract_trips_dag",
    default_args=DEFAULT_ARGS,
    description="Every 15 min: trip + payment incremental load",
    schedule="*/15 * * * *",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["extract", "trips"],
) as dag:
    PythonOperator(task_id="extract", python_callable=_extract)
