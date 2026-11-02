
  
    

    create or replace table `marketing-attribution-498615`.`raw`.`int_conversion_paths`
      
    
    

    
    OPTIONS(
      description=""""""
    )
    as (
      

-- =====================================================================
-- For each conversion, produce the ordered touchpoint path that preceded
-- it within the attribution window (default 30 days).
-- This is the core input for all 5 attribution models.
-- =====================================================================

with  __dbt__cte__int_unified_touchpoints as (


-- =====================================================================
-- Unify all 5 source channels into a single touchpoint schema.
-- This is the table that all attribution models query.
-- =====================================================================

with google as (
    select channel_event_id, channel, user_id, campaign_id, group_id, creative_id,
           keyword, placement, event_type, event_timestamp, cost
    from `marketing-attribution-498615`.`raw`.`stg_google_ads`
),
meta as (
    select channel_event_id, channel, user_id, campaign_id, group_id, creative_id,
           keyword, placement, event_type, event_timestamp, cost
    from `marketing-attribution-498615`.`raw`.`stg_meta_ads`
),
tiktok as (
    select channel_event_id, channel, user_id, campaign_id, group_id, creative_id,
           keyword, placement, event_type, event_timestamp, cost
    from `marketing-attribution-498615`.`raw`.`stg_tiktok_ads`
),
email as (
    select channel_event_id, channel, user_id, campaign_id, group_id, creative_id,
           keyword, placement, event_type, event_timestamp, cost
    from `marketing-attribution-498615`.`raw`.`stg_email_events`
),
web as (
    select channel_event_id, channel, user_id, campaign_id, group_id, creative_id,
           keyword, placement, event_type, event_timestamp, cost
    from `marketing-attribution-498615`.`raw`.`stg_web_events`
),

unioned as (
    select * from google
    union all select * from meta
    union all select * from tiktok
    union all select * from email
    union all select * from web
),

-- Filter to interaction-style events only (drop pure impressions for cleaner attribution paths)
filtered as (
    select *
    from unioned
    where event_type in ('click', 'open', 'view', 'product_view', 'add_to_cart', 'page_view')
)

select * from filtered
), conversions as (
    select * from `marketing-attribution-498615`.`raw`.`stg_conversions`
),

touchpoints as (
    select * from __dbt__cte__int_unified_touchpoints
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
      and t.event_timestamp >= TIMESTAMP_SUB(c.conversion_timestamp, INTERVAL 30 DAY)
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
    );
  