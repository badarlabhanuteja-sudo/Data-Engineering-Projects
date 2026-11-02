

with  __dbt__cte__int_rider_lifetime as (


with completed as (
    select * from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_trips` where is_completed
)

select
    rider_id,
    count(*)                                                       as total_trips,
    sum(final_fare)                                                as gross_spend_inr,
    sum(distance_km)                                               as total_km,
    avg(final_fare)                                                as avg_trip_fare,
    avg(distance_km)                                               as avg_distance_km,
    avg(rating_by_rider)                                           as avg_rider_rating_given,
    min(request_timestamp)                                         as first_trip_at,
    max(request_timestamp)                                         as last_trip_at,
    DATE_DIFF(DATE(max(request_timestamp)), DATE(min(request_timestamp)), DAY) as tenure_days,
    DATE_DIFF(DATE('2025-12-31'), DATE(max(request_timestamp)), DAY) as days_since_last_trip
from completed
group by 1
), rider_lt as (select * from __dbt__cte__int_rider_lifetime),
     riders   as (select * from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_riders`),
     cities   as (select * from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_cities`)

select
    r.rider_id,
    r.first_name,
    r.last_name,
    r.email,
    r.rider_tier,
    c.city_name                                                       as home_city,
    coalesce(rl.total_trips, 0)                                       as total_trips,
    coalesce(rl.gross_spend_inr, 0)                                   as gross_spend_inr,
    rl.last_trip_at,
    rl.days_since_last_trip,
    case
        when rl.days_since_last_trip is null      then 'never_rode'
        when rl.days_since_last_trip <= 7         then 'active'
        when rl.days_since_last_trip <= 30        then 'recent'
        when rl.days_since_last_trip <= 60        then 'lapsing'
        else 'churned'
    end                                                                as activity_band,
    case
        when rl.days_since_last_trip > 30 then true
        else false
    end                                                                as is_30day_churned
from riders r
left join rider_lt rl on r.rider_id = rl.rider_id
left join cities c    on r.home_city_id = c.city_id