



select
    *
from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`mart_churn_prediction`

where not(predicted_churn_score_ml between 0 and 1)

