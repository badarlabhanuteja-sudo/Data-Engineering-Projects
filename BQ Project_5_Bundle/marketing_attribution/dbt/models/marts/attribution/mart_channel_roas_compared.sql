{{ config(materialized='table', tags=['attribution','comparison']) }}

-- =====================================================================
-- Headline output: same revenue, five attribution views side by side,
-- plus channel cost and ROAS for each.
-- =====================================================================

with all_models as (
    select model, channel, attributed_conversions, attributed_revenue, attributed_share
      from {{ ref('mart_first_touch_attribution') }}
    union all
    select model, channel, attributed_conversions, attributed_revenue, attributed_share
      from {{ ref('mart_last_touch_attribution') }}
    union all
    select model, channel, attributed_conversions, attributed_revenue, attributed_share
      from {{ ref('mart_linear_attribution') }}
    union all
    select model, channel, attributed_conversions, attributed_revenue, attributed_share
      from {{ ref('mart_time_decay_attribution') }}
    union all
    select model, channel, attributed_conversions, attributed_revenue, attributed_share
      from {{ ref('mart_markov_attribution') }}
),

channel_spend as (
    select channel, SUM(spend_amount) as total_spend
      from {{ ref('stg_ad_spend') }}
     group by 1
)

select
    a.model,
    a.channel,
    a.attributed_conversions,
    a.attributed_revenue,
    a.attributed_share,
    COALESCE(s.total_spend, 0)                                   as total_spend,
    {{ safe_divide('a.attributed_revenue', 'NULLIF(s.total_spend, 0)') }} as roas
from all_models a
left join channel_spend s on a.channel = s.channel
order by a.model, a.attributed_revenue desc
