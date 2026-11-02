SELECT first_name, last_name, mrn, date_of_birth, phone_number, email
FROM `healthcare-outcomes.baseline.vw_patient_deidentified`
LIMIT 3;


SELECT first_name, last_name, mrn, date_of_birth_year_only, phone_number
FROM `healthcare-outcomes.baseline.vw_patient_clinician`
LIMIT 3;

SELECT first_name, last_name, mrn, date_of_birth, phone_number, email
FROM `healthcare-outcomes.raw.raw_patients`
LIMIT 3;
