
with  __dbt__cte__int_session_engagement as (


with v as (select * from `streaming-media-498412`.`dbt_dev_staging`.`stg_view_events`),
     s as (select * from `streaming-media-498412`.`dbt_dev_staging`.`stg_sessions`)

select
    s.session_id,
    s.user_id,
    s.session_start,
    s.session_end,
    s.session_duration_sec,
    s.device_type,
    s.country_code,
    count(distinct v.title_id)                                 as titles_watched,
    count(*)                                                    as total_events,
    sum(case when v.event_type = 'play'     then 1 else 0 end) as plays,
    sum(case when v.event_type = 'complete' then 1 else 0 end) as completes,
    sum(case when v.event_type = 'abandon'  then 1 else 0 end) as abandons,
    sum(case when v.event_type = 'skip'     then 1 else 0 end) as skips,
    sum(v.buffering_seconds)                                    as total_buffering_sec
from s
left join v on s.session_id = v.session_id
group by 1, 2, 3, 4, 5, 6, 7
), src as (
    select * from __dbt__cte__int_session_engagement
)
select
    *,
    to_hex(md5(cast(coalesce(cast(user_id as string), '_dbt_utils_surrogate_key_null_') as string)))                   as user_sk,
    to_hex(md5(cast(coalesce(cast(DATE(session_start) as string), '_dbt_utils_surrogate_key_null_') as string)))       as date_sk,
    CURRENT_TIMESTAMP()                                                    as _dbt_inserted_at
from src