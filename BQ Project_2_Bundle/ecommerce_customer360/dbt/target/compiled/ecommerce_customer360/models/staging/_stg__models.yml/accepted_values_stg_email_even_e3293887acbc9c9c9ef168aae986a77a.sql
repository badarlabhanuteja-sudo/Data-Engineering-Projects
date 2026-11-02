
    
    

with all_values as (

    select
        event_type as value_field,
        count(*) as n_records

    from `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_email_events`
    group by event_type

)

select *
from all_values
where value_field not in (
    'sent','open','click','unsubscribe'
)


