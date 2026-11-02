"""recommender_hourly_dag — INTERVENTION: rebuild recommender every hour."""

from datetime import datetime
from airflow import DAG
from airflow.operators.bash import BashOperator
from common import DEFAULT_ARGS


with DAG(
    dag_id="recommender_hourly_dag",
    default_args=DEFAULT_ARGS,
    description="INTERVENTION: hourly rebuild of mart_user_recommendations (BigQuery)",
    schedule="@hourly",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["recommender", "experiment_intervention"],
) as dag:
    BashOperator(
        task_id="rebuild_recommender",
        bash_command="cd /opt/airflow/dbt && dbt run --select mart_user_recommendations",
    )
