{{
    config(
        materialized='table',
        partition_by={
            "field": "event_date",
            "data_type": "date",
            "granularity": "day"
        },
        cluster_by=['event_date']
    )
}}
with src as (
    select * from {{ ref('stg_view_events') }}
),
dim_u as (
    select user_sk, user_business_key, valid_from, valid_to
    from {{ ref('dim_user_scd2') }}
)
select
    s.view_event_id,
    s.session_id,
    u.user_sk,
    s.user_id                                                  as user_business_key,
    {{ dbt_utils.generate_surrogate_key(['s.title_id']) }}     as title_sk,
    s.title_id                                                 as title_business_key,
    {{ dbt_utils.generate_surrogate_key(['s.event_date']) }}   as date_sk,
    s.event_type,
    s.event_timestamp,
    s.event_date,
    s.playback_position_sec,
    s.quality_level,
    s.buffering_seconds,
    s.device,
    s.network,
    s.is_complete,
    s.is_abandon,
    s._loaded_at,
    CURRENT_TIMESTAMP()                                        as _dbt_inserted_at
from src s
left join dim_u u
       on s.user_id        = u.user_business_key
      and s.event_timestamp >= CAST(u.valid_from AS TIMESTAMP)
      and s.event_timestamp <  CAST(u.valid_to   AS TIMESTAMP)
