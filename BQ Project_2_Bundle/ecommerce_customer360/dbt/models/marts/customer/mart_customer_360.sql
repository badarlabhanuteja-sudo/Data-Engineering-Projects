{{ config(materialized='table', cluster_by=['country_code', 'customer_tier']) }}
with cust as (
    select * from {{ ref('dim_customer_scd2') }}
    where is_current
),
orders as (select * from {{ ref('int_customer_orders_history') }}),
sessions_agg as (
    select
        customer_business_key                          as customer_id,
        count(*)                                       as total_sessions,
        sum(page_views)                                as total_page_views,
        sum(product_views)                             as total_product_views,
        sum(cart_adds)                                 as total_cart_adds,
        sum(checkouts_started)                         as total_checkouts_started,
        sum(purchases_completed)                       as total_purchases_completed,
        max(session_start)                             as last_session_at
    from {{ ref('fct_web_sessions') }}
    where customer_business_key is not null
    group by 1
),
email as (select * from {{ ref('int_customer_email_engagement') }}),
returning as (select * from {{ ref('int_returning_vs_new_customer') }})
select
    c.customer_business_key                            as customer_id,
    c.customer_sk,
    c.email,
    c.first_name,
    c.last_name,
    c.gender,
    c.country_code,
    c.state,
    c.city,
    c.signup_channel,
    cast(c.is_email_subscriber as int64)               as is_email_subscriber,
    c.customer_tier,
    -- Order behaviour
    coalesce(o.total_orders, 0)                        as total_orders,
    coalesce(o.gross_revenue, 0)                       as gross_revenue,
    o.avg_order_value,
    o.first_order_date,
    o.last_order_date,
    o.customer_tenure_days,
    o.days_since_last_order,
    coalesce(cast(o.is_churned as int64), 1)                          as is_churned,
    coalesce(o.orders_with_promo, 0)                   as orders_with_promo,
    coalesce(o.total_discount_received, 0)             as total_discount_received,
    coalesce(r.repeat_orders_count, 0)                 as repeat_orders_count,
    -- Web engagement
    coalesce(s.total_sessions, 0)                      as web_sessions,
    coalesce(s.total_page_views, 0)                    as web_page_views,
    coalesce(s.total_product_views, 0)                 as web_product_views,
    coalesce(s.total_cart_adds, 0)                     as web_cart_adds,
    coalesce(s.total_checkouts_started, 0)             as web_checkouts_started,
    coalesce(s.total_purchases_completed, 0)           as web_purchases_completed,
    s.last_session_at,
    -- Email engagement
    coalesce(e.emails_sent, 0)                         as emails_sent,
    coalesce(e.emails_opened, 0)                       as emails_opened,
    coalesce(e.emails_clicked, 0)                      as emails_clicked,
    coalesce(cast(e.open_rate as float64), 0.0)        as email_open_rate,
    coalesce(cast(e.click_rate as float64), 0.0)       as email_click_rate,
    coalesce(cast(e.is_unsubscribed as int64), 0)                     as is_unsubscribed,
    CURRENT_TIMESTAMP()                                as _dbt_inserted_at
from cust c
left join orders        o on c.customer_business_key = o.customer_id
left join sessions_agg  s on c.customer_business_key = s.customer_id
left join email         e on c.customer_business_key = e.customer_id
left join returning     r on c.customer_business_key = r.customer_id


