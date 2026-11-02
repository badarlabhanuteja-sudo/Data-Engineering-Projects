
  
    

    create or replace table `marketing-attribution-498615`.`analytics`.`mart_last_touch_attribution`
      
    
    

    
    OPTIONS(
      description="""Model B \u2014 100% credit to last touchpoint"""
    )
    as (
      

-- Model B: 100% credit to the last touchpoint in each conversion path.

with last_touches as (
    select
        conversion_id,
        user_id,
        channel,
        revenue
    from `marketing-attribution-498615`.`raw`.`int_conversion_paths`
    where is_last_touch
)

select
    'last_touch'                                   as model,
    channel,
    COUNT(DISTINCT conversion_id)                  as attributed_conversions,
    SUM(revenue)                                   as attributed_revenue,
    
    SAFE_DIVIDE(CAST(SUM(revenue) AS FLOAT64), CAST((SELECT SUM(revenue) FROM last_touches) AS FLOAT64))
 as attributed_share
from last_touches
group by channel
order by attributed_revenue desc
    );
  