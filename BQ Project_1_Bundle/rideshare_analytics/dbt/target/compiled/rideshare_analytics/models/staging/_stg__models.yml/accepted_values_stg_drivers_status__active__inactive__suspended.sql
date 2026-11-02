
    
    

with all_values as (

    select
        status as value_field,
        count(*) as n_records

    from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_drivers`
    group by status

)

select *
from all_values
where value_field not in (
    'active','inactive','suspended'
)


