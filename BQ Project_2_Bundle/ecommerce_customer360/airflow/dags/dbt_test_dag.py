"""
dbt_test_dag
Runs `dbt test` only — used for severity-classified post-build verification.
"""

from datetime import datetime
from airflow import DAG
from airflow.operators.bash import BashOperator
from common import DEFAULT_ARGS, DBT_PROJECT_PATH
 
with DAG(
    dag_id="dbt_test_dag",
    default_args=DEFAULT_ARGS,
    description="Standalone dbt test run (BigQuery)",
    schedule=None,
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["dbt", "test", "bigquery"],
) as dag:
 
    BashOperator(
        task_id="dbt_test",
        bash_command=f"cd {DBT_PROJECT_PATH} && dbt test",
    )