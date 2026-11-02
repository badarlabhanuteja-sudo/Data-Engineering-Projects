{{ config(materialized='table') }}

with rider_lt as (select * from {{ ref('int_rider_lifetime') }}),
     riders   as (select * from {{ ref('stg_riders') }}),
     cities   as (select * from {{ ref('stg_cities') }})

select
    r.rider_id,
    r.first_name,
    r.last_name,
    r.email,
    r.rider_tier,
    c.city_name                                                       as home_city,
    coalesce(rl.total_trips, 0)                                       as total_trips,
    coalesce(rl.gross_spend_inr, 0)                                   as gross_spend_inr,
    rl.last_trip_at,
    rl.days_since_last_trip,
    case
        when rl.days_since_last_trip is null      then 'never_rode'
        when rl.days_since_last_trip <= 7         then 'active'
        when rl.days_since_last_trip <= 30        then 'recent'
        when rl.days_since_last_trip <= 60        then 'lapsing'
        else 'churned'
    end                                                                as activity_band,
    case
        when rl.days_since_last_trip > 30 then true
        else false
    end                                                                as is_30day_churned
from riders r
left join rider_lt rl on r.rider_id = rl.rider_id
left join cities c    on r.home_city_id = c.city_id
