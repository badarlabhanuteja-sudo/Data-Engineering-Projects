{{ config(materialized='table') }}

with c360 as (
    select * from {{ ref('mart_customer_360') }}
    where total_orders > 0
),

with_metrics as (
    select
        customer_id,
        customer_sk,
        gross_revenue                                            as historical_clv,
        total_orders,
        avg_order_value,
        customer_tenure_days,
        case when customer_tenure_days > 0
             then CAST(total_orders AS FLOAT64) / nullif(customer_tenure_days, 0)
             else null end                                       as orders_per_day,
        -- Naive forward CLV: average order value × predicted future orders
        -- (assuming retention ∝ recency)
        case
            when days_since_last_order <= 30  then avg_order_value * 12
            when days_since_last_order <= 90  then avg_order_value * 6
            when days_since_last_order <= 180 then avg_order_value * 2
            else 0
        end                                                      as projected_12m_clv
    from c360
),

bucketed as (
    select
        *,
        ntile(4) over (order by historical_clv) as clv_quartile
    from with_metrics
)

select
    *,
    case
        when clv_quartile = 4 then 'Top'
        when clv_quartile = 3 then 'High'
        when clv_quartile = 2 then 'Mid'
        else 'Low'
    end as clv_segment
from bucketed

