-- =====================================================================
-- 01_setup_datasets.sql
-- Creates the BigQuery datasets (equivalent to Snowflake schemas).
-- Run once against your GCP project before loading any data.
--
-- Execute with:
--   bq mk --dataset --location=US --description "..." YOUR_PROJECT:DATASET
-- Or paste into the BigQuery console Query editor.
-- =====================================================================

-- ---------------------------------------------------------------------
-- RAW — bronze layer, source-system landing zone (immutable)
-- ---------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `RAW`
  OPTIONS (
    description = 'Bronze layer: source-system tables loaded as-is, no transformations',
    location     = 'US'
  );

-- ---------------------------------------------------------------------
-- STAGING — silver layer, dbt views (one per source table)
-- ---------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `STAGING`
  OPTIONS (
    description = 'Silver layer: typed, renamed, lightly cleaned views over RAW',
    location     = 'US'
  );

-- ---------------------------------------------------------------------
-- INTERMEDIATE — silver layer, joined and enriched models
-- ---------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `INTERMEDIATE`
  OPTIONS (
    description = 'Silver layer: multi-source joins, business-logic application',
    location     = 'US'
  );

-- ---------------------------------------------------------------------
-- MARTS — gold layer, star schema + business marts
-- ---------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `MARTS`
  OPTIONS (
    description = 'Gold layer: dim_*, fct_*, mart_* — BI-ready',
    location     = 'US'
  );

-- ---------------------------------------------------------------------
-- META — experiment results, run metadata, dbt artifacts
-- ---------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `META`
  OPTIONS (
    description = 'Experiment metadata and dissertation results',
    location     = 'US'
  );

-- ---------------------------------------------------------------------
-- SNAPSHOTS — dbt SCD2 snapshots
-- ---------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `SNAPSHOTS`
  OPTIONS (
    description = 'dbt-managed Type 2 slowly-changing dimension snapshots',
    location     = 'US'
  );
