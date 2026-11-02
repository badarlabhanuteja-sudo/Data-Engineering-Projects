
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select channel
from `marketing-attribution-498615`.`raw`.`channels`
where channel is null



  
  
      
    ) dbt_internal_test