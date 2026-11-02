from datetime import datetime
from airflow import DAG
from airflow.operators.bash import BashOperator
from common import DEFAULT_ARGS


with DAG(
    dag_id="churn_train_dag",
    default_args=DEFAULT_ARGS,
    description="Weekly retrain of XGBoost churn model (BigQuery Spark serverless)",
    schedule="0 4 * * 0",          # Sundays 04:00
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["ml", "bigquery", "churn", "intervention"],
) as dag:

    BashOperator(
        task_id="dbt_run_churn_features",
        bash_command="cd /opt/airflow/dbt && dbt run --select mart_churn_features",
    ) >> BashOperator(
        task_id="dbt_run_churn_prediction",
        bash_command="cd /opt/airflow/dbt && dbt run --select mart_churn_prediction",
    )