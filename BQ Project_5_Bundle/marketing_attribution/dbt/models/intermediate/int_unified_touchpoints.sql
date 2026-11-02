{{ config(materialized='ephemeral') }}

-- =====================================================================
-- Unify all 5 source channels into a single touchpoint schema.
-- This is the table that all attribution models query.
-- =====================================================================

with google as (
    select channel_event_id, channel, user_id, campaign_id, group_id, creative_id,
           keyword, placement, event_type, event_timestamp, cost
    from {{ ref('stg_google_ads') }}
),
meta as (
    select channel_event_id, channel, user_id, campaign_id, group_id, creative_id,
           keyword, placement, event_type, event_timestamp, cost
    from {{ ref('stg_meta_ads') }}
),
tiktok as (
    select channel_event_id, channel, user_id, campaign_id, group_id, creative_id,
           keyword, placement, event_type, event_timestamp, cost
    from {{ ref('stg_tiktok_ads') }}
),
email as (
    select channel_event_id, channel, user_id, campaign_id, group_id, creative_id,
           keyword, placement, event_type, event_timestamp, cost
    from {{ ref('stg_email_events') }}
),
web as (
    select channel_event_id, channel, user_id, campaign_id, group_id, creative_id,
           keyword, placement, event_type, event_timestamp, cost
    from {{ ref('stg_web_events') }}
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
