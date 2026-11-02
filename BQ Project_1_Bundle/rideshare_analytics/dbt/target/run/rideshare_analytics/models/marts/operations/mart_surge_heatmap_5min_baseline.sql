
  
    

    create or replace table `project-d8d88b02-3334-4b57-b24`.`marts`.`mart_surge_heatmap_5min_baseline`
      
    
    

    
    OPTIONS(
      description="""BASELINE 5-minute surge heatmap"""
    )
    as (
      

with src as (
    select * from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_trips`
    
)

select
    city_id,
    TIMESTAMP_TRUNC(request_timestamp, MINUTE) as slice_start,
    count(*)                                   as demand_count,
    avg(surge_multiplier)                      as avg_surge,
    max(surge_multiplier)                      as max_surge,
    sum(case when is_cancelled then 1 else 0 end) as cancellations,
    CURRENT_TIMESTAMP()                        as _dbt_inserted_at
from src
group by 1, 2
    );
  