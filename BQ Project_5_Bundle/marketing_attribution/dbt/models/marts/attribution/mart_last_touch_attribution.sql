{{ config(materialized='table', tags=['attribution','last_touch']) }}

-- Model B: 100% credit to the last touchpoint in each conversion path.

with last_touches as (
    select
        conversion_id,
        user_id,
        channel,
        revenue
    from {{ ref('int_conversion_paths') }}
    where is_last_touch
)

select
    'last_touch'                                   as model,
    channel,
    COUNT(DISTINCT conversion_id)                  as attributed_conversions,
    SUM(revenue)                                   as attributed_revenue,
    {{ safe_divide('SUM(revenue)',
        '(SELECT SUM(revenue) FROM last_touches)') }} as attributed_share
from last_touches
group by channel
order by attributed_revenue desc
