

with  __dbt__cte__int_customer_sessions as (


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
), sessions as (
    select * from __dbt__cte__int_customer_sessions
),

cust as (
    select customer_sk, customer_business_key, valid_from, valid_to
    from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`dim_customer_scd2`
)

select
    s.session_id,
    c.customer_sk,
    s.customer_id                              as customer_business_key,
    s.session_start,
    s.session_end,
    cast(s.session_start as date)              as session_date,
    to_hex(md5(cast(coalesce(cast(cast(s.session_start as date) as string), '_dbt_utils_surrogate_key_null_') as string))) as date_sk,
    s.session_duration_sec,
    s.event_count,
    s.distinct_event_types,
    s.page_views,
    s.product_views,
    s.cart_adds,
    s.checkouts_started,
    s.purchases_completed,
    s.has_purchase,
    current_timestamp()                        as _dbt_inserted_at
from sessions s
left join cust c
       on s.customer_id  = c.customer_business_key
      and s.session_start >= c.valid_from
      and s.session_start <  c.valid_to