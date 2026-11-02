{{ config(materialized='table', tags=['attribution','linear']) }}

-- Model C: revenue distributed equally across all touchpoints in the path.

with path_credits as (
    select
        conversion_id,
        channel,
        -- Each touchpoint receives revenue / path_length
        SUM(revenue / NULLIF(path_length, 0)) as channel_revenue
    from {{ ref('int_conversion_paths') }}
    group by conversion_id, channel
)

select
    'linear'                                       as model,
    channel,
    COUNT(DISTINCT conversion_id)                  as attributed_conversions,
    SUM(channel_revenue)                           as attributed_revenue,
    {{ safe_divide('SUM(channel_revenue)',
        '(SELECT SUM(channel_revenue) FROM path_credits)') }} as attributed_share
from path_credits
group by channel
order by attributed_revenue desc
