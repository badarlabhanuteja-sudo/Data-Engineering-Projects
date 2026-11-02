{{ config(materialized='ephemeral') }}

with v as (select * from {{ ref('stg_view_events') }}),
     r as (select * from {{ ref('stg_ratings') }})

select
    t.title_id,
    t.title_name,
    t.content_type,
    t.primary_genre,
    t.primary_language,
    t.release_year,
    count(distinct v.user_id)                                   as unique_viewers,
    count(*)                                                    as total_view_events,
    sum(case when v.event_type = 'complete' then 1 else 0 end)  as completes,
    sum(case when v.event_type = 'abandon'  then 1 else 0 end)  as abandons,
    {{ safe_divide('sum(case when v.event_type = \'complete\' then 1 else 0 end)',
                   'NULLIF(sum(case when v.event_type = \'play\' then 1 else 0 end), 0)') }} as completion_rate,
    avg(r.rating)                                               as avg_rating,
    count(distinct r.rating_id)                                 as ratings_count
from {{ ref('stg_titles') }} t
left join v on t.title_id = v.title_id
left join r on t.title_id = r.title_id
group by 1, 2, 3, 4, 5, 6
