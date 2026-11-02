{{ config(materialized='table', tags=['attribution','first_touch']) }}

-- Model A: 100% credit to the first touchpoint in each conversion path.

with first_touches as (
    select
        conversion_id,
        user_id,
        channel,
        revenue
    from {{ ref('int_conversion_paths') }}
    where is_first_touch
)

select
    'first_touch'                                  as model,
    channel,
    COUNT(DISTINCT conversion_id)                  as attributed_conversions,
    SUM(revenue)                                   as attributed_revenue,
    {{ safe_divide('SUM(revenue)',
        '(SELECT SUM(revenue) FROM first_touches)') }} as attributed_share
from first_touches
group by channel
order by attributed_revenue desc
