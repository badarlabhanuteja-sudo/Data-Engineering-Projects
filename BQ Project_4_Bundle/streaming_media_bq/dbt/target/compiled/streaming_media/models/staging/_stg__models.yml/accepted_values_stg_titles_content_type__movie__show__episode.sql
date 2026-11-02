
    
    

with all_values as (

    select
        content_type as value_field,
        count(*) as n_records

    from `streaming-media-498412`.`dbt_dev_staging`.`stg_titles`
    group by content_type

)

select *
from all_values
where value_field not in (
    'movie','show','episode'
)


