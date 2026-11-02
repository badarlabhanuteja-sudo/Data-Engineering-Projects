{{ config(materialized='table') }}

with c as (select * from {{ ref('int_content_popularity') }})

select
    title_id,
    title_name,
    content_type,
    primary_genre,
    primary_language,
    release_year,
    coalesce(unique_viewers,    0) as unique_viewers,
    coalesce(total_view_events, 0) as total_view_events,
    coalesce(completes,         0) as completes,
    coalesce(abandons,          0) as abandons,
    coalesce(completion_rate,   0) as completion_rate,
    avg_rating,
    coalesce(ratings_count,     0) as ratings_count,
    -- Bayesian-adjusted rating: shrink toward global mean for low-count titles
    case
        when ratings_count is null or ratings_count = 0 then null
        else (coalesce(ratings_count, 0) * coalesce(avg_rating, 0)
              + 100 * 3.5)           -- prior: 100 ratings of 3.5
             / (coalesce(ratings_count, 0) + 100)
    end                             as bayesian_rating,
    case
        when unique_viewers >= 5000 then 'hit'
        when unique_viewers >= 1000 then 'popular'
        when unique_viewers >=  100 then 'modest'
        else 'niche'
    end                             as performance_band
from c
order by unique_viewers desc nulls last
