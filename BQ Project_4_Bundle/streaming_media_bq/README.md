# Streaming Media Analytics — BigQuery Sandbox Edition

MSc Capstone Project 4 · Recommender freshness experiment

This codebase has been **fully migrated from Snowflake to Google BigQuery Sandbox**.
It is zero-cost to run: BigQuery Sandbox gives 10 GB free storage and 1 TB/month
free query processing — no billing account required.

---

## What changed from the Snowflake version

| Area | Snowflake (original) | BigQuery Sandbox (this version) |
|---|---|---|
| Warehouses / credits | XS/S virtual warehouses | Not applicable — serverless |
| IAM / roles | `ACCOUNTADMIN`, `DBT_ROLE`, `DBT_USER` | GCP project IAM (`roles/bigquery.dataEditor`) |
| Setup scripts | `snowflake/*.sql` + `run_snowflake_setup.sh` | `bigquery/*.sql` + `scripts/run_bigquery_setup.sh` |
| Data loading | `snowflake.connector` + PUT/COPY INTO | `google-cloud-bigquery` LoadJob |
| dbt adapter | `dbt-snowflake` | `dbt-bigquery` |
| dbt profiles | Snowflake account/user/password | OAuth (`gcloud auth application-default login`) |
| SQL functions | `DATEDIFF`, `SPLIT_PART`, `MONTHNAME`, `DAYNAME`, `payload:field::string`, `TIMESTAMP_LTZ/NTZ` | `DATE_DIFF`, `SPLIT()[SAFE_OFFSET(0)]`, `FORMAT_DATE('%B')`, `FORMAT_DATE('%A')`, `JSON_VALUE(payload, '$.field')`, `TIMESTAMP`/`DATETIME` |
| Incremental strategy | merge (Snowflake) | merge + `partition_by` (BigQuery) |
| Python dbt model | Snowpark (`session.create_dataframe`) | BQ Spark (`session.createDataFrame`) |
| Experiment metrics | `WAREHOUSE_METERING_HISTORY` | `credits_used = 0.0` (no metering API in Sandbox) |
| `docker-compose.yml` | MinIO + Snowflake env vars | GCP ADC volume mount, no MinIO |
| `.env` | `SNOWFLAKE_*` vars | `GCP_PROJECT_ID`, `BQ_LOCATION` |

---

## Quick start

### 1. Prerequisites

```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
gcloud auth login
gcloud auth application-default login        # sets up ADC for BigQuery client libs
gcloud config set project YOUR_PROJECT_ID

# Enable BigQuery API
gcloud services enable bigquery.googleapis.com
```

### 2. Clone & configure

```bash
cp .env.example .env
# Edit .env: set GCP_PROJECT_ID=your-gcp-project-id
```

### 3. Create BigQuery datasets and tables

```bash
PROJECT_ID=your-gcp-project-id bash scripts/run_bigquery_setup.sh
```

### 4. Generate synthetic data and load to BigQuery

```bash
pip install -r requirements.txt
python data_generator/generate_all.py          # writes CSVs/JSONL to synthetic_data/
python data_generator/load_to_bigquery.py      # loads into BigQuery raw.*
```

### 5. Run dbt

```bash
cd dbt
dbt deps                                       # install dbt_utils, dbt_expectations
dbt seed                                       # load seed CSVs
dbt run                                        # build all models
dbt test                                       # run tests
```

### 6. Run the experiment

```bash
python experiment/run_experiment.py
python experiment/statistical_analysis.py
python experiment/generate_charts.py
```

### 7. (Optional) Docker Compose

```bash
docker compose up -d
# Airflow UI: http://localhost:8080  (admin/admin)
```

---

## Project structure

```
streaming_media/
├── bigquery/               # DDL scripts (datasets, raw tables, meta tables)
├── dbt/
│   ├── models/
│   │   ├── staging/        # stg_* views  — Snowflake→BQ function rewrites
│   │   ├── intermediate/   # ephemeral CTEs
│   │   └── marts/
│   │       ├── core/       # dim_date, dim_title, dim_user_scd2, fct_*
│   │       ├── engagement/ # mart_user_engagement, mart_completion_rates_by_genre
│   │       ├── content/    # mart_content_performance
│   │       └── recommendations/  # mart_user_recommendations (BQ Spark Python)
│   ├── snapshots/          # SCD2 users snapshot
│   ├── macros/             # safe_divide, run history macros
│   ├── seeds/              # device_categories.csv
│   ├── tests/singular/
│   ├── profiles.yml        # BigQuery OAuth profile
│   └── dbt_project.yml
├── data_generator/
│   ├── generate_all.py
│   ├── generate_titles.py
│   ├── generate_users.py
│   ├── generate_sessions_and_views.py
│   ├── generate_ratings.py
│   └── load_to_bigquery.py   # replaces load_to_snowflake.py
├── experiment/
│   ├── run_experiment.py       # BigQuery client, no credits API
│   ├── statistical_analysis.py
│   └── generate_charts.py
├── airflow/dags/
│   ├── common.py
│   ├── extract_streaming_dag.py
│   ├── dbt_full_dag.py           # Cosmos + GoogleCloudOauthProfileMapping
│   ├── recommender_nightly_dag.py
│   ├── recommender_hourly_dag.py
│   ├── experiment_dag.py
│   └── dbt_test_dag.py
├── notebook/analysis.ipynb      # BigQuery client queries
├── scripts/run_bigquery_setup.sh
├── Dockerfile.dbt
├── docker-compose.yml
├── requirements.txt              # dbt-bigquery, google-cloud-bigquery, no snowflake-*
└── .env.example
```

---

## BigQuery Sandbox limits to be aware of

- **Storage**: 10 GB free; tables expire after 60 days unless you set `expiration_ms = null` explicitly.
- **Queries**: 1 TB/month free; use `partition_by` on `fct_view_events` (already configured) to limit scan costs.
- **No streaming inserts billing**: `insert_rows_json` (used in `run_experiment.py`) is free in Sandbox.
- **Python dbt models**: BigQuery Spark is available in standard projects; Sandbox may require a billing account to enable. If blocked, replace the Python model with the equivalent SQL using `ML.RECOMMEND` or a pre-computed similarity table.
