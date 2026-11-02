
  
    

    create or replace table `project-d8d88b02-3334-4b57-b24`.`marts`.`mart_executive_kpi_weekly`
      
    
    

    
    OPTIONS(
      description=""""""
    )
    as (
      
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
    from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_trips`
    group by 1
)
select
    week_start,
    total_trips,
    unique_riders,
    unique_drivers,
    completed_trips,
    cancelled_trips,
    
    SAFE_DIVIDE(CAST(CAST(cancelled_trips AS FLOAT64) AS FLOAT64), CAST(total_trips AS FLOAT64))
      as cancel_rate,
    gross_merchandise_value,
    
    SAFE_DIVIDE(CAST(gross_merchandise_value AS FLOAT64), CAST(completed_trips AS FLOAT64))
 as avg_completed_fare,
    avg_surge,
    avg_rider_rating,
    avg_driver_rating,
    lag(gross_merchandise_value) over (order by week_start)         as gmv_prev_week,
    
    SAFE_DIVIDE(CAST(gross_merchandise_value - lag(gross_merchandise_value) over (order by week_start) AS FLOAT64), CAST(lag(gross_merchandise_value) over (order by week_start) AS FLOAT64))
 as gmv_wow_growth
from weekly
order by week_start
    );
  