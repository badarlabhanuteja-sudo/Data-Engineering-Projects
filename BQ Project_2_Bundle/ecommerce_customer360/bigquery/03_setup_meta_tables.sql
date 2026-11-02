-- =====================================================================
-- 03_setup_meta_tables.sql
-- META dataset for experiment tracking and dissertation results.
-- =====================================================================

-- ---------------------------------------------------------------------
-- experiment_runs
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `META.experiment_runs` (
    run_id            INT64      NOT NULL,   -- manually managed or via sequence in app
    run_uuid          STRING     NOT NULL,
    condition         STRING     NOT NULL,   -- 'BASELINE_RFM' | 'INTERVENTION_ML'
    run_index         INT64,
    started_at        TIMESTAMP,
    completed_at      TIMESTAMP,
    duration_seconds  NUMERIC(12, 2),
    rows_in           INT64,
    rows_out          INT64,
    notes             STRING
);

-- ---------------------------------------------------------------------
-- experiment_metrics
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `META.experiment_metrics` (
    metric_id     INT64    NOT NULL,         -- manually managed or via sequence in app
    run_uuid      STRING   NOT NULL,
    condition     STRING   NOT NULL,
    metric_name   STRING   NOT NULL,
    metric_value  FLOAT64,
    captured_at   TIMESTAMP  DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------
-- experiment_predictions
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `META.experiment_predictions` (
    prediction_id    INT64   NOT NULL,       -- manually managed or via sequence in app
    run_uuid         STRING  NOT NULL,
    condition        STRING  NOT NULL,
    customer_id      INT64   NOT NULL,
    predicted_churn  BOOL,
    predicted_score  FLOAT64,
    actual_churn     BOOL
);

-- Verify
SELECT table_name, creation_time
  FROM `META.INFORMATION_SCHEMA.TABLES`
 ORDER BY table_name;
