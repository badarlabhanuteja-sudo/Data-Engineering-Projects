"""recommender_nightly_dag — BASELINE: rebuild recommender once per day at 02:00."""

from datetime import datetime
from airflow import DAG
from airflow.operators.bash import BashOperator
from common import DEFAULT_ARGS


with DAG(
    dag_id="recommender_nightly_dag",
    default_args=DEFAULT_ARGS,
    description="BASELINE: nightly rebuild of mart_user_recommendations (BigQuery)",
    schedule="0 2 * * *",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["recommender", "experiment_baseline"],
) as dag:
    BashOperator(
        task_id="rebuild_recommender",
        bash_command="cd /opt/airflow/dbt && dbt run --select mart_user_recommendations",
    )
