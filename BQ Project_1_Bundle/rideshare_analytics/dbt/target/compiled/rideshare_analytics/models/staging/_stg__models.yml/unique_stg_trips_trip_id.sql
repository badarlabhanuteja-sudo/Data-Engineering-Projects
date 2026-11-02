
    
    

with dbt_test__target as (

  select trip_id as unique_field
  from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_trips`
  where trip_id is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


