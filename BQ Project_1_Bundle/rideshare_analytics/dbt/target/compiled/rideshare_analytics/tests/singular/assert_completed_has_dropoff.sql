-- Every completed trip must have a dropoff timestamp
select trip_id, trip_status, dropoff_timestamp
  from `project-d8d88b02-3334-4b57-b24`.`marts`.`fct_trips`
 where trip_status = 'completed' and dropoff_timestamp is null