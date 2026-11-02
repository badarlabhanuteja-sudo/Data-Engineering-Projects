{{
    config(
        materialized='table',
        unique_key='trip_id',
        on_schema_change='append_new_columns',
        incremental_strategy='merge',
        cluster_by=['request_date']
    )
}}

with src as (
    select * from {{ ref('int_trip_enriched') }}
    {% if is_incremental() %}
        where _loaded_at >= (select COALESCE(MAX(_loaded_at), TIMESTAMP('1900-01-01')) from {{ this }})
    {% endif %}
),

dim_d as (select driver_sk, driver_business_key, valid_from, valid_to from {{ ref('dim_driver_scd2') }}),
dim_r as (select rider_sk,  rider_business_key,  valid_from, valid_to from {{ ref('dim_rider_scd2') }})

select
    s.trip_id,
    dr.driver_sk,
    s.driver_id                              as driver_business_key,
    ri.rider_sk,
    s.rider_id                               as rider_business_key,
    s.city_id,
    {{ dbt_utils.generate_surrogate_key(['s.city_id']) }} as city_sk,
    {{ dbt_utils.generate_surrogate_key(['s.request_date']) }} as date_sk,
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

