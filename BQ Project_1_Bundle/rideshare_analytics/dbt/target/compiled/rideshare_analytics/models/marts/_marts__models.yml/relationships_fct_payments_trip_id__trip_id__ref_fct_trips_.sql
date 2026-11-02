
    
    

with child as (
    select trip_id as from_field
    from `project-d8d88b02-3334-4b57-b24`.`marts`.`fct_payments`
    where trip_id is not null
),

parent as (
    select trip_id as to_field
    from `project-d8d88b02-3334-4b57-b24`.`marts`.`fct_trips`
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


