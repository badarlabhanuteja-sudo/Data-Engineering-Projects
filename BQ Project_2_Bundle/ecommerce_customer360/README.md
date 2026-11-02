# E-Commerce Customer 360 & Churn Analytics

**MSc Computer Science Capstone — Project 2**  
**Stack:** BigQuery · dbt Core · Apache Airflow · Python · Docker

## What This Is

An end-to-end ELT pipeline that ingests e-commerce orders, web clickstream, and email-marketing data into BigQuery, transforms it through a medallion-architected dbt project (staging → intermediate → marts), and produces a star-schema analytical layer powering Customer 360 profiles, RFM segmentation, and churn prediction.

The empirical research angle compares **rule-based RFM segmentation** against **statistical churn prediction (XGBoost)** on identical data, measuring precision, recall, F1, and engineering effort.

## Quick Start

```bash
# 1. Clone and configure
cp .env.example .env                   # edit with your GCP project ID

# 2. Place your GCP service account key
mkdir -p gcp && cp /path/to/sa-key.json gcp/sa-key.json

# 3. Bring up the stack
docker compose up -d                    # Airflow, Postgres, dbt-runner

# 4. Generate synthetic data
docker compose exec dbt-runner python /workspace/data_generator/generate_all.py

# 5. Load to BigQuery
docker compose exec dbt-runner python /workspace/data_generator/load_to_bigquery.py

# 6. Run dbt
docker compose exec dbt-runner bash -c "cd /workspace/dbt && dbt deps && dbt seed && dbt run && dbt test"

# 7. Launch Airflow UI
open http://localhost:8080              # creds in .env

# 8. Run experiment
docker compose exec dbt-runner python /workspace/experiment/run_experiment.py
docker compose exec dbt-runner python /workspace/experiment/statistical_analysis.py
docker compose exec dbt-runner python /workspace/experiment/generate_charts.py
```

## Repository Layout

```
ecommerce_customer360/
├── README.md                       (this file)
├── .env.example                    GCP credentials template
├── docker-compose.yml              Full local stack
├── Dockerfile.dbt                  dbt-runner image
├── requirements.txt                Python deps
├── gcp/                            Service account key (gitignored)
├── data_generator/                 Faker-driven synthetic data
├── dbt/                            Full dbt project (medallion architecture)
├── airflow/                        DAGs (Cosmos-rendered)
├── experiment/                     20-run paired comparison + stats + charts
├── notebook/                       Interactive analysis
├── scripts/                        Bash utilities
├── docs/                           Detailed phase-by-phase docs
└── diagrams/                       Architecture diagrams
```

## Required Reading (in order)

1. `Project_2_Overview_TechStack.docx`  — what this project is, why, and how it's architected
2. `Project_2_Execution_Guide.docx`     — step-by-step, phase-by-phase setup & run
3. This README                           — quick reference

## Key Stats

| Metric | Value |
|--------|-------|
| Synthetic orders | ~500,000 |
| Synthetic customers | ~50,000 |
| Synthetic web events | ~2,000,000 |
| dbt models | 30+ |
| Airflow DAGs | 8 |
| BigQuery estimated cost per full pipeline run | ~$0–2 (free tier eligible) |

## Reproducibility Note

All synthetic data is seeded (random seed = 42 by default). Two clean runs on identical hardware will produce identical row counts and identical experimental results within sampling error.