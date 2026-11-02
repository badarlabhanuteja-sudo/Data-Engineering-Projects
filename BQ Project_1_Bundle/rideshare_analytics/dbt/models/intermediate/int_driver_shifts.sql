{{ config(materialized='ephemeral') }}

with pings as (
    select * from {{ ref('stg_location_pings') }}
),

with_gaps as (
    select
        driver_id,
        ping_timestamp,
        is_on_trip,
        speed_kmph,
        TIMESTAMP_DIFF(
            ping_timestamp,
            LAG(ping_timestamp) OVER (PARTITION BY driver_id ORDER BY ping_timestamp),
            SECOND
        ) as gap_seconds
    from pings
),

shift_starts as (
    select *,
           case when gap_seconds is null or gap_seconds > 1800 then 1 else 0 end as is_shift_start
    from with_gaps
),

with_shift_id as (
    select *,
           SUM(is_shift_start) OVER (
               PARTITION BY driver_id ORDER BY ping_timestamp
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) as shift_id
    from shift_starts
)

select
    driver_id,
    shift_id,
    min(ping_timestamp)                  as shift_start,
    max(ping_timestamp)                  as shift_end,
    TIMESTAMP_DIFF(max(ping_timestamp), min(ping_timestamp), MINUTE) as shift_duration_min,
    count(*)                             as ping_count,
    sum(case when is_on_trip then 1 else 0 end) as pings_on_trip,
    avg(speed_kmph)                      as avg_speed_kmph
from with_shift_id
group by 1, 2