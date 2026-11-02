
  
    

    create or replace table `marketing-attribution-498615`.`analytics`.`mart_first_touch_attribution`
      
    
    

    
    OPTIONS(
      description="""Model A \u2014 100% credit to first touchpoint"""
    )
    as (
      

-- Model A: 100% credit to the first touchpoint in each conversion path.

with first_touches as (
    select
        conversion_id,
        user_id,
        channel,
        revenue
    from `marketing-attribution-498615`.`raw`.`int_conversion_paths`
    where is_first_touch
)

select
    'first_touch'                                  as model,
    channel,
    COUNT(DISTINCT conversion_id)                  as attributed_conversions,
    SUM(revenue)                                   as attributed_revenue,
    
    SAFE_DIVIDE(CAST(SUM(revenue) AS FLOAT64), CAST((SELECT SUM(revenue) FROM first_touches) AS FLOAT64))
 as attributed_share
from first_touches
group by channel
order by attributed_revenue desc
    );
  