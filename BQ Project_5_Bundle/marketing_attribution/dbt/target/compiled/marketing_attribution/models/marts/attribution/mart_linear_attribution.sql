

-- Model C: revenue distributed equally across all touchpoints in the path.

with path_credits as (
    select
        conversion_id,
        channel,
        -- Each touchpoint receives revenue / path_length
        SUM(revenue / NULLIF(path_length, 0)) as channel_revenue
    from `marketing-attribution-498615`.`raw`.`int_conversion_paths`
    group by conversion_id, channel
)

select
    'linear'                                       as model,
    channel,
    COUNT(DISTINCT conversion_id)                  as attributed_conversions,
    SUM(channel_revenue)                           as attributed_revenue,
    
    SAFE_DIVIDE(CAST(SUM(channel_revenue) AS FLOAT64), CAST((SELECT SUM(channel_revenue) FROM path_credits) AS FLOAT64))
 as attributed_share
from path_credits
group by channel
order by attributed_revenue desc