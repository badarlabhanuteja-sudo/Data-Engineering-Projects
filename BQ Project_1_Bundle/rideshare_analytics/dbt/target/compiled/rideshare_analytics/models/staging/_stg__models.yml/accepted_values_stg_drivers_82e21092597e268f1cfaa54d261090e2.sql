
    
    

with all_values as (

    select
        vehicle_type as value_field,
        count(*) as n_records

    from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_drivers`
    group by vehicle_type

)

select *
from all_values
where value_field not in (
    'auto','mini','sedan','suv','electric'
)


