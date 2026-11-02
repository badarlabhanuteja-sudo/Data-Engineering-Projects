-- Every completed trip must have a dropoff timestamp
select trip_id, trip_status, dropoff_timestamp
  from {{ ref('fct_trips') }}
 where trip_status = 'completed' and dropoff_timestamp is null
