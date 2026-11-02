-- =====================================================================
-- 01_setup_datasets.sql
-- BigQuery Sandbox: Create datasets (equivalent to Snowflake schemas)
-- Run with: bq mk or via GCP Console / bq CLI
--
-- NOTE: BigQuery Sandbox is free tier — no billing account required.
--       Datasets live in your GCP project (set PROJECT_ID below).
--       Replace YOUR_PROJECT_ID with your actual GCP project id.
-- =====================================================================

-- In BigQuery there are no warehouses or roles at the dataset level.
-- Access is controlled via IAM. Run these with the bq CLI:
--
--   bq --project_id=YOUR_PROJECT_ID mk --dataset --location=US \
--       --description="Bronze: source-system landing" \
--       YOUR_PROJECT_ID:raw
--
-- Or paste each CREATE SCHEMA statement in BigQuery Console > SQL Editor.

CREATE SCHEMA IF NOT EXISTS `YOUR_PROJECT_ID.raw`
  OPTIONS (
    description = "Bronze: source-system landing",
    location    = "US"
  );

CREATE SCHEMA IF NOT EXISTS `YOUR_PROJECT_ID.staging`
  OPTIONS (
    description = "Silver: cleaned views",
    location    = "US"
  );

CREATE SCHEMA IF NOT EXISTS `YOUR_PROJECT_ID.intermediate`
  OPTIONS (
    description = "Silver: joined and enriched",
    location    = "US"
  );

CREATE SCHEMA IF NOT EXISTS `YOUR_PROJECT_ID.marts`
  OPTIONS (
    description = "Gold: dim_*, fct_*, mart_*",
    location    = "US"
  );

CREATE SCHEMA IF NOT EXISTS `YOUR_PROJECT_ID.snapshots`
  OPTIONS (
    description = "dbt SCD2 snapshots",
    location    = "US"
  );

CREATE SCHEMA IF NOT EXISTS `YOUR_PROJECT_ID.meta`
  OPTIONS (
    description = "Experiment metadata",
    location    = "US"
  );
