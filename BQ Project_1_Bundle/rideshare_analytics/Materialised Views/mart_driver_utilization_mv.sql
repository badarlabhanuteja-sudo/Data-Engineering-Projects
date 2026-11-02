CREATE OR REPLACE MATERIALIZED VIEW `your-project-id.streams_dt.mart_driver_utilization_mv`
OPTIONS (enable_refresh = true, refresh_interval_minutes = 1)
AS
SELECT
  driver_id,
  COUNT(*)                AS trips_24h,
  SUM(distance_km)        AS km_24h,
  SUM(final_fare)         AS revenue_24h,
  SUM(duration_min)       AS active_minutes_24h,
  MAX(dropoff_timestamp)  AS last_trip_at
FROM `your-project-id.raw.raw_trips`
WHERE trip_status = 'completed'
GROUP BY 1;

