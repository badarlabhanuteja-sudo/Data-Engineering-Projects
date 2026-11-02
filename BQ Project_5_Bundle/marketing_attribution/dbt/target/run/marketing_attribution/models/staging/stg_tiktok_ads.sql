

  create or replace view `marketing-attribution-498615`.`raw`.`stg_tiktok_ads`
  OPTIONS(
      description=""""""
    )
  as 

select
    tiktok_event_id             as channel_event_id,
    'tiktok_ads'                as channel,
    user_id,
    campaign_id,
    ad_group_id                 as group_id,
    creative_id,
    CAST(NULL AS STRING)        as keyword,
    CAST(NULL AS STRING)        as placement,
    event_type,
    event_timestamp,
    cost

from `marketing-attribution-498615`.`raw`.`raw_tiktok_ads`;

