"""
extract_orders_dag
Daily incremental extraction of orders + order_items from the simulated OLTP
PostgreSQL database into Snowflake RAW tables.

In a real pipeline this would use Fivetran / Airbyte. Here we simulate via a
PythonOperator that runs the data-generator's "delta" mode.
"""

from datetime import datetime
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from common import DEFAULT_ARGS


def _extract_orders_delta(**context):
    """Stub for delta extraction — calls data_generator/load_to_bigquery.py."""
    import subprocess
    result = subprocess.run(
        ["python", "/workspace/data_generator/load_to_bigquery.py"],
        capture_output=True, text=True, check=False
    )
    print(result.stdout)
    print(result.stderr)
    if result.returncode != 0:
        raise RuntimeError(f"Extraction failed (exit {result.returncode})")


with DAG(
    dag_id="extract_orders_dag",
    default_args=DEFAULT_ARGS,
    description="Daily incremental order extraction from OLTP → BigQuery RAW",
    schedule="0 1 * * *",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["extract", "orders", "raw", "bigquery"],
) as dag:

    extract = PythonOperator(
        task_id="extract_orders_delta",
        python_callable=_extract_orders_delta,
    )

    notify = BashOperator(
        task_id="log_completion",
        bash_command='echo "orders extraction complete: {{ ds }}"',
    )

    extract >> notify