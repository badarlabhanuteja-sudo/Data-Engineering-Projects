
    
    

with child as (
    select driver_id as from_field
    from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_trips`
    where driver_id is not null
),

parent as (
    select driver_id as to_field
    from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_drivers`
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


