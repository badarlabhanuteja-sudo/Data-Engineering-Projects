
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select email_event_id
from `marketing-attribution-498615`.`raw`.`raw_email_events`
where email_event_id is null



  
  
      
    ) dbt_internal_test