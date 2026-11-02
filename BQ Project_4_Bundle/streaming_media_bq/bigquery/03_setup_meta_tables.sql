-- =====================================================================
-- 03_setup_meta_tables.sql
-- BigQuery Sandbox: Experiment metadata tables
--
-- NOTE: BigQuery has no IDENTITY/SEQUENCE columns.
--       Use STRING UUIDs as primary keys, or let your application
--       assign monotonic IDs via ROW_NUMBER() if needed.
-- =====================================================================

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.meta.experiment_runs` (
    run_id           INT64,           -- application-assigned (no AUTO_INCREMENT in BQ)
    run_uuid         STRING  NOT NULL,
    condition        STRING  NOT NULL,  -- BASELINE_NIGHTLY | INTERVENTION_HOURLY
    run_index        INT64,
    started_at       TIMESTAMP,
    completed_at     TIMESTAMP,
    duration_seconds FLOAT64,
    notes            STRING
);

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.meta.experiment_metrics` (
    metric_id        INT64,           -- application-assigned
    run_uuid         STRING  NOT NULL,
    condition        STRING  NOT NULL,
    metric_name      STRING  NOT NULL,
    metric_value     FLOAT64,
    captured_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- dbt run history (populated by the on-run-end macro)
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.meta.dbt_run_history` (
    invocation_id    STRING,
    run_started_at   TIMESTAMP,
    run_completed_at TIMESTAMP,
    target_name      STRING,
    command          STRING,
    status           STRING,
    num_models_total INT64,
    num_models_pass  INT64,
    num_models_fail  INT64,
    num_models_warn  INT64,
    execution_time_s FLOAT64
);
