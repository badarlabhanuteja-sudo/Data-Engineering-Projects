-- back compat for old kwarg name
  
  
        
            
            
            
            
        
    

    

    merge into `project-d8d88b02-3334-4b57-b24`.`marts`.`mart_driver_utilization_baseline` as DBT_INTERNAL_DEST
        using (

with last_24h as (

select
    driver_id,
    count(*) as trips_24h,
    sum(distance_km) as km_24h,
    sum(final_fare) as revenue_24h,
    sum(duration_min) as active_minutes_24h,
    max(dropoff_timestamp) as last_trip_at

from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_trips`

where is_completed
  and dropoff_timestamp >= TIMESTAMP_SUB(
        CURRENT_TIMESTAMP(),
        INTERVAL 24 HOUR
      )

group by driver_id


)

select
driver_id,
trips_24h,
km_24h,
revenue_24h,
active_minutes_24h,
last_trip_at,


    SAFE_DIVIDE(CAST(active_minutes_24h AS FLOAT64), CAST(1440.0 AS FLOAT64))

    as utilisation_24h,

case
    when trips_24h >= 20 then 'high'
    when trips_24h >= 10 then 'medium'
    when trips_24h >= 3 then 'low'
    else 'inactive'
end as utilisation_band,

CURRENT_TIMESTAMP() as _dbt_inserted_at


from last_24h
        ) as DBT_INTERNAL_SOURCE
        on ((DBT_INTERNAL_SOURCE.driver_id = DBT_INTERNAL_DEST.driver_id))

    
    when matched then update set
        `driver_id` = DBT_INTERNAL_SOURCE.`driver_id`,`trips_24h` = DBT_INTERNAL_SOURCE.`trips_24h`,`km_24h` = DBT_INTERNAL_SOURCE.`km_24h`,`revenue_24h` = DBT_INTERNAL_SOURCE.`revenue_24h`,`active_minutes_24h` = DBT_INTERNAL_SOURCE.`active_minutes_24h`,`last_trip_at` = DBT_INTERNAL_SOURCE.`last_trip_at`,`utilisation_24h` = DBT_INTERNAL_SOURCE.`utilisation_24h`,`utilisation_band` = DBT_INTERNAL_SOURCE.`utilisation_band`,`_dbt_inserted_at` = DBT_INTERNAL_SOURCE.`_dbt_inserted_at`
    

    when not matched then insert
        (`driver_id`, `trips_24h`, `km_24h`, `revenue_24h`, `active_minutes_24h`, `last_trip_at`, `utilisation_24h`, `utilisation_band`, `_dbt_inserted_at`)
    values
        (`driver_id`, `trips_24h`, `km_24h`, `revenue_24h`, `active_minutes_24h`, `last_trip_at`, `utilisation_24h`, `utilisation_band`, `_dbt_inserted_at`)


    