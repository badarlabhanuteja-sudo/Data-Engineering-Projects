
  
    

    create or replace table `project-d8d88b02-3334-4b57-b24`.`marts`.`fct_driver_pings_hourly_baseline`
      
    
    

    
    OPTIONS(
      description="""BASELINE for the empirical study \u2014 incremental, refreshed on Airflow schedule"""
    )
    as (
      

with src as (
    select * from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_location_pings`
    
)

select
    driver_id,
    TIMESTAMP_TRUNC(ping_timestamp, HOUR)      as ping_hour,
    count(*)                                   as ping_count,
    avg(speed_kmph)                            as avg_speed_kmph,
    min(ping_timestamp)                        as hour_first_ping,
    max(ping_timestamp)                        as hour_last_ping,
    CURRENT_TIMESTAMP()                        as _dbt_inserted_at
from src
group by 1, 2
    );
  