-- =====================================================================
-- 04_setup_baseline_views.sql
-- =====================================================================
-- BASELINE arm: PHI redaction via simple views without column-level
-- policy tags. This is the pattern most teams adopt before discovering
-- BigQuery column-level security. It works but has well-known weaknesses:
--
--   1. Every consumer SQL must reference the view, not the underlying
--      table. Forgetting → PHI leak.
--   2. New columns in the underlying table are not redacted by default.
--   3. There is no role-based unmasking — clinicians cannot see real
--      values without a separate, manually-managed view.
--   4. There is no row-level filtering at all — must be re-implemented
--      per-view as a WHERE clause.
--
-- These views are referenced by the BASELINE-arm queries in the
-- experiment to give a fair comparison.
-- Replace PROJECT_ID with your actual GCP project ID.
-- =====================================================================

-- A view-based redaction of patient data — only de-identified columns
-- are exposed. Effectively a one-size-fits-all mask.
CREATE OR REPLACE VIEW `PROJECT_ID.baseline.vw_patient_deidentified` AS
SELECT
    patient_id,
    -- All PHI removed
    'REDACTED'                                        AS first_name,
    'REDACTED'                                        AS last_name,
    'MRN_*****'                                       AS mrn,
    CAST(NULL AS DATE)                                AS date_of_birth,
    CONCAT(SUBSTR(address_postal_code, 1, 3), '**')   AS address_postal_code_3digit,
    CAST(NULL AS STRING)                              AS phone_number,
    CAST(NULL AS STRING)                              AS email,
    -- Non-PHI columns
    gender, race, ethnicity, marital_status,
    address_state, primary_language,
    insurance_plan,
    is_deceased, deceased_date,
    created_at, updated_at
FROM `PROJECT_ID.raw.raw_patients`
-- Mimic the row access policy
WHERE NOT is_deceased
   OR DATE_DIFF(CURRENT_DATE(), deceased_date, YEAR) <= 5;

-- A separate "clinician" view, manually managed.
CREATE OR REPLACE VIEW `PROJECT_ID.baseline.vw_patient_clinician` AS
SELECT
    patient_id, first_name, last_name, mrn,
    DATE(EXTRACT(YEAR FROM date_of_birth), 1, 1)     AS date_of_birth_year_only,
    address_postal_code,
    CAST(NULL AS STRING)                              AS phone_number,  -- still redacted
    CAST(NULL AS STRING)                              AS email,          -- still redacted
    gender, race, ethnicity, marital_status,
    address_state, primary_language,
    insurance_plan,
    is_deceased, deceased_date,
    created_at, updated_at
FROM `PROJECT_ID.raw.raw_patients`;
