#!/usr/bin/env bash
# run_bigquery_setup.sh
# Creates BigQuery datasets and raw tables.
# Prerequisites: gcloud CLI authenticated, bq CLI available.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}"}/.." && pwd)"
cd "$ROOT"

if [ -f .env ]; then set -a; source .env; set +a; else echo "ERROR: .env not found"; exit 1; fi

PROJECT="${GCP_PROJECT:?GCP_PROJECT is not set in .env}"
LOCATION="${GCP_LOCATION:-US}"

echo "Setting up BigQuery project: $PROJECT  (location: $LOCATION)"

# ── Create datasets ──────────────────────────────────────────────────
for dataset in raw analytics meta dbt_test_failures; do
    echo "  → Creating dataset: $dataset"
    bq mk --location="$LOCATION" --dataset "$PROJECT:$dataset" 2>/dev/null || \
        echo "    (already exists)"
done

# ── Create raw tables ─────────────────────────────────────────────────
echo "  → Creating raw tables..."
bq query --project_id="$PROJECT" --use_legacy_sql=false \
    < bigquery/02_setup_raw_tables.sql

# ── Create meta tables ────────────────────────────────────────────────
echo "  → Creating meta tables..."
# Replace placeholder with actual project ID
sed "s/YOUR_PROJECT/$PROJECT/g" bigquery/03_setup_meta_tables.sql | \
    bq query --project_id="$PROJECT" --use_legacy_sql=false

echo
echo "✓ BigQuery setup complete"
echo "Next steps:"
echo "  1. python data_generator/load_to_bigquery.py"
echo "  2. cd dbt && dbt deps && dbt seed && dbt run && dbt test"
