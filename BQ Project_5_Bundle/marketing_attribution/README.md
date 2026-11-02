# Marketing Attribution — BigQuery Migration

This project is a multi-touch marketing attribution pipeline built on
**Google BigQuery** + **dbt** + **Apache Airflow**. It implements five
attribution models (First Touch, Last Touch, Linear, Time Decay, Markov Chain)
and compares ROAS across all five side by side.

---

## Project Structure

```
marketing_attribution/
├── .env                          # BigQuery credentials (copy from .env.example)
├── .env.example
├── docker-compose.yml            # Airflow + Postgres + dbt-runner
├── Dockerfile.dbt
├── requirements.txt
│
├── bigquery/                     # One-time setup SQL (run manually in BQ Console)
│   ├── 01_setup_dataset.sql      # Dataset creation instructions
│   ├── 02_setup_raw_tables.sql   # Raw source tables DDL
│   └── 03_setup_meta_tables.sql  # dbt run history table
│
├── data_generator/
│   ├── generate_ad_spend.py
│   ├── generate_all.py
│   ├── generate_journeys.py
│   └── load_to_bigquery.py       # Loads synthetic_data/ CSVs into BigQuery
│
├── dbt/
│   ├── dbt_project.yml
│   ├── profiles.yml              # BigQuery connection profile
│   ├── packages.yml
│   ├── macros/
│   │   ├── utils.sql             # safe_divide, run-history macros
│   │   └── generate_schema_name.sql
│   ├── seeds/
│   │   ├── channels.csv
│   │   └── _seeds.yml
│   ├── models/
│   │   ├── staging/              # Views over raw BigQuery tables
│   │   ├── intermediate/         # Unified touchpoints + conversion paths
│   │   └── marts/
│   │       ├── attribution/      # 5 attribution models + ROAS comparison
│   │       └── recommendations/  # Budget reallocation mart
│   └── tests/singular/
│       └── assert_revenue_conserved.sql
│
├── airflow/dags/
│   ├── common.py
│   └── dbt_attribution_dag.py    # Cosmos-powered daily dbt run
│
├── scripts/
│   └── run_bigquery_setup.sh     # One-time dataset + table creation
│
└── experiment/                   # Statistical comparison scripts (unchanged)
```

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Python | 3.11+ | |
| dbt-bigquery | 1.8.2 | `pip install dbt-bigquery==1.8.2` |
| Google Cloud SDK | latest | `gcloud auth application-default login` |
| Docker + Compose | latest | For Airflow stack |
| BigQuery Sandbox | free | No credit card required |

---

## Quick Start

### 1. Configure credentials

```bash
cp .env.example .env
# Edit .env and set:
#   GCP_PROJECT=your-gcp-project-id
#   GCP_LOCATION=US
#   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

**BigQuery Sandbox (no billing required):**
- Go to https://console.cloud.google.com/bigquery
- Create a project (free sandbox mode is auto-enabled)
- IAM → Service Accounts → Create → assign `BigQuery Data Editor` + `BigQuery Job User` roles
- Download the JSON key and set `GOOGLE_APPLICATION_CREDENTIALS` to its path

Or use Application Default Credentials for local dev:
```bash
gcloud auth application-default login
# Then set method: oauth in profiles.yml instead of service-account
```

### 2. Create BigQuery datasets and tables

```bash
chmod +x scripts/run_bigquery_setup.sh
./scripts/run_bigquery_setup.sh
```

Or manually in BigQuery Console — open `bigquery/02_setup_raw_tables.sql`,
replace `YOUR_PROJECT` with your project ID, and run it.

### 3. Generate and load synthetic data

```bash
pip install -r requirements.txt

# Generate CSVs
python data_generator/generate_all.py

# Load into BigQuery
python data_generator/load_to_bigquery.py
```

### 4. Run dbt

```bash
cd dbt
dbt deps          # install dbt_utils + dbt_expectations packages
dbt seed          # load channels.csv reference table
dbt run           # build all models
dbt test          # run data quality tests
```

### 5. (Optional) Launch Airflow

```bash
docker compose up -d
# Airflow UI → http://localhost:8080  (admin / admin)
# Enable the dag: dbt_attribution_dag
```

---

## BigQuery-Specific Changes from the Original Codebase

### SQL function mapping

| Original (other dialect) | BigQuery equivalent |
|--------------------------|---------------------|
| `DATEDIFF('hour', a, b)` | `TIMESTAMP_DIFF(b, a, HOUR)` |
| `DATEADD('day', -N, ts)` | `TIMESTAMP_SUB(ts, INTERVAL N DAY)` |
| `CAST(ts AS DATE)` | `DATE(ts)` |
| `LISTAGG(col, ' > ') WITHIN GROUP (ORDER BY ...)` | `STRING_AGG(col, ' > ' ORDER BY ...)` |
| `CURRENT_TIMESTAMP()` | `CURRENT_TIMESTAMP()` ✓ same |
| `NULLIF(x, 0)` | `NULLIF(x, 0)` ✓ same |
| `COALESCE(...)` | `COALESCE(...)` ✓ same |
| `NULL` (untyped) | `CAST(NULL AS STRING)` — BigQuery requires typed NULLs in UNIONs |
| `::float` cast | `CAST(x AS FLOAT64)` |
| `VARIANT` column type | `JSON` |
| `TIMESTAMP_NTZ` / `TIMESTAMP_LTZ` | `TIMESTAMP` |
| `VARCHAR(N)` | `STRING` |
| `NUMBER(12,2)` | `NUMERIC` |
| `NUMBER(38,0)` | `INT64` |

### `safe_divide` macro

The macro now wraps BigQuery's built-in `SAFE_DIVIDE()`:

```sql
{% macro safe_divide(numerator, denominator) %}
    SAFE_DIVIDE(CAST({{ numerator }} AS FLOAT64), CAST({{ denominator }} AS FLOAT64))
{% endmacro %}
```

### Markov model (Python dbt model)

The Python model now uses the standard **BigQuery Python dbt** interface
(`dbt.ref(...).to_pandas()`). BigQuery Python models run on **Dataproc Serverless**.

To enable: in your Google Cloud project, enable the Dataproc API and configure
a Dataproc connection in `profiles.yml`:
```yaml
submission_method: serverless
dataproc_region: us-central1
```

Alternatively, if you prefer not to use Dataproc, convert
`mart_markov_attribution.py` to a SQL model using BigQuery ML or a JavaScript
UDF — see the comment at the top of the file.

### Dataset layout (BigQuery = no top-level database)

| Layer | BigQuery Dataset | dbt `+schema` |
|-------|-----------------|---------------|
| Raw source tables | `raw` | `raw` |
| Staging views | `raw` | `raw` |
| Intermediate (ephemeral) | — | — |
| Attribution marts | `analytics` | `analytics` |
| Seeds | `raw` | `raw` |
| Test failures | `dbt_test_failures` | `dbt_test_failures` |
| Run history | `meta` | — |

---

## Key dbt Models

| Model | Layer | Description |
|-------|-------|-------------|
| `stg_google_ads` | Staging | Google Ads click/impression events |
| `stg_meta_ads` | Staging | Meta (Facebook/Instagram) ad events |
| `stg_tiktok_ads` | Staging | TikTok ad events |
| `stg_email_events` | Staging | Email open/click events |
| `stg_web_events` | Staging | Organic + UTM-tagged web events |
| `stg_conversions` | Staging | Purchase / signup / lead events |
| `stg_ad_spend` | Staging | Daily channel spend for ROAS |
| `int_unified_touchpoints` | Intermediate | All channels in one schema |
| `int_conversion_paths` | Intermediate | Ordered touchpoints per conversion |
| `int_path_summary` | Intermediate | Channel path string per conversion |
| `mart_first_touch_attribution` | Mart | Model A: 100% credit to first touch |
| `mart_last_touch_attribution` | Mart | Model B: 100% credit to last touch |
| `mart_linear_attribution` | Mart | Model C: equal credit across path |
| `mart_time_decay_attribution` | Mart | Model D: exponential decay toward conversion |
| `mart_markov_attribution` | Mart | Model E: removal-effect Markov chain |
| `mart_channel_roas_compared` | Mart | All 5 models + ROAS side by side |
| `mart_budget_reallocation` | Mart | Recommended spend per channel |

---

## BigQuery Sandbox Limits

The free BigQuery Sandbox includes:
- **10 GB** of active storage per month
- **1 TB** of query processing per month
- No expiry on the sandbox (tables expire after 60 days unless you upgrade)

The synthetic dataset (~200 MB total) fits comfortably within sandbox limits.
