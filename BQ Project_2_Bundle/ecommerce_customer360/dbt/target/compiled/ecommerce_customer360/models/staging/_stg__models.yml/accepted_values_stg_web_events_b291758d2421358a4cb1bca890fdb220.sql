
    
    

with all_values as (

    select
        event_type as value_field,
        count(*) as n_records

    from `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_web_events`
    group by event_type

)

select *
from all_values
where value_field not in (
    'page_view','product_view','search','add_to_cart','remove_from_cart','begin_checkout','complete_purchase','login','signup','wishlist_add'
)


