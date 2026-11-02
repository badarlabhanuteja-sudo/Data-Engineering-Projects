{{ config(materialized='table') }}
with weekly as (
    select
        DATE_TRUNC(request_timestamp, WEEK)                         as week_start,
        count(*)                                                    as total_trips,
        count(distinct rider_id)                                    as unique_riders,
        count(distinct driver_id)                                   as unique_drivers,
        sum(case when is_completed then 1 else 0 end)               as completed_trips,
        sum(case when is_cancelled then 1 else 0 end)               as cancelled_trips,
        sum(final_fare)                                             as gross_merchandise_value,
        avg(surge_multiplier)                                       as avg_surge,
        avg(rating_by_rider)                                        as avg_rider_rating,
        avg(rating_by_driver)                                       as avg_driver_rating
    from {{ ref('stg_trips') }}
    group by 1
)
select
    week_start,
    total_trips,
    unique_riders,
    unique_drivers,
    completed_trips,
    cancelled_trips,
    {{ safe_divide('CAST(cancelled_trips AS FLOAT64)', 'total_trips') }}      as cancel_rate,
    gross_merchandise_value,
    {{ safe_divide('gross_merchandise_value', 'completed_trips') }} as avg_completed_fare,
    avg_surge,
    avg_rider_rating,
    avg_driver_rating,
    lag(gross_merchandise_value) over (order by week_start)         as gmv_prev_week,
    {{ safe_divide(
        'gross_merchandise_value - lag(gross_merchandise_value) over (order by week_start)',
        'lag(gross_merchandise_value) over (order by week_start)') }} as gmv_wow_growth
from weekly
order by week_start

