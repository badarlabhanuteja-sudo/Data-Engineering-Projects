
    
    

with all_values as (

    select
        order_status as value_field,
        count(*) as n_records

    from `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_orders`
    group by order_status

)

select *
from all_values
where value_field not in (
    'delivered','cancelled','returned'
)


