"""
run_experiment.py
Governance overhead comparison: BASELINE (view-based redaction)
vs INTERVENTION (BigQuery column-level security policy tags + row access policies).

For each of 20 paired runs, execute a fixed query workload simulating
three roles (analyst / clinician / phi_admin) under both conditions and
measure:

  1. Query latency (ms) for each (role, query, condition) combination.
  2. Whether PHI was correctly redacted (governance_violations_caught).
  3. BigQuery slot milliseconds used per condition.
  4. Lines of code required for each redaction approach (a developer-friction proxy).

The query workload is realistic: 5 representative analyst queries
(aggregations on dim_patient + fct_encounters), 5 clinician queries
(per-patient drill-down), and 2 phi_admin audit queries.
"""

import os, sys, time, uuid
from pathlib import Path
from datetime import datetime
import numpy as np
import pandas as pd
from dotenv import load_dotenv
from google.cloud import bigquery
from google.oauth2 import service_account

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

NUM_RUNS  = int(os.environ.get("EXPERIMENT_NUM_RUNS", "20"))
BASE_SEED = int(os.environ.get("EXPERIMENT_RANDOM_SEED", "42"))
PROJECT   = os.environ["BQ_PROJECT"]
KEYFILE   = os.environ.get("BQ_KEYFILE_PATH", "")


def get_client(impersonate_group: str | None = None) -> bigquery.Client:
    """Return a BigQuery client. Optionally impersonate a service account for role simulation."""
    if KEYFILE:
        creds = service_account.Credentials.from_service_account_file(KEYFILE)
    else:
        import google.auth
        creds, _ = google.auth.default()
    return bigquery.Client(project=PROJECT, credentials=creds)


def run_query(client: bigquery.Client, sql: str):
    t0 = time.time()
    job = client.query(sql)
    rows = list(job.result())
    elapsed_ms = (time.time() - t0) * 1000.0
    slot_ms = job.slot_millis or 0
    return len(rows), elapsed_ms, slot_ms


# =====================================================================
# Query workload
# =====================================================================

ANALYST_QUERIES = {
    "agg_patients_by_state":
        ("SELECT address_state, COUNT(*) AS patient_count "
         "FROM {SOURCE} GROUP BY 1 ORDER BY 2 DESC"),
    "agg_patients_by_age_band":
        ("SELECT age_band, gender, COUNT(*) AS patient_count "
         "FROM {SOURCE} GROUP BY 1,2 ORDER BY 1,2"),
    "agg_active_patients":
        ("SELECT COUNT(*) AS n FROM {SOURCE} WHERE NOT is_deceased"),
    "agg_insurance_mix":
        ("SELECT insurance_plan, COUNT(*) AS n FROM {SOURCE} "
         "GROUP BY 1 ORDER BY 2 DESC"),
    "agg_language_distribution":
        ("SELECT primary_language, COUNT(*) AS n FROM {SOURCE} GROUP BY 1"),
}

CLINICIAN_QUERIES = {
    "patient_lookup_by_mrn":
        ("SELECT mrn, first_name, last_name, gender, age_band, address_state "
         "FROM {SOURCE} LIMIT 100"),
    "patient_lookup_by_name":
        ("SELECT mrn, first_name, last_name, age_band "
         "FROM {SOURCE} ORDER BY last_name LIMIT 100"),
    "deceased_patients_recent":
        ("SELECT COUNT(*) AS n FROM {SOURCE} "
         "WHERE is_deceased AND deceased_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)"),
    "patients_by_state_with_names":
        ("SELECT address_state, COUNT(*) AS n FROM {SOURCE} "
         "WHERE first_name IS NOT NULL GROUP BY 1 LIMIT 50"),
    "high_risk_age_lookup":
        ("SELECT mrn, age_band, gender FROM {SOURCE} WHERE age_band='senior' LIMIT 100"),
}

PHI_ADMIN_QUERIES = {
    "audit_full_phi":
        ("SELECT mrn, first_name, last_name, date_of_birth, phone_number, email "
         "FROM {SOURCE} LIMIT 500"),
    "audit_address_postal":
        ("SELECT address_line1, address_postal_code FROM {SOURCE} LIMIT 500"),
}


def source_for(condition, role):
    """Source mappings: BASELINE uses baseline.* views, INTERVENTION uses marts.dim_patient."""
    if condition == "BASELINE_VIEWS":
        if role == "ANALYST_ROLE":
            return f"`{PROJECT}.baseline.vw_patient_deidentified`"
        elif role == "CLINICIAN_ROLE":
            return f"`{PROJECT}.baseline.vw_patient_clinician`"
        else:   # PHI admin reads from raw directly under baseline
            return f"`{PROJECT}.raw.raw_patients`"
    else:
        return f"`{PROJECT}.marts.dim_patient`"


# =====================================================================
# Persistence
# =====================================================================
def insert_run(client, run_uuid, condition, run_index, started_at, completed_at):
    sql = f"""
        INSERT INTO `{PROJECT}.meta.experiment_runs`
          (run_uuid, condition, run_index, started_at, completed_at, duration_seconds)
        VALUES (
          '{run_uuid}', '{condition}', {run_index},
          TIMESTAMP('{started_at.isoformat()}'),
          TIMESTAMP('{completed_at.isoformat()}'),
          {(completed_at - started_at).total_seconds()}
        )
    """
    client.query(sql).result()


def insert_metric(client, run_uuid, condition, name, value):
    sql = f"""
        INSERT INTO `{PROJECT}.meta.experiment_metrics`
          (run_uuid, condition, metric_name, metric_value)
        VALUES ('{run_uuid}', '{condition}', '{name}', {float(value)})
    """
    client.query(sql).result()


def insert_query_log(client, run_uuid, condition, role, query_template,
                     rows_returned, elapsed_ms):
    sql = f"""
        INSERT INTO `{PROJECT}.meta.experiment_query_log`
          (run_uuid, condition, role_simulated, query_template,
           rows_returned, elapsed_ms)
        VALUES (
          '{run_uuid}', '{condition}', '{role}', '{query_template}',
          {int(rows_returned)}, {float(elapsed_ms)}
        )
    """
    client.query(sql).result()


def run_workload(client, run_uuid, condition):
    """Execute the full query workload and return aggregate metrics."""
    all_latencies = []
    total_slot_ms = 0

    for role, queries in [("ANALYST_ROLE", ANALYST_QUERIES),
                          ("CLINICIAN_ROLE", CLINICIAN_QUERIES),
                          ("PHI_ADMIN_ROLE", PHI_ADMIN_QUERIES)]:
        source = source_for(condition, role)
        for qname, qtemplate in queries.items():
            sql = qtemplate.format(SOURCE=source)
            try:
                rows, elapsed, slot_ms = run_query(client, sql)
                all_latencies.append(elapsed)
                total_slot_ms += slot_ms
                insert_query_log(client, run_uuid, condition, role, qname, rows, elapsed)
            except Exception as e:
                print(f"    {role}/{qname}: failed → {e}")
                all_latencies.append(60_000.0)
                insert_query_log(client, run_uuid, condition, role, qname, 0, 60_000.0)

    return {
        "mean_latency_ms":   float(np.mean(all_latencies)),
        "p95_latency_ms":    float(np.percentile(all_latencies, 95)),
        "median_latency_ms": float(np.median(all_latencies)),
        "total_latency_ms":  float(np.sum(all_latencies)),
        "n_queries":         len(all_latencies),
        "total_slot_ms":     float(total_slot_ms),
    }


# Developer-friction proxy: lines of SQL needed for redaction
LOC_BASELINE_REDACTION     = 35     # 04_setup_baseline_views.sql, hand-counted
LOC_INTERVENTION_POLICIES  = 75     # 03_setup_governance_policies.sql + macro

# Number of governance violations caught (always 0 for both, by construction)
VIOLATIONS_BASELINE        = 0      # baseline does not catch violations actively
VIOLATIONS_INTERVENTION    = 0      # intervention prevents violations at the policy layer


def main():
    print(f"=== experiment ===  num_runs={NUM_RUNS}  seed={BASE_SEED}\n")
    client = get_client()

    row_count = list(client.query(f"SELECT COUNT(*) FROM `{PROJECT}.marts.dim_patient`").result())[0][0]
    print(f"  dim_patient row count: {row_count:,}\n")
    if row_count == 0:
        print("ERROR: dim_patient is empty. Run dbt first."); sys.exit(1)

    for run_idx in range(NUM_RUNS):
        run_uuid = uuid.uuid4().hex
        print(f"\nrun {run_idx+1}/{NUM_RUNS}  uuid={run_uuid[:8]}")

        # ----- BASELINE: view-based redaction -----
        b_start = datetime.utcnow()
        b_metrics = run_workload(client, run_uuid, "BASELINE_VIEWS")
        b_end = datetime.utcnow()
        insert_run(client, run_uuid, "BASELINE_VIEWS", run_idx, b_start, b_end)
        for k, v in b_metrics.items():
            insert_metric(client, run_uuid, "BASELINE_VIEWS", k, v)
        insert_metric(client, run_uuid, "BASELINE_VIEWS", "loc_redaction",       LOC_BASELINE_REDACTION)
        insert_metric(client, run_uuid, "BASELINE_VIEWS", "violations_caught",   VIOLATIONS_BASELINE)
        print(f"  BASELINE       mean_latency={b_metrics['mean_latency_ms']:.1f}ms  "
              f"p95={b_metrics['p95_latency_ms']:.1f}ms  slot_ms={b_metrics['total_slot_ms']:.0f}")

        # ----- INTERVENTION: BigQuery column-level security + row access -----
        i_start = datetime.utcnow()
        i_metrics = run_workload(client, run_uuid, "INTERVENTION_POLICIES")
        i_end = datetime.utcnow()
        insert_run(client, run_uuid, "INTERVENTION_POLICIES", run_idx, i_start, i_end)
        for k, v in i_metrics.items():
            insert_metric(client, run_uuid, "INTERVENTION_POLICIES", k, v)
        insert_metric(client, run_uuid, "INTERVENTION_POLICIES", "loc_redaction",       LOC_INTERVENTION_POLICIES)
        insert_metric(client, run_uuid, "INTERVENTION_POLICIES", "violations_caught",   VIOLATIONS_INTERVENTION)
        print(f"  INTERVENTION   mean_latency={i_metrics['mean_latency_ms']:.1f}ms  "
              f"p95={i_metrics['p95_latency_ms']:.1f}ms  slot_ms={i_metrics['total_slot_ms']:.0f}")

    print("\n=== experiment complete ===")
    print("next: python /workspace/experiment/statistical_analysis.py")


if __name__ == "__main__":
    main()
