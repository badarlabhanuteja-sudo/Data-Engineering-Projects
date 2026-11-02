



select
    *
from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_trips`

where not(final_fare >= 0)

