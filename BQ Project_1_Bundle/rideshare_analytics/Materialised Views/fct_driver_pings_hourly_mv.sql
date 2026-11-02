CREATE OR REPLACE MATERIALIZED VIEW `your-project-id.streams_dt.fct_driver_pings_hourly_mv`
OPTIONS (enable_refresh = true, refresh_interval_minutes = 1)
AS
SELECT
  driver_id,
  TIMESTAMP_TRUNC(CAST(ping_timestamp AS TIMESTAMP), HOUR)   AS ping_hour,
  COUNT(*)                                                    AS ping_count,
  AVG(speed_kmph)                                             AS avg_speed_kmph,
  MIN(CAST(ping_timestamp AS TIMESTAMP))                      AS hour_first_ping,
  MAX(CAST(ping_timestamp AS TIMESTAMP))                      AS hour_last_ping
FROM `your-project-id.raw.raw_location_pings`
GROUP BY 1, 2;
