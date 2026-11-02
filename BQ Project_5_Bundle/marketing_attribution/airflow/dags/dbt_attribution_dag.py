"""dbt_attribution_dag — Cosmos-rendered dbt build of all attribution marts."""

from datetime import datetime
import os
from cosmos import DbtDag, ProjectConfig, ProfileConfig, ExecutionConfig
from cosmos.profiles import GoogleCloudServiceAccountFileProfileMapping

profile_config = ProfileConfig(
    profile_name="marketing_attribution",
    target_name="dev",
    profile_mapping=GoogleCloudServiceAccountFileProfileMapping(
        conn_id="google_cloud_default",
        profile_args={
            "project":  os.environ["GCP_PROJECT"],
            "dataset":  "raw",
            "location": os.environ.get("GCP_LOCATION", "US"),
            "threads":  4,
        },
    ),
)

dbt_attribution_dag = DbtDag(
    dag_id="dbt_attribution_dag",
    schedule="0 3 * * *",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    project_config=ProjectConfig("/opt/airflow/dbt"),
    profile_config=profile_config,
    execution_config=ExecutionConfig(dbt_executable_path="/home/airflow/.local/bin/dbt"),
    operator_args={"install_deps": True, "full_refresh": False},
    default_args={"retries": 1},
    tags=["dbt", "attribution"],
)
