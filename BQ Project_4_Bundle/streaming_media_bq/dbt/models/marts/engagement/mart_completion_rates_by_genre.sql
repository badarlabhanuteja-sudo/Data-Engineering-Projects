{{ config(materialized='table') }}

with v as (select * from {{ ref('stg_view_events') }}),
     t as (select * from {{ ref('stg_titles') }})

select
    t.primary_genre,
    t.content_type,
    count(distinct v.user_id)                                   as unique_viewers,
    count(*)                                                    as total_events,
    sum(case when v.event_type = 'play'     then 1 else 0 end)  as plays,
    sum(case when v.event_type = 'complete' then 1 else 0 end)  as completes,
    sum(case when v.event_type = 'abandon'  then 1 else 0 end)  as abandons,
    {{ safe_divide('sum(case when v.event_type = \'complete\' then 1 else 0 end)',
                   'NULLIF(sum(case when v.event_type = \'play\' then 1 else 0 end), 0)') }} as completion_rate,
    {{ safe_divide('sum(case when v.event_type = \'abandon\'  then 1 else 0 end)',
                   'NULLIF(sum(case when v.event_type = \'play\' then 1 else 0 end), 0)') }} as abandon_rate
from t
left join v on t.title_id = v.title_id
group by 1, 2
order by 4 desc nulls last
