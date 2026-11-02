
    
    

with all_values as (

    select
        trip_status as value_field,
        count(*) as n_records

    from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_trips`
    group by trip_status

)

select *
from all_values
where value_field not in (
    'requested','accepted','cancelled','completed'
)


