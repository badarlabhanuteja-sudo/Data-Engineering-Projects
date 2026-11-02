{{ config(materialized='view') }}

select
    email_event_id              as channel_event_id,
    'email'                     as channel,
    user_id,
    campaign_id,
    CAST(NULL AS STRING)        as group_id,
    CAST(NULL AS STRING)        as creative_id,
    CAST(NULL AS STRING)        as keyword,
    CAST(NULL AS STRING)        as placement,
    event_type,
    event_timestamp,
    0.0                         as cost

from {{ source('raw', 'raw_email_events') }}
