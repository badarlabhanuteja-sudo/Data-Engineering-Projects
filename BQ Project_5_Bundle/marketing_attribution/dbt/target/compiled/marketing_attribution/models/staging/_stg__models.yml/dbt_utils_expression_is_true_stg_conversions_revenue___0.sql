



select
    1
from `marketing-attribution-498615`.`raw`.`stg_conversions`

where not(revenue >= 0)

