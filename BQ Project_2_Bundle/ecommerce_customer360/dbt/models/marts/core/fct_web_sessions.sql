{{
    config(
        materialized='incremental',
        unique_key='session_id',
        on_schema_change='append_new_columns',
        incremental_strategy='merge'
    )
}}

with sessions as (
    select * from {{ ref('int_customer_sessions') }}
),

cust as (
    select customer_sk, customer_business_key, valid_from, valid_to
    from {{ ref('dim_customer_scd2') }}
)

select
    s.session_id,
    c.customer_sk,
    s.customer_id                              as customer_business_key,
    s.session_start,
    s.session_end,
    cast(s.session_start as date)              as session_date,
    {{ dbt_utils.generate_surrogate_key(['cast(s.session_start as date)']) }} as date_sk,
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

