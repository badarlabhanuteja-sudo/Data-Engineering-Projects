{{
    config(
        materialized='table',
        unique_key=['driver_id', 'ping_hour'],
        on_schema_change='append_new_columns',
        incremental_strategy='merge',
        tags=['experiment_baseline', 'baseline_incremental']
    )
}}

with src as (
    select * from {{ ref('stg_location_pings') }}
    {% if is_incremental() %}
        where ping_timestamp >= (
            select TIMESTAMP_SUB(
                COALESCE(MAX(hour_last_ping), TIMESTAMP('1900-01-01')),
                INTERVAL 2 HOUR
            ) from {{ this }}
        )
    {% endif %}
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
