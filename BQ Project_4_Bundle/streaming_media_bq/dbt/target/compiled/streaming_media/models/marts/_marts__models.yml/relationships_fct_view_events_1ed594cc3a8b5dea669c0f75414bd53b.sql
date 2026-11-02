
    
    

with child as (
    select user_business_key as from_field
    from `streaming-media-498412`.`dbt_dev_marts`.`fct_view_events`
    where user_business_key is not null
),

parent as (
    select user_business_key as to_field
    from `streaming-media-498412`.`dbt_dev_marts`.`dim_user_scd2`
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


