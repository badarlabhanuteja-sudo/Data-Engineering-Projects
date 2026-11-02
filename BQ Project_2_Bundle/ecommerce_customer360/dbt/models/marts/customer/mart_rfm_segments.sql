{{ config(
    materialized='table',
    tags=['baseline', 'rfm', 'experiment_baseline']
) }}

-- =====================================================================
-- BASELINE classifier for the empirical study.
-- Hughes (1996) quintile-binned RFM segmentation.
-- =====================================================================

with c360 as (
    select * from {{ ref('mart_customer_360') }}
    where total_orders > 0                       -- exclude never-purchasers
),

scored as (
    select
        customer_id,
        customer_sk,
        gross_revenue,
        total_orders,
        days_since_last_order,
        is_churned,

        {{ rfm_quintile('days_since_last_order', ascending=false) }} as r_score,
        {{ rfm_quintile('total_orders',          ascending=true)  }} as f_score,
        {{ rfm_quintile('gross_revenue',         ascending=true)  }} as m_score
    from c360
)

select
    customer_id,
    customer_sk,
    r_score,
    f_score,
    m_score,
    (r_score * 100) + (f_score * 10) + m_score          as rfm_score_combined,
    {{ rfm_segment_label('r_score', 'f_score', 'm_score') }} as rfm_segment,

    -- BASELINE churn prediction: classed as "at risk" if R is in bottom 2 quintiles
    case when r_score <= 2 then true else false end     as predicted_churn_baseline,
    -- A simple risk score: inverse of recency quintile
    (6 - r_score) / 5.0                                 as predicted_churn_score_baseline,

    is_churned                                          as actual_churn,
    gross_revenue,
    total_orders,
    days_since_last_order,
    CURRENT_TIMESTAMP()                                 as _dbt_inserted_at
from scored

