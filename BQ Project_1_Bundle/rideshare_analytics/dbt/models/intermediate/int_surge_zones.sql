{{ config(materialized='ephemeral') }}

select
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
from {{ ref('int_trip_enriched') }}
group by 1, 2, 3, 4, 5
