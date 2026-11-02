{{ config(materialized='table') }}

-- =====================================================================
-- For each conversion, produce the ordered touchpoint path that preceded
-- it within the attribution window (default 30 days).
-- This is the core input for all 5 attribution models.
-- =====================================================================

with conversions as (
    select * from {{ ref('stg_conversions') }}
),

touchpoints as (
    select * from {{ ref('int_unified_touchpoints') }}
),

-- Join conversions to all preceding touchpoints from the same user within the window
joined as (
    select
        c.conversion_id,
        c.user_id,
        c.conversion_timestamp,
        c.revenue,
        t.channel_event_id,
        t.channel,
        t.event_timestamp,
        t.campaign_id,
        TIMESTAMP_DIFF(c.conversion_timestamp, t.event_timestamp, HOUR) as hours_to_conversion
    from conversions c
    inner join touchpoints t
       on c.user_id = t.user_id
      and t.event_timestamp <= c.conversion_timestamp
      and t.event_timestamp >= TIMESTAMP_SUB(c.conversion_timestamp, INTERVAL {{ var('attribution_window_days') }} DAY)
),

with_position as (
    select
        *,
        ROW_NUMBER() OVER (PARTITION BY conversion_id ORDER BY event_timestamp ASC)  as touch_position,
        COUNT(*)     OVER (PARTITION BY conversion_id)                               as path_length,
        ROW_NUMBER() OVER (PARTITION BY conversion_id ORDER BY event_timestamp DESC) as touch_position_from_end
    from joined
)

select
    conversion_id,
    user_id,
    conversion_timestamp,
    revenue,
    channel,
    channel_event_id,
    event_timestamp,
    campaign_id,
    hours_to_conversion,
    touch_position,
    path_length,
    CASE WHEN touch_position = 1             THEN true ELSE false END as is_first_touch,
    CASE WHEN touch_position_from_end = 1    THEN true ELSE false END as is_last_touch
from with_position
