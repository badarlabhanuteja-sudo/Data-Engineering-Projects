
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select meta_event_id
from `marketing-attribution-498615`.`raw`.`raw_meta_ads`
where meta_event_id is null



  
  
      
    ) dbt_internal_test