#!/usr/bin/env bash
# run_bigquery_setup.sh
# Provisions all BigQuery datasets and tables for the streaming-media project.
#
# Prerequisites:
#   1. Google Cloud SDK installed: https://cloud.google.com/sdk/docs/install
#   2. Authenticated:   gcloud auth login
#   3. Project set:     gcloud config set project YOUR_PROJECT_ID
#   4. BigQuery API enabled in the GCP Console
#
# Usage:
#   chmod +x scripts/run_bigquery_setup.sh
#   PROJECT_ID=my-gcp-project ./scripts/run_bigquery_setup.sh

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}") /.." && pwd)"
cd "$ROOT"

PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
if [ -z "$PROJECT_ID" ]; then
  echo "ERROR: set PROJECT_ID env var or run: gcloud config set project YOUR_PROJECT"
  exit 1
fi

LOCATION="${BQ_LOCATION:-US}"
echo "Setting up BigQuery datasets in project: $PROJECT_ID  (location: $LOCATION)"

# --- Create datasets (idempotent) ---
for DATASET in raw staging intermediate marts snapshots meta; do
  echo "  → dataset: $PROJECT_ID.$DATASET"
  bq --project_id="$PROJECT_ID" mk \
    --dataset \
    --location="$LOCATION" \
    --description="streaming_media: $DATASET layer" \
    "$PROJECT_ID:$DATASET" 2>/dev/null || echo "    (already exists)"
done

# --- Substitute project id and run DDL ---
TMP=$(mktemp -d)
for f in bigquery/01_setup_datasets.sql \
          bigquery/02_setup_raw_tables.sql \
          bigquery/03_setup_meta_tables.sql; do
  out="$TMP/$(basename $f)"
  sed "s/YOUR_PROJECT_ID/$PROJECT_ID/g" "$f" > "$out"
  echo "  → $f"
  bq --project_id="$PROJECT_ID" query \
    --use_legacy_sql=false \
    --location="$LOCATION" \
    "$(cat "$out")"
done

rm -rf "$TMP"
echo ""
echo "✓ BigQuery setup complete for project: $PROJECT_ID"
echo "Next: python data_generator/generate_all.py && python data_generator/load_to_bigquery.py"
