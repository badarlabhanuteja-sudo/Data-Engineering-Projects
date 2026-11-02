



select
    *
from `streaming-media-498412`.`dbt_dev_staging`.`stg_ratings`

where not(rating between 0.5 and 5.0)

