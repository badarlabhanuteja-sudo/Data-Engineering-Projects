
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select event_id
from `marketing-attribution-498615`.`raw`.`raw_web_events`
where event_id is null



  
  
      
    ) dbt_internal_test