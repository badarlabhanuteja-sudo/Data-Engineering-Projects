{{ config(materialized='ephemeral') }}

with orders as (
    select * from {{ ref('stg_orders') }}
    where is_completed                   -- exclude cancellations / returns
),

per_customer as (
    select
        customer_id,
        count(distinct order_id)                                        as total_orders,
        count(distinct date_trunc(order_date, month))                   as active_months,
        sum(gross_merchandise_value)                                    as gross_revenue,
        sum(total_amount)                                               as total_revenue_inc_tax,
        avg(gross_merchandise_value)                                    as avg_order_value,
        min(order_date)                                                 as first_order_date,
        max(order_date)                                                 as last_order_date,
        date_diff(
            max(order_date),
            min(order_date),
            day)                                                        as customer_tenure_days,
        sum(case when promo_code is not null then 1 else 0 end)         as orders_with_promo,
        count(distinct promo_code)                                      as unique_promos_used,
        sum(discount_amount)                                            as total_discount_received
    from orders
    group by 1
),

recency as (
    select
        customer_id,
        date_diff(
            date('{{ var("analysis_as_of_date") }}'),
            last_order_date,
            day)                                                        as days_since_last_order
    from per_customer
)

select
    p.*,
    r.days_since_last_order,
    case
        when r.days_since_last_order > {{ var('churn_window_days') }} then true
        else false
    end as is_churned
from per_customer p
join recency r using (customer_id)
