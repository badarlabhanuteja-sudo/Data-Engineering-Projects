{{ config(materialized='ephemeral') }}

with v as (select * from {{ ref('stg_view_events') }}),
     s as (select * from {{ ref('stg_sessions') }}),
     r as (select * from {{ ref('stg_ratings') }})

select
    u.user_id                                                   as user_id,
    count(distinct s.session_id)                                as total_sessions,
    sum(s.session_duration_sec) / 60.0                          as total_watch_minutes,
    count(distinct v.title_id)                                  as unique_titles_watched,
    sum(case when v.event_type = 'complete' then 1 else 0 end)  as titles_completed,
    sum(case when v.event_type = 'abandon'  then 1 else 0 end)  as titles_abandoned,
    {{ safe_divide('sum(case when v.event_type = \'complete\' then 1 else 0 end)',
                   'NULLIF(sum(case when v.event_type = \'play\' then 1 else 0 end), 0)') }} as completion_rate,
    count(distinct r.rating_id)                                 as ratings_given,
    avg(r.rating)                                               as avg_rating_given,
    max(s.session_start)                                        as last_session_at,
    -- BigQuery: DATE_DIFF on DATE values
    DATE_DIFF(
        CAST('{{ var("analysis_as_of_date") }}' AS DATE),
        DATE(max(s.session_start)),
        DAY
    )                                                           as days_since_last_session
from {{ ref('stg_users') }} u
left join s on u.user_id = s.user_id
left join v on u.user_id = v.user_id
left join r on u.user_id = r.user_id
group by u.user_id
