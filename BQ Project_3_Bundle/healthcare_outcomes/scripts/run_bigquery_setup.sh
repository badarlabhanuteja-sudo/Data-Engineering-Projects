#!/usr/bin/env bash
# run_bigquery_setup.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}"}/.." && pwd)"
cd "$ROOT"
if [ -f .env ]; then set -a; source .env; set +a; else echo "ERROR: .env not found"; exit 1; fi

PROJECT="${BQ_PROJECT:?BQ_PROJECT must be set}"
LOCATION="${BQ_LOCATION:-US}"

echo "running BigQuery setup for project $PROJECT (location: $LOCATION)"

for f in bigquery/00_setup_dataset.sql \
          bigquery/01_setup_roles_grants.sql \
          bigquery/02_setup_raw_tables.sql \
          bigquery/03_setup_governance_policies.sql \
          bigquery/04_setup_baseline_views.sql \
          bigquery/05_setup_meta_tables.sql ; do
    # Replace PROJECT_ID placeholder with the real project
    TMPFILE=$(mktemp /tmp/bq_setup_XXXXXX.sql)
    sed "s/PROJECT_ID/${PROJECT}/g" "$f" > "$TMPFILE"
    echo
    echo "  → $f"
    bq query \
        --project_id="$PROJECT" \
        --location="$LOCATION" \
        --use_legacy_sql=false \
        < "$TMPFILE"
    rm -f "$TMPFILE"
done

echo
echo "✓ BigQuery setup complete"
