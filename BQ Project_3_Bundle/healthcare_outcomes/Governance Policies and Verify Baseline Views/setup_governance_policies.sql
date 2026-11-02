CREATE OR REPLACE ROW ACCESS POLICY patient_row_access_policy
  ON `healthcare-outcomes.marts.dim_patient`
  GRANT TO ('user:sripedasanaganti23@gmail.com')
  FILTER USING (TRUE);

CREATE OR REPLACE ROW ACCESS POLICY patient_analyst_row_access_policy
  ON `healthcare-outcomes.marts.dim_patient`
  GRANT TO ('user:sripedasanaganti23@gmail.com')
  FILTER USING (
    NOT is_deceased
    OR DATE_DIFF(CURRENT_DATE(), deceased_date, YEAR) <= 5
  );
