CREATE OR REPLACE TABLE `your-project-id.meta.experiment_runs` (
    run_id          INT64,
    run_uuid        STRING NOT NULL,
    condition       STRING NOT NULL,
    run_index       INT64,
    started_at      TIMESTAMP,
    completed_at    TIMESTAMP,
    duration_seconds NUMERIC,
    notes           STRING
);

CREATE OR REPLACE TABLE `your-project-id.meta.experiment_metrics` (
    metric_id       INT64,
    run_uuid        STRING NOT NULL,
    condition       STRING NOT NULL,
    metric_name     STRING NOT NULL,
    metric_value    FLOAT64,
    captured_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE `your-project-id.meta.dbt_run_history` (
    invocation_id       STRING,
    run_started_at      TIMESTAMP,
    run_completed_at    TIMESTAMP,
    target_name         STRING,
    command             STRING,
    status              STRING,
    num_models_total    INT64,
    num_models_pass     INT64,
    num_models_fail     INT64,
    num_models_warn     INT64,
    execution_time_s    NUMERIC
);