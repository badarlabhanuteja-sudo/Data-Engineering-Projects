-- =====================================================================
-- 02_setup_raw_tables.sql
-- FHIR-equivalent resource tables: Patient, Encounter, Condition,
-- Observation, MedicationRequest, Procedure.
-- Replace PROJECT_ID with your actual GCP project ID.
-- =====================================================================

-- ---------------------------------------------------------------------
-- raw_patients — FHIR Patient
-- All PHI columns are flagged in comments.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `PROJECT_ID.raw.raw_patients` (
    patient_id          STRING        NOT NULL,
    mrn                 STRING,       -- PHI: medical record number
    first_name          STRING,       -- PHI
    last_name           STRING,       -- PHI
    date_of_birth       DATE,         -- PHI
    gender              STRING,
    race                STRING,
    ethnicity           STRING,
    marital_status      STRING,
    address_line1       STRING,       -- PHI
    address_city        STRING,       -- PHI (in combination)
    address_state       STRING,
    address_postal_code STRING,       -- PHI (3-digit prefix safe; full not safe)
    phone_number        STRING,       -- PHI
    email               STRING,       -- PHI
    insurance_id        STRING,       -- PHI
    insurance_plan      STRING,
    primary_language    STRING,
    is_deceased         BOOL,
    deceased_date       DATE,
    created_at          TIMESTAMP,
    updated_at          TIMESTAMP,
    _loaded_at          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------
-- raw_encounters — FHIR Encounter
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `PROJECT_ID.raw.raw_encounters` (
    encounter_id            STRING   NOT NULL,
    patient_id              STRING,
    encounter_class         STRING,  -- inpatient / outpatient / ambulatory / emergency
    encounter_type          STRING,
    admission_timestamp     TIMESTAMP,
    discharge_timestamp     TIMESTAMP,
    length_of_stay_hours    NUMERIC,
    department              STRING,
    primary_diagnosis_code  STRING,  -- ICD-10
    primary_diagnosis_text  STRING,
    discharge_disposition   STRING,
    is_readmission_30d      BOOL,
    total_charges           NUMERIC,
    created_at              TIMESTAMP,
    updated_at              TIMESTAMP,
    _loaded_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------
-- raw_observations — FHIR Observation (vitals + labs)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `PROJECT_ID.raw.raw_observations` (
    observation_id        STRING   NOT NULL,
    patient_id            STRING,
    encounter_id          STRING,
    observation_type      STRING,  -- vital / lab / imaging
    code                  STRING,  -- LOINC
    code_text             STRING,
    value                 NUMERIC,
    unit                  STRING,
    observation_timestamp TIMESTAMP,
    abnormal_flag         STRING,  -- normal / high / low / critical
    _loaded_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------
-- raw_conditions — FHIR Condition
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `PROJECT_ID.raw.raw_conditions` (
    condition_id        STRING   NOT NULL,
    patient_id          STRING,
    encounter_id        STRING,
    code                STRING,  -- ICD-10
    code_text           STRING,
    onset_date          DATE,
    abated_date         DATE,
    clinical_status     STRING,  -- active / resolved / inactive
    verification_status STRING,  -- confirmed / provisional / differential
    _loaded_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------
-- raw_medications — FHIR MedicationRequest
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `PROJECT_ID.raw.raw_medications` (
    medication_request_id STRING  NOT NULL,
    patient_id            STRING,
    encounter_id          STRING,
    rxnorm_code           STRING, -- RxNorm
    medication_name       STRING,
    dosage_text           STRING,
    route                 STRING, -- oral / iv / topical / etc.
    prescribed_at         TIMESTAMP,
    days_supply           INT64,
    refills_allowed       INT64,
    _loaded_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------
-- raw_procedures — FHIR Procedure
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `PROJECT_ID.raw.raw_procedures` (
    procedure_id       STRING   NOT NULL,
    patient_id         STRING,
    encounter_id       STRING,
    cpt_code           STRING,  -- CPT or HCPCS
    procedure_text     STRING,
    performed_at       TIMESTAMP,
    performer_provider STRING,
    _loaded_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);
