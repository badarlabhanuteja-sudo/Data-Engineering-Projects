{{ config(materialized='table') }}

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2022-01-01' as date)",
        end_date="cast('2026-12-31' as date)"
       )
    }}
)

select
    date_day                                                              as date_day,
    {{ dbt_utils.generate_surrogate_key(['date_day']) }}                  as date_sk,
    extract(year     from date_day)                                       as year_number,
    extract(quarter  from date_day)                                       as quarter_number,
    extract(month    from date_day)                                       as month_number,
    format_date('%B', date_day)                                           as month_name,
    extract(isoweek  from date_day)                                       as iso_week_number,
    extract(day      from date_day)                                       as day_of_month,
    format_date('%A', date_day)                                           as day_name,
    extract(dayofweek from date_day)                                      as day_of_week_number,
    case when extract(dayofweek from date_day) in (1, 7) then true
         else false end                                                   as is_weekend,
    date_trunc(date_day, month)                                           as month_start_date,
    last_day(date_day, month)                                             as month_end_date,
    date_trunc(date_day, quarter)                                         as quarter_start_date,
    last_day(date_day, quarter)                                           as quarter_end_date,
    case when date_day = current_date() then true else false end           as is_today,
    case when date_day < current_date() then true else false end           as is_past
from date_spine

