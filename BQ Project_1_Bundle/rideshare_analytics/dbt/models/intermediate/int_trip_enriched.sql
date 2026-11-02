{{ config(materialized='ephemeral') }}

with t as (select * from {{ ref('stg_trips') }}),
     d as (select * from {{ ref('stg_drivers') }}),
     r as (select * from {{ ref('stg_riders') }}),
     c as (select * from {{ ref('stg_cities') }}),
     p as (
        select trip_id,
               sum(case when payment_status = 'success'  then amount else 0 end) as paid_amount,
               max(case when payment_status = 'success'  then 1 else 0 end) as is_paid_success,
               max(case when payment_status = 'failed'   then 1 else 0 end) as is_paid_failed,
               max(case when payment_status = 'refunded' then 1 else 0 end) as is_refunded
          from {{ ref('stg_payments') }}
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
    {{ classify_surge('t.surge_multiplier') }} as surge_band,
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
