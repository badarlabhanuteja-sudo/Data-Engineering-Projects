CREATE OR REPLACE MATERIALIZED VIEW `your-project-id.streams_dt.mart_surge_heatmap_5min_mv` OPTIONS (enable_refresh = true, refresh_interval_minutes = 1) 
AS 
SELECT 
city_id, 
TIMESTAMP_TRUNC(request_timestamp, MINUTE) AS slice_start, 
COUNT(*)                                   AS demand_count, 
AVG(surge_multiplier)                      AS avg_surge, 
MAX(surge_multiplier)                      AS max_surge, 
SUM(CASE WHEN trip_status = 'cancelled' THEN 1 ELSE 0 END) AS cancellations 
FROM `your-project-id.raw.raw_trips` 
GROUP BY 1, 2;
