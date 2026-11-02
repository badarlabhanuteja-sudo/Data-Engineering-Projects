-- =====================================================================
-- 00_setup_dataset.sql
-- =====================================================================
-- Run with a principal that has roles/bigquery.dataOwner and
-- roles/resourcemanager.projectIamAdmin on the target project.
-- Replace PROJECT_ID with your actual GCP project ID.
-- =====================================================================

-- Create datasets (BigQuery equivalent of schemas/database+schema combos)
CREATE SCHEMA IF NOT EXISTS `PROJECT_ID.raw`
  OPTIONS (
    description = 'Bronze: source landing (synthetic FHIR)',
    location     = 'US'
  );

CREATE SCHEMA IF NOT EXISTS `PROJECT_ID.staging`
  OPTIONS (
    description = 'Silver: cleaned views',
    location     = 'US'
  );

CREATE SCHEMA IF NOT EXISTS `PROJECT_ID.intermediate`
  OPTIONS (
    description = 'Silver: joined and enriched',
    location     = 'US'
  );

CREATE SCHEMA IF NOT EXISTS `PROJECT_ID.marts`
  OPTIONS (
    description = 'Gold: clinical + governance marts',
    location     = 'US'
  );

CREATE SCHEMA IF NOT EXISTS `PROJECT_ID.governance`
  OPTIONS (
    description = 'BigQuery column-level security taxonomy + policy tags',
    location     = 'US'
  );

CREATE SCHEMA IF NOT EXISTS `PROJECT_ID.baseline`
  OPTIONS (
    description = 'View-based PHI redaction (BASELINE arm of experiment)',
    location     = 'US'
  );

CREATE SCHEMA IF NOT EXISTS `PROJECT_ID.snapshots`
  OPTIONS (
    description = 'dbt SCD2 snapshots',
    location     = 'US'
  );

CREATE SCHEMA IF NOT EXISTS `PROJECT_ID.meta`
  OPTIONS (
    description = 'Experiment metadata + audit logs',
    location     = 'US'
  );
