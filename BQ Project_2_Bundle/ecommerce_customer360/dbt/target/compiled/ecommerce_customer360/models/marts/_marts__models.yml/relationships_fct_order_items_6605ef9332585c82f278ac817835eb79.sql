
    
    

with child as (
    select order_id as from_field
    from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`fct_order_items`
    where order_id is not null
),

parent as (
    select order_id as to_field
    from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`fct_orders`
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


