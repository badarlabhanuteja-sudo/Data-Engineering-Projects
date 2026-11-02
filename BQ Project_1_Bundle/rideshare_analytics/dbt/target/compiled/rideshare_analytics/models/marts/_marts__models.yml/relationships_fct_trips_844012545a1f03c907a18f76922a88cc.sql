
    
    

with child as (
    select driver_business_key as from_field
    from `project-d8d88b02-3334-4b57-b24`.`marts`.`fct_trips`
    where driver_business_key is not null
),

parent as (
    select driver_business_key as to_field
    from `project-d8d88b02-3334-4b57-b24`.`marts`.`dim_driver_scd2`
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


