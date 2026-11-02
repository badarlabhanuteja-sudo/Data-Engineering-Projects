{{ config(materialized='view') }}
select
    view_event_id,
    session_id,
    user_id,
    title_id,
    lower(event_type)                                     as event_type,
    event_timestamp,
    DATE(event_timestamp)                                 as event_date,
    playback_position_sec,
    quality_level,
    coalesce(buffering_seconds, 0)                        as buffering_seconds,
    payload.device                                        as device,
    payload.network                                       as network,
    payload                                               as payload_json,
    case when event_type = 'complete'  then true else false end as is_complete,
    case when event_type = 'abandon'   then true else false end as is_abandon,
    event_timestamp                                       as _loaded_at
from {{ source('raw', 'raw_view_events') }}
