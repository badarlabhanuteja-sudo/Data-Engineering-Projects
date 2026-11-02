



select
    *
from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`mart_rfm_segments`

where not(r_score between 1 and 5)

