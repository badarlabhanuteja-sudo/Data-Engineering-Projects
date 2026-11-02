
  
    

    create or replace table `streaming-media-498412`.`dbt_dev_marts`.`mart_user_engagement`
      
    
    

    
    OPTIONS(
      description=""""""
    )
    as (
      

with  __dbt__cte__int_user_engagement as (


with v as (select * from `streaming-media-498412`.`dbt_dev_staging`.`stg_view_events`),
     s as (select * from `streaming-media-498412`.`dbt_dev_staging`.`stg_sessions`),
     r as (select * from `streaming-media-498412`.`dbt_dev_staging`.`stg_ratings`)

select
    u.user_id                                                   as user_id,
    count(distinct s.session_id)                                as total_sessions,
    sum(s.session_duration_sec) / 60.0                          as total_watch_minutes,
    count(distinct v.title_id)                                  as unique_titles_watched,
    sum(case when v.event_type = 'complete' then 1 else 0 end)  as titles_completed,
    sum(case when v.event_type = 'abandon'  then 1 else 0 end)  as titles_abandoned,
    
    CASE WHEN NULLIF(sum(case when v.event_type = 'play' then 1 else 0 end), 0) = 0 OR NULLIF(sum(case when v.event_type = 'play' then 1 else 0 end), 0) IS NULL
         THEN NULL
         ELSE SAFE_DIVIDE(CAST(sum(case when v.event_type = 'complete' then 1 else 0 end) AS FLOAT64), CAST(NULLIF(sum(case when v.event_type = 'play' then 1 else 0 end), 0) AS FLOAT64))
    END
 as completion_rate,
    count(distinct r.rating_id)                                 as ratings_given,
    avg(r.rating)                                               as avg_rating_given,
    max(s.session_start)                                        as last_session_at,
    -- BigQuery: DATE_DIFF on DATE values
    DATE_DIFF(
        CAST('2025-12-31' AS DATE),
        DATE(max(s.session_start)),
        DAY
    )                                                           as days_since_last_session
from `streaming-media-498412`.`dbt_dev_staging`.`stg_users` u
left join s on u.user_id = s.user_id
left join v on u.user_id = v.user_id
left join r on u.user_id = r.user_id
group by u.user_id
), u as (select * from `streaming-media-498412`.`dbt_dev_staging`.`stg_users`),
     e as (select * from __dbt__cte__int_user_engagement)

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
    );
  