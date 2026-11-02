"""dbt_full_dag — Cosmos-rendered dbt build (BigQuery edition)."""

import os
from datetime import datetime
from cosmos import DbtDag, ProjectConfig, ProfileConfig, ExecutionConfig
from cosmos.profiles import GoogleCloudOauthProfileMapping

profile_config = ProfileConfig(
    profile_name="streaming_media",
    target_name="dev",
    profile_mapping=GoogleCloudOauthProfileMapping(
        conn_id="google_cloud_default",
        profile_args={
            "project":  os.environ["GCP_PROJECT_ID"],
            "dataset":  "dbt_dev",
            "location": os.environ.get("BQ_LOCATION", "US"),
            "threads":  4,
        },
    ),
)

dbt_full_dag = DbtDag(
    dag_id="dbt_full_dag",
    schedule="0 3 * * *",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    project_config=ProjectConfig("/opt/airflow/dbt"),
    profile_config=profile_config,
    execution_config=ExecutionConfig(dbt_executable_path="/home/airflow/.local/bin/dbt"),
    operator_args={"install_deps": True, "full_refresh": False},
    default_args={"retries": 1},
    tags=["dbt", "transform", "bigquery"],
)
