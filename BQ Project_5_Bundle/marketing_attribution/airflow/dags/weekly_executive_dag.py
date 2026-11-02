"""weekly_executive_dag — weekly attribution-comparison report."""

from datetime import datetime
from airflow import DAG
from airflow.operators.bash import BashOperator
from common import DEFAULT_ARGS


with DAG(
    dag_id="weekly_executive_dag",
    default_args=DEFAULT_ARGS,
    description="Weekly attribution-comparison snapshot for executive consumption",
    schedule="0 6 * * 1",     # Mondays 06:00
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["reporting", "executive"],
) as dag:
    BashOperator(
        task_id="snapshot_attribution_comparison",
        bash_command=(
            "cd /opt/airflow/dbt && "
            "dbt run --select tag:attribution --full-refresh"
        ),
    )
