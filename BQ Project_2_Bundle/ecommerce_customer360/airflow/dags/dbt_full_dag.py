from datetime import datetime
from airflow import DAG
from airflow.operators.bash import BashOperator
from common import DEFAULT_ARGS, DBT_PROJECT_PATH

DBT_CMD = f"cd {DBT_PROJECT_PATH}"

with DAG(
    dag_id="dbt_full_dag",
    default_args=DEFAULT_ARGS,
    description="Full dbt pipeline: seed → snapshot → run → test (BigQuery)",
    schedule="0 3 * * *",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["dbt", "bigquery", "full-pipeline"],
) as dag:

    dbt_deps = BashOperator(
        task_id="dbt_deps",
        bash_command=f"{DBT_CMD} && dbt deps",
    )
    dbt_seed = BashOperator(
        task_id="dbt_seed",
        bash_command=f"{DBT_CMD} && dbt seed",
    )
    dbt_snapshot = BashOperator(
        task_id="dbt_snapshot",
        bash_command=f"{DBT_CMD} && dbt snapshot",
    )
    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"{DBT_CMD} && dbt run",
    )
    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"{DBT_CMD} && dbt test",
    )

    dbt_deps >> dbt_seed >> dbt_snapshot >> dbt_run >> dbt_test