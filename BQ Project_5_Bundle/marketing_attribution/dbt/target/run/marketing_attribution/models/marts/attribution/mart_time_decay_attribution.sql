
  
    

    create or replace table `marketing-attribution-498615`.`analytics`.`mart_time_decay_attribution`
      
    
    

    
    OPTIONS(
      description="""Model D \u2014 exponentially-decaying credit toward conversion"""
    )
    as (
      

-- Model D: exponentially-weighted credit, with touchpoints closer to
-- conversion receiving more weight. Half-life is configurable.

with weighted as (
    select
        conversion_id,
        channel,
        hours_to_conversion,
        revenue,
        -- exp(-h / (half_life * 24))  →  half_life days
        EXP(-hours_to_conversion / (7 * 24.0)) as raw_weight
    from `marketing-attribution-498615`.`raw`.`int_conversion_paths`
),

normalized as (
    select
        conversion_id,
        channel,
        revenue * raw_weight / SUM(raw_weight) OVER (PARTITION BY conversion_id) as channel_revenue
    from weighted
)

select
    'time_decay'                                   as model,
    channel,
    COUNT(DISTINCT conversion_id)                  as attributed_conversions,
    SUM(channel_revenue)                           as attributed_revenue,
    
    SAFE_DIVIDE(CAST(SUM(channel_revenue) AS FLOAT64), CAST((SELECT SUM(channel_revenue) FROM normalized) AS FLOAT64))
 as attributed_share
from normalized
group by channel
order by attributed_revenue desc
    );
  