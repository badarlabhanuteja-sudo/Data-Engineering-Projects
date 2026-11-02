

with __dbt__cte__int_trip_enriched as (


with t as (select * from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_trips`),
     d as (select * from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_drivers`),
     r as (select * from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_riders`),
     c as (select * from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_cities`),
     p as (
        select trip_id,
               sum(case when payment_status = 'success'  then amount else 0 end) as paid_amount,
               max(case when payment_status = 'success'  then 1 else 0 end) as is_paid_success,
               max(case when payment_status = 'failed'   then 1 else 0 end) as is_paid_failed,
               max(case when payment_status = 'refunded' then 1 else 0 end) as is_refunded
          from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_payments`
         group by 1
     )

select
    t.trip_id,
    t.rider_id,
    t.driver_id,
    t.city_id,
    c.city_name,
    c.state                              as city_state,
    d.vehicle_type,
    d.rating                             as driver_rating,
    r.rider_tier,
    t.request_timestamp,
    t.pickup_timestamp,
    t.dropoff_timestamp,
    t.request_date,
    t.request_hour,
    t.request_dow,
    t.distance_km,
    t.duration_min,
    t.base_fare,
    t.surge_multiplier,
    
    case
        when t.surge_multiplier < 1.2 then 'normal'
        when t.surge_multiplier < 1.5 then 'mild'
        when t.surge_multiplier < 2.0 then 'elevated'
        when t.surge_multiplier < 3.0 then 'high'
        else 'extreme'
    end
 as surge_band,
    t.surge_uplift_inr,
    t.final_fare,
    t.payment_method,
    t.trip_status,
    t.is_completed,
    t.is_cancelled,
    t.wait_seconds,
    t.rating_by_rider,
    t.rating_by_driver,
    coalesce(p.paid_amount, 0)           as paid_amount,
    coalesce(p.is_paid_success, 0)       as is_paid_success,
    coalesce(p.is_paid_failed, 0)        as is_paid_failed,
    coalesce(p.is_refunded, 0)           as is_refunded,
    t._loaded_at
from t
left join d on t.driver_id = d.driver_id
left join r on t.rider_id  = r.rider_id
left join c on t.city_id   = c.city_id
left join p on t.trip_id   = p.trip_id
) select
    city_id,
    city_name,
    date_trunc('hour', request_timestamp)                 as event_hour,
    extract(dow  from request_timestamp)                  as request_dow,
    extract(hour from request_timestamp)                  as request_hour,
    count(*)                                              as trip_count,
    sum(case when is_cancelled then 1 else 0 end)         as cancelled_count,
    avg(surge_multiplier)                                 as avg_surge,
    max(surge_multiplier)                                 as max_surge,
    sum(final_fare)                                       as gmv_inr
from __dbt__cte__int_trip_enriched
group by 1, 2, 3, 4, 5