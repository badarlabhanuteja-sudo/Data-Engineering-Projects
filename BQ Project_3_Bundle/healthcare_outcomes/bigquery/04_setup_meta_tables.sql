-- =====================================================================
-- 05_setup_meta_tables.sql
-- Replace PROJECT_ID with your actual GCP project ID.
-- =====================================================================

CREATE OR REPLACE TABLE `PROJECT_ID.meta.experiment_runs` (
    run_id           INT64          OPTIONS (description = 'Auto-increment via INSERT SELECT MAX'),
    run_uuid         STRING         NOT NULL,
    condition        STRING         NOT NULL,    -- BASELINE_VIEWS | INTERVENTION_POLICIES
    run_index        INT64,
    started_at       TIMESTAMP,
    completed_at     TIMESTAMP,
    duration_seconds NUMERIC,
    notes            STRING
);

CREATE OR REPLACE TABLE `PROJECT_ID.meta.experiment_metrics` (
    metric_id        INT64,
    run_uuid         STRING         NOT NULL,
    condition        STRING         NOT NULL,
    metric_name      STRING         NOT NULL,
    metric_value     FLOAT64,
    captured_at      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP()
);

-- Per-query latency log
CREATE OR REPLACE TABLE `PROJECT_ID.meta.experiment_query_log` (
    query_log_id     INT64,
    run_uuid         STRING         NOT NULL,
    condition        STRING         NOT NULL,
    role_simulated   STRING,        -- analyst / clinician / phi_admin
    query_template   STRING,
    rows_returned    INT64,
    elapsed_ms       NUMERIC,
    captured_at      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP()
);

-- Audit log (governance violations caught + bypass attempts)
CREATE OR REPLACE TABLE `PROJECT_ID.meta.governance_audit_log` (
    audit_id         INT64,
    run_uuid         STRING,
    condition        STRING,
    audit_check      STRING,
    pass_or_fail     STRING,
    detail           STRING,
    captured_at      TIMESTAMP      DEFAULT CURRENT_TIMESTAMP()
);
