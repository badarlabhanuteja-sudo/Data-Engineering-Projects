

  create or replace view `marketing-attribution-498615`.`raw`.`stg_web_events`
  OPTIONS(
      description=""""""
    )
  as 

select
    event_id                    as channel_event_id,
    'web'                       as channel,
    user_id,
    utm_campaign                as campaign_id,
    CAST(NULL AS STRING)        as group_id,
    CAST(NULL AS STRING)        as creative_id,
    CAST(NULL AS STRING)        as keyword,
    CAST(NULL AS STRING)        as placement,
    event_type,
    event_timestamp,
    0.0                         as cost,
    -- web-specific extras
    session_id,
    page_url,
    referrer,
    utm_source,
    utm_medium,
    payload

from `marketing-attribution-498615`.`raw`.`raw_web_events`;

