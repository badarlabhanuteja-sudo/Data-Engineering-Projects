{{ config(
    materialized='table',
    unique_key=['city_id','slice_start'],
    incremental_strategy='merge',
    tags=['experiment_baseline','baseline_incremental']
) }}

with src as (
    select * from {{ ref('stg_trips') }}
    {% if is_incremental() %}
        where request_timestamp >= (
            select TIMESTAMP_SUB(
                COALESCE(MAX(slice_start), TIMESTAMP('1900-01-01')),
                INTERVAL 2 HOUR
            ) from {{ this }}
        )
    {% endif %}
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
