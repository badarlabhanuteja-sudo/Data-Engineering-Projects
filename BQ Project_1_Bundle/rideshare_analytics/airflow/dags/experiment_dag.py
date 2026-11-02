"""experiment_dag — Dynamic Tables vs Incremental, 20-run paired experiment."""

from datetime import datetime
from airflow import DAG
from airflow.operators.bash import BashOperator
from common import DEFAULT_ARGS


with DAG(
    dag_id="experiment_dag",
    default_args=DEFAULT_ARGS,
    description="20-run paired comparison + statistical analysis + charts",
    schedule=None,                        # manual trigger
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["experiment", "dissertation"],
) as dag:
    run    = BashOperator(task_id="run_experiment",       bash_command="python /workspace/experiment/run_experiment.py")
    stats  = BashOperator(task_id="statistical_analysis", bash_command="python /workspace/experiment/statistical_analysis.py")
    charts = BashOperator(task_id="generate_charts",      bash_command="python /workspace/experiment/generate_charts.py")
    run >> stats >> charts
