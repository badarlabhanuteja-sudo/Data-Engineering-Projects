from datetime import datetime
import os
from airflow import DAG
from airflow.operators.bash import BashOperator
from common import DEFAULT_ARGS

ENV_VARS = {
    "GCP_PROJECT": "ecommerce-customer360",
    "GCP_PROJECT_ID": "ecommerce-customer360",
    "GOOGLE_APPLICATION_CREDENTIALS": "/home/datagenaitech/airflow/credentials/credentials.json",
    "EXPERIMENT_NUM_RUNS": "20",
    "EXPERIMENT_RANDOM_SEED": "42",
}

with DAG(
    dag_id="experiment_dag",
    default_args=DEFAULT_ARGS,
    description="Paired RFM vs XGBoost experiment — 20 runs (BigQuery)",
    schedule=None,
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["experiment", "ml", "bigquery"],
) as dag:
    run_experiment = BashOperator(
        task_id="run_experiment",
        bash_command="python /home/datagenaitech/airflow/experiment/run_experiment.py",
        env=ENV_VARS,
        append_env=True,
    )
    statistical_analysis = BashOperator(
        task_id="statistical_analysis",
        bash_command="python /home/datagenaitech/airflow/experiment/statistical_analysis.py",
        env=ENV_VARS,
        append_env=True,
    )
    generate_charts = BashOperator(
        task_id="generate_charts",
        bash_command="python /home/datagenaitech/airflow/experiment/generate_charts.py",
        env=ENV_VARS,
        append_env=True,
    )
    run_experiment >> statistical_analysis >> generate_charts
