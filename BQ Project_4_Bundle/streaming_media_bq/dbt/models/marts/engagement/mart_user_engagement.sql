{{ config(materialized='table') }}

with u as (select * from {{ ref('stg_users') }}),
     e as (select * from {{ ref('int_user_engagement') }})

select
    u.user_id,
    u.email,
    u.country_code,
    u.plan_tier,
    u.tenure_days,
    coalesce(e.total_sessions,          0) as total_sessions,
    coalesce(e.total_watch_minutes,     0) as total_watch_minutes,
    coalesce(e.unique_titles_watched,   0) as unique_titles_watched,
    coalesce(e.titles_completed,        0) as titles_completed,
    coalesce(e.titles_abandoned,        0) as titles_abandoned,
    coalesce(e.completion_rate,         0) as completion_rate,
    coalesce(e.ratings_given,           0) as ratings_given,
    e.avg_rating_given,
    e.last_session_at,
    coalesce(e.days_since_last_session, 9999) as days_since_last_session,
    case
        when e.days_since_last_session is null then 'never_active'
        when e.days_since_last_session <=   7  then 'weekly_active'
        when e.days_since_last_session <=  30  then 'monthly_active'
        when e.days_since_last_session <=  90  then 'lapsed'
        else 'churned'
    end                                    as activity_band
from u
left join e on u.user_id = e.user_id
