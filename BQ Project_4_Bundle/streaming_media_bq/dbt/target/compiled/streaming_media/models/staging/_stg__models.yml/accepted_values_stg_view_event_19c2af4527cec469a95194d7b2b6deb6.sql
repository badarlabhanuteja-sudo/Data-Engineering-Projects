
    
    

with all_values as (

    select
        event_type as value_field,
        count(*) as n_records

    from `streaming-media-498412`.`dbt_dev_staging`.`stg_view_events`
    group by event_type

)

select *
from all_values
where value_field not in (
    'play','pause','resume','complete','abandon','skip','stop'
)


