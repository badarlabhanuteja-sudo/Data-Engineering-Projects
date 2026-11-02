#!/usr/bin/env bash
# run_bigquery_setup.sh
# Executes the BigQuery DDL scripts in numerical order using the bq CLI.
# Requires: Google Cloud SDK installed and authenticated, .env populated.
# Note: scripts 00-02 create datasets/roles and must be run by a principal
#       with roles/bigquery.admin (or roles/owner) on the project.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ -f .env ]; then
    set -a; source .env; set +a
else
    echo "ERROR: .env not found in $ROOT"; exit 1
fi

PROJECT="${BIGQUERY_PROJECT:?BIGQUERY_PROJECT not set}"
LOCATION="${BIGQUERY_LOCATION:-US}"

# Optional: impersonate a service account for setup steps that need elevated
# permissions (equivalent to ACCOUNTADMIN in Snowflake).
IMPERSONATE_SA="${BIGQUERY_ADMIN_SA:-}"
IMPERSONATE_FLAG=""
if [ -n "$IMPERSONATE_SA" ]; then
    IMPERSONATE_FLAG="--impersonate_service_account=$IMPERSONATE_SA"
fi

echo "running BigQuery setup against project=$PROJECT location=$LOCATION"

run_sql() {
    local file="$1"
    echo
    echo "  → $file"
    bq query \
        --project_id="$PROJECT" \
        --location="$LOCATION" \
        --use_legacy_sql=false \
        --nouse_cache \
        $IMPERSONATE_FLAG \
        < "$file"
}

for f in bigquery/00_setup_datasets.sql \
         bigquery/01_setup_iam.sql \
         bigquery/02_setup_raw_tables.sql \
         bigquery/03_setup_meta_tables.sql ; do
    run_sql "$f"
done

echo
echo "✓ BigQuery setup complete"
