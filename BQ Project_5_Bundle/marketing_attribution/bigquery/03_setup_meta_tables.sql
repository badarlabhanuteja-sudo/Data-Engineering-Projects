-- =====================================================================
-- 03_setup_meta_tables.sql
-- dbt run-history tracking table (equivalent to META.dbt_run_history).
-- Replace YOUR_PROJECT with your actual GCP project ID.
-- =====================================================================

CREATE TABLE IF NOT EXISTS `YOUR_PROJECT.meta.dbt_run_history` (
    invocation_id     STRING,
    run_started_at    TIMESTAMP,
    run_completed_at  TIMESTAMP,
    target_name       STRING,
    command           STRING,
    status            STRING,
    num_models_total  INT64,
    num_models_pass   INT64,
    num_models_fail   INT64,
    num_models_warn   INT64,
    execution_time_s  NUMERIC
);
