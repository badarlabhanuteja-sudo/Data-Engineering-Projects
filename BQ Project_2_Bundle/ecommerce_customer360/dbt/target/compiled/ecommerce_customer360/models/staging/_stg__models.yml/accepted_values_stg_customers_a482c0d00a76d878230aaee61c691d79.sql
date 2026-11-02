
    
    

with all_values as (

    select
        customer_tier as value_field,
        count(*) as n_records

    from `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_customers`
    group by customer_tier

)

select *
from all_values
where value_field not in (
    'bronze','silver','gold','platinum'
)


