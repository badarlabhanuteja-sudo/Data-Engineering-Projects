
  
    

    create or replace table `streaming-media-498412`.`dbt_dev_marts`.`fct_view_events`
      
    partition by event_date
    cluster by event_date

    
    OPTIONS(
      description=""""""
    )
    as (
      
with src as (
    select * from `streaming-media-498412`.`dbt_dev_staging`.`stg_view_events`
),
dim_u as (
    select user_sk, user_business_key, valid_from, valid_to
    from `streaming-media-498412`.`dbt_dev_marts`.`dim_user_scd2`
)
select
    s.view_event_id,
    s.session_id,
    u.user_sk,
    s.user_id                                                  as user_business_key,
    to_hex(md5(cast(coalesce(cast(s.title_id as string), '_dbt_utils_surrogate_key_null_') as string)))     as title_sk,
    s.title_id                                                 as title_business_key,
    to_hex(md5(cast(coalesce(cast(s.event_date as string), '_dbt_utils_surrogate_key_null_') as string)))   as date_sk,
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
    );
  