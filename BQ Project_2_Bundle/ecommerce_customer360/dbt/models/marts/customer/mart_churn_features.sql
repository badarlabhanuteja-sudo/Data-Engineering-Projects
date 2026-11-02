{{ config(
    materialized='table',
    tags=['features', 'ml']
) }}

-- =====================================================================
-- Feature store for the INTERVENTION ML churn classifier.
-- One row per customer with engineered features.
-- =====================================================================

with c360 as (
    select * from {{ ref('mart_customer_360') }}
    where total_orders > 0                  -- align population with baseline
),

with_derived as (
    select
        customer_id,
        customer_sk,
        is_churned                                                   as label,

        -- Demographic / signup
        case when customer_tier = 'platinum' then 4
             when customer_tier = 'gold'     then 3
             when customer_tier = 'silver'   then 2
             else 1                                          end     as tier_ordinal,
        case when is_email_subscriber = 1 then 1 else 0 end              as is_email_subscriber_int,
        case when country_code = 'IN' then 1 else 0 end              as is_country_in,
        case when signup_channel in ('google_ads', 'meta_ads', 'tiktok') then 1 else 0 end as is_paid_acquisition,

        -- Order behaviour
        total_orders,
        gross_revenue,
        avg_order_value,
        customer_tenure_days,
        days_since_last_order,
        coalesce(orders_with_promo, 0)                               as orders_with_promo,
        coalesce(total_discount_received, 0)                         as total_discount_received,
        {{ safe_divide('coalesce(orders_with_promo, 0)', 'nullif(total_orders, 0)') }} as promo_fraction,
        coalesce(repeat_orders_count, 0)                             as repeat_orders_count,
        {{ safe_divide('coalesce(repeat_orders_count, 0)', 'nullif(total_orders, 0)') }} as repeat_fraction,

        -- Web engagement
        web_sessions,
        web_page_views,
        web_product_views,
        web_cart_adds,
        web_checkouts_started,
        web_purchases_completed,
        {{ safe_divide('web_cart_adds', 'nullif(web_product_views, 0)') }} as cart_to_view_ratio,
        {{ safe_divide('web_purchases_completed', 'nullif(web_checkouts_started, 0)') }} as checkout_completion_rate,

        -- Email engagement
        emails_sent,
        emails_opened,
        emails_clicked,
        email_open_rate,
        email_click_rate,
        case when is_unsubscribed = 1 then 1 else 0 end                  as is_unsubscribed_int

    from c360
)

select * from with_derived




