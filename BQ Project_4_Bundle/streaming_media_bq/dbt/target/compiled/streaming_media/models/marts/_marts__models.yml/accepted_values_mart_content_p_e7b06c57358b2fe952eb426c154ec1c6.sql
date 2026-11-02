
    
    

with all_values as (

    select
        performance_band as value_field,
        count(*) as n_records

    from `streaming-media-498412`.`dbt_dev_marts`.`mart_content_performance`
    group by performance_band

)

select *
from all_values
where value_field not in (
    'hit','popular','modest','niche'
)


