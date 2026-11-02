{{ config(materialized='table') }}

select
    t.city_id,
    c.city_name,
    count(*)                                                 as completed_trips,
    avg(t.wait_seconds)                                       as avg_wait_seconds,
    avg(t.wait_seconds)                                       as median_wait_seconds,
    avg(t.duration_min)                                       as avg_duration_min,
    avg(t.duration_min)                                       as median_duration_min,
    avg(t.distance_km)                                        as avg_distance_km,
    SAFE_DIVIDE(CAST(sum(case when t.wait_seconds <= 180 then 1 else 0 end) AS FLOAT64), CAST(count(*) AS FLOAT64)) as pct_pickup_under_3min,
    SAFE_DIVIDE(CAST(sum(case when t.wait_seconds <= 300 then 1 else 0 end) AS FLOAT64), CAST(count(*) AS FLOAT64)) as pct_pickup_under_5min
from {{ ref('fct_trips') }} t
join {{ ref('dim_city') }} c on t.city_id = c.city_business_key
where t.is_completed
group by 1, 2
order by completed_trips desc
