{{ config(materialized='ephemeral') }}

with completed as (
    select * from {{ ref('stg_trips') }} where is_completed
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
    DATE_DIFF(DATE('{{ var("analysis_as_of_date") }}'), DATE(max(request_timestamp)), DAY) as days_since_last_trip
from completed
group by 1