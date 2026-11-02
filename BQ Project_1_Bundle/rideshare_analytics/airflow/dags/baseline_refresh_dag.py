from datetime import datetime
from airflow import DAG
from airflow.operators.bash import BashOperator

DEFAULT_ARGS = {"owner": "airflow", "retries": 1}

with DAG(
    dag_id="baseline_refresh_dag",
    default_args=DEFAULT_ARGS,
    description="BASELINE: every 5 min, incremental refresh of the 3 streaming marts",
    schedule="*/5 * * * *",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["dbt", "experiment_baseline"],
) as dag:
    BashOperator(
        task_id="dbt_run_baseline_marts",
        bash_command=(
            "cd C:/Users/DATAGENAITECH/Downloads/rideshare_analytics/dbt && "
            "dbt run --select tag:baseline_incremental"
        ),
    )
