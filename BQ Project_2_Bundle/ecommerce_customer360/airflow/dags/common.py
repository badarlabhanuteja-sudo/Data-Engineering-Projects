import os
from datetime import timedelta

DBT_PROJECT_PATH  = "/opt/airflow/dbt"
DBT_PROFILES_PATH = "/opt/airflow/dbt"

DEFAULT_ARGS = {
    "owner":             "msc-capstone",
    "depends_on_past":   False,
    "email_on_failure":  False,
    "email_on_retry":    False,
    "retries":           1,
    "retry_delay":       timedelta(minutes=5),
    "execution_timeout": timedelta(hours=2),
}

# BigQuery connection kwargs — used by python operators that call BQ directly
BQ_CONN_KW = {
    "project": os.environ["GCP_PROJECT_ID"],
    # Credentials resolved automatically from GOOGLE_APPLICATION_CREDENTIALS
    # or Workload Identity when running on GKE/Cloud Composer.
}

GCP_PROJECT = os.environ["GCP_PROJECT_ID"]
