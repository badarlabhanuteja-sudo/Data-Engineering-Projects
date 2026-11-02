# Healthcare Outcomes & PHI Governance Pipeline

**MSc Computer Science Capstone — Project 3**
**Stack:** BigQuery · dbt Core (with contracts) · Apache Airflow · Docker

## What This Is

An end-to-end analytics platform for a hospital network. Ingests synthetic FHIR-style patient records (Synthea-equivalent), encounters, conditions, observations, medications, and procedures into BigQuery. dbt transforms them through a medallion architecture into clinical analytics marts (readmission risk, length-of-stay analytics, condition prevalence) and governance marts (audit logs, query attribution).

The empirical research angle compares **BigQuery column-level security (Data Catalog policy tags) + Row Access Policies + dbt contracts** (INTERVENTION) against **view-based PHI redaction** (BASELINE), measuring query latency overhead, governance-policy violations caught, developer-friction (LOC + test failures), and BigQuery slot cost across 20 paired runs.

## Quick Start

```bash
cp .env.example .env                              # edit BQ_PROJECT + BQ_KEYFILE_PATH
docker compose up -d --build
bash scripts/run_bigquery_setup.sh                # 6 SQL scripts (datasets, roles, raw tables, governance, baseline views, meta)
docker compose exec dbt-runner python /workspace/data_generator/generate_all.py
docker compose exec dbt-runner python /workspace/data_generator/load_to_bigquery.py
docker compose exec dbt-runner bash -c "cd /workspace/dbt && dbt deps && dbt seed && dbt run && dbt test"
docker compose exec dbt-runner python /workspace/experiment/run_experiment.py
docker compose exec dbt-runner python /workspace/experiment/statistical_analysis.py
docker compose exec dbt-runner python /workspace/experiment/generate_charts.py
```

### Prerequisites
- GCP project with the BigQuery and Data Catalog APIs enabled
- A service account with `roles/bigquery.dataEditor` and `roles/bigquery.jobUser` on the project
- Service account key JSON placed at the path in `BQ_KEYFILE_PATH` (or use Application Default Credentials by leaving it empty)

## Repository Layout

```
healthcare_outcomes/
├── README.md, .env.example, docker-compose.yml, Dockerfile.dbt, requirements.txt
├── bigquery/          (6 DDL scripts: datasets, roles, raw tables, governance policies, baseline views, meta)
├── data_generator/    Synthetic FHIR-style patient + encounter + observation generator
├── dbt/               medallion: staging → intermediate → marts/clinical + marts/governance
│   └── tests/singular/ Governance assertions (no PHI in marts, policy tags applied, etc.)
├── airflow/dags/      6 DAGs
├── experiment/        Governance-overhead comparison
├── notebook/          Interactive analysis
└── scripts/           BigQuery setup helper
```

## Key Stats

| Metric | Value |
|---|---|
| Synthetic patients | 100,000 |
| Synthetic encounters | ~800,000 |
| Synthetic observations (vitals/labs) | ~5,000,000 |
| Synthetic conditions | ~400,000 |
| Synthetic medications | ~600,000 |
| dbt models | ~22 |

## Synthetic Data — HIPAA Safety

All data is generated synthetically. No real patient identifiers are used. Patient-level fields (name, MRN, date of birth, address) are Faker-generated and have no correspondence with any real person. The project is HIPAA-safe by construction.

## BigQuery vs Original Architecture Notes

| Concept | Original | This Version |
|---|---|---|
| Compute unit | Snowflake Virtual Warehouse | BigQuery slot reservation / on-demand |
| PHI column masking | Dynamic Data Masking policies | Data Catalog policy tags (column-level security) |
| Row filtering | Row Access Policy (Snowflake) | BigQuery Row Access Policy |
| Bulk load | Snowflake internal stage + COPY INTO | BigQuery `load_table_from_file` (CSV direct) |
| Incremental strategy | `merge` with `cluster_by` | `merge` with `partition_by` (monthly) + `cluster_by` |
| Date functions | `MONTHNAME`, `DAYNAME`, `EXTRACT(DOW …)` | `FORMAT_DATE`, `EXTRACT(DAYOFWEEK …)` |
| Median aggregate | `MEDIAN()` | `PERCENTILE_CONT(x, 0.5) OVER ()` |
| Resource monitoring | Snowflake Resource Monitor | BigQuery budget alerts (set in GCP Billing) |
