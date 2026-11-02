

with  __dbt__cte__int_content_popularity as (


with v as (select * from `streaming-media-498412`.`dbt_dev_staging`.`stg_view_events`),
     r as (select * from `streaming-media-498412`.`dbt_dev_staging`.`stg_ratings`)

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
    
    CASE WHEN NULLIF(sum(case when v.event_type = 'play' then 1 else 0 end), 0) = 0 OR NULLIF(sum(case when v.event_type = 'play' then 1 else 0 end), 0) IS NULL
         THEN NULL
         ELSE SAFE_DIVIDE(CAST(sum(case when v.event_type = 'complete' then 1 else 0 end) AS FLOAT64), CAST(NULLIF(sum(case when v.event_type = 'play' then 1 else 0 end), 0) AS FLOAT64))
    END
 as completion_rate,
    avg(r.rating)                                               as avg_rating,
    count(distinct r.rating_id)                                 as ratings_count
from `streaming-media-498412`.`dbt_dev_staging`.`stg_titles` t
left join v on t.title_id = v.title_id
left join r on t.title_id = r.title_id
group by 1, 2, 3, 4, 5, 6
), c as (select * from __dbt__cte__int_content_popularity)

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