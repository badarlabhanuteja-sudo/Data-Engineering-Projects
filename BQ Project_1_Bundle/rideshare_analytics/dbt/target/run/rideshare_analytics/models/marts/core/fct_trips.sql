
  
    

    create or replace table `project-d8d88b02-3334-4b57-b24`.`marts`.`fct_trips`
      
    
    cluster by request_date

    
    OPTIONS(
      description="""Trip fact, incremental on _loaded_at, clustered by request_date"""
    )
    as (
      

with  __dbt__cte__int_trip_enriched as (


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
), src as (
    select * from __dbt__cte__int_trip_enriched
    
),

dim_d as (select driver_sk, driver_business_key, valid_from, valid_to from `project-d8d88b02-3334-4b57-b24`.`marts`.`dim_driver_scd2`),
dim_r as (select rider_sk,  rider_business_key,  valid_from, valid_to from `project-d8d88b02-3334-4b57-b24`.`marts`.`dim_rider_scd2`)

select
    s.trip_id,
    dr.driver_sk,
    s.driver_id                              as driver_business_key,
    ri.rider_sk,
    s.rider_id                               as rider_business_key,
    s.city_id,
    to_hex(md5(cast(coalesce(cast(s.city_id as string), '_dbt_utils_surrogate_key_null_') as string))) as city_sk,
    to_hex(md5(cast(coalesce(cast(s.request_date as string), '_dbt_utils_surrogate_key_null_') as string))) as date_sk,
    s.request_timestamp,
    s.pickup_timestamp,
    s.dropoff_timestamp,
    s.request_date,
    s.request_hour,
    s.request_dow,
    s.distance_km,
    s.duration_min,
    s.base_fare,
    s.surge_multiplier,
    s.surge_band,
    s.surge_uplift_inr,
    s.final_fare,
    s.payment_method,
    s.trip_status,
    s.is_completed,
    s.is_cancelled,
    s.wait_seconds,
    s.rating_by_rider,
    s.rating_by_driver,
    s.paid_amount,
    s.is_paid_success,
    s.is_paid_failed,
    s.is_refunded,
    s._loaded_at,
    current_timestamp() as _dbt_inserted_at
from src s
left join dim_d dr
       on s.driver_id = dr.driver_business_key
      and s.request_timestamp >= dr.valid_from
      and s.request_timestamp <  dr.valid_to
left join dim_r ri
       on s.rider_id = ri.rider_business_key
      and s.request_timestamp >= ri.valid_from
      and s.request_timestamp <  ri.valid_to
    );
  