-- Surge multipliers should be between 1.0 and 5.0
select trip_id, surge_multiplier
  from {{ ref('fct_trips') }}
 where surge_multiplier < 1.0 or surge_multiplier > 5.0
