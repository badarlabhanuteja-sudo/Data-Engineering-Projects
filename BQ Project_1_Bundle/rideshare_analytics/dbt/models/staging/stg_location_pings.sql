{{ config(materialized='view') }}

select
    ping_id,
    driver_id,
    CAST(ping_timestamp AS TIMESTAMP) as ping_timestamp,
    lat,
    lng,
    speed_kmph,
    heading,
    is_on_trip,
    battery_pct,
    CURRENT_TIMESTAMP() as _loaded_at
from {{ source('raw', 'raw_location_pings') }}

