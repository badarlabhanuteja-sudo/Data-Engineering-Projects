
    
    

with all_values as (

    select
        plan_tier as value_field,
        count(*) as n_records

    from `streaming-media-498412`.`dbt_dev_staging`.`stg_users`
    group by plan_tier

)

select *
from all_values
where value_field not in (
    'basic','standard','premium','family'
)


