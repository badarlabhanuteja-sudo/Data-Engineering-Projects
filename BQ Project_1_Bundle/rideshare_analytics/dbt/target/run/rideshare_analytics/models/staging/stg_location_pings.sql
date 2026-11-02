

  create or replace view `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_location_pings`
  OPTIONS(
      description=""""""
    )
  as 

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
from `project-d8d88b02-3334-4b57-b24`.`raw`.`raw_location_pings`;

