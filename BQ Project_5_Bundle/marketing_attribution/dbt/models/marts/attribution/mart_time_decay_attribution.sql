{{ config(materialized='table', tags=['attribution','time_decay']) }}

-- Model D: exponentially-weighted credit, with touchpoints closer to
-- conversion receiving more weight. Half-life is configurable.

with weighted as (
    select
        conversion_id,
        channel,
        hours_to_conversion,
        revenue,
        -- exp(-h / (half_life * 24))  →  half_life days
        EXP(-hours_to_conversion / ({{ var('time_decay_half_life_days') }} * 24.0)) as raw_weight
    from {{ ref('int_conversion_paths') }}
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
    {{ safe_divide('SUM(channel_revenue)',
        '(SELECT SUM(channel_revenue) FROM normalized)') }} as attributed_share
from normalized
group by channel
order by attributed_revenue desc
