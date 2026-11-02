
  
    

    create or replace table `marketing-attribution-498615`.`analytics`.`mart_channel_roas_compared`
      
    
    

    
    OPTIONS(
      description="""Side-by-side comparison of all 5 models with cost and ROAS"""
    )
    as (
      

-- =====================================================================
-- Headline output: same revenue, five attribution views side by side,
-- plus channel cost and ROAS for each.
-- =====================================================================

with all_models as (
    select model, channel, attributed_conversions, attributed_revenue, attributed_share
      from `marketing-attribution-498615`.`analytics`.`mart_first_touch_attribution`
    union all
    select model, channel, attributed_conversions, attributed_revenue, attributed_share
      from `marketing-attribution-498615`.`analytics`.`mart_last_touch_attribution`
    union all
    select model, channel, attributed_conversions, attributed_revenue, attributed_share
      from `marketing-attribution-498615`.`analytics`.`mart_linear_attribution`
    union all
    select model, channel, attributed_conversions, attributed_revenue, attributed_share
      from `marketing-attribution-498615`.`analytics`.`mart_time_decay_attribution`
    union all
    select model, channel, attributed_conversions, attributed_revenue, attributed_share
      from `marketing-attribution-498615`.`analytics`.`mart_markov_attribution`
),

channel_spend as (
    select channel, SUM(spend_amount) as total_spend
      from `marketing-attribution-498615`.`raw`.`stg_ad_spend`
     group by 1
)

select
    a.model,
    a.channel,
    a.attributed_conversions,
    a.attributed_revenue,
    a.attributed_share,
    COALESCE(s.total_spend, 0)                                   as total_spend,
    
    SAFE_DIVIDE(CAST(a.attributed_revenue AS FLOAT64), CAST(NULLIF(s.total_spend, 0) AS FLOAT64))
 as roas
from all_models a
left join channel_spend s on a.channel = s.channel
order by a.model, a.attributed_revenue desc
    );
  