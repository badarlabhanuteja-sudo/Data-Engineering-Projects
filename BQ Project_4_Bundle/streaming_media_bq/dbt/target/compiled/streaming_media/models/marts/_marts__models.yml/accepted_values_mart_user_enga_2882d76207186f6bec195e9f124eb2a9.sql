
    
    

with all_values as (

    select
        activity_band as value_field,
        count(*) as n_records

    from `streaming-media-498412`.`dbt_dev_marts`.`mart_user_engagement`
    group by activity_band

)

select *
from all_values
where value_field not in (
    'never_active','weekly_active','monthly_active','lapsed','churned'
)


