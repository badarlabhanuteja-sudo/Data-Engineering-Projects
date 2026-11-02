{{ config(materialized='view') }}
select
    session_id,
    user_id,
    profile_id,
    lower(device_type)                                    as device_type,
    device_os,
    session_start,
    session_end,
    TIMESTAMP_DIFF(session_end, session_start, SECOND)    as session_duration_sec,
    network_type,
    upper(country)                                        as country_code,
    DATE(session_start)                                   as session_date,
    EXTRACT(hour FROM session_start)                      as session_hour,
    session_start                                         as _loaded_at
from {{ source('raw', 'raw_sessions') }}
