

with events as (
    select * from `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_web_events`
    where customer_id is not null
),
sessions as (
    select
        customer_id,
        session_id,
        min(cast(event_timestamp as timestamp))                                 as session_start,
        max(cast(event_timestamp as timestamp))                                 as session_end,
        timestamp_diff(
            max(cast(event_timestamp as timestamp)),
            min(cast(event_timestamp as timestamp)),
            second)                                                             as session_duration_sec,
        count(*)                                                                as event_count,
        count(distinct event_type)                                              as distinct_event_types,
        sum(case when event_type = 'page_view'         then 1 else 0 end)      as page_views,
        sum(case when event_type = 'product_view'      then 1 else 0 end)      as product_views,
        sum(case when event_type = 'add_to_cart'       then 1 else 0 end)      as cart_adds,
        sum(case when event_type = 'begin_checkout'    then 1 else 0 end)      as checkouts_started,
        sum(case when event_type = 'complete_purchase' then 1 else 0 end)      as purchases_completed,
        max(case when event_type = 'complete_purchase' then 1 else 0 end)      as has_purchase
    from events
    group by 1, 2
)
select * from sessions