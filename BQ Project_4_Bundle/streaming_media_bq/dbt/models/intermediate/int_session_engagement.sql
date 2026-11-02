{{ config(materialized='ephemeral') }}

with v as (select * from {{ ref('stg_view_events') }}),
     s as (select * from {{ ref('stg_sessions') }})

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
