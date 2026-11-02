{{ config(materialized='table') }}

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2025-06-01' as date)",
        end_date="cast('2026-12-31' as date)"
    ) }}
)

select
    date_day,
    {{ dbt_utils.generate_surrogate_key(['date_day']) }}      as date_sk,
    EXTRACT(year  FROM date_day)                               as year_number,
    EXTRACT(quarter FROM date_day)                             as quarter_number,
    EXTRACT(month FROM date_day)                               as month_number,
    FORMAT_DATE('%B', date_day)                                as month_name,
    EXTRACT(isoweek FROM date_day)                             as iso_week_number,
    EXTRACT(day   FROM date_day)                               as day_of_month,
    FORMAT_DATE('%A', date_day)                                as day_name,
    EXTRACT(dayofweek FROM date_day)                           as day_of_week_number,
    case when EXTRACT(dayofweek FROM date_day) in (1, 7) then true else false end as is_weekend
from date_spine