
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select spend_id
from `marketing-attribution-498615`.`raw`.`raw_ad_spend`
where spend_id is null



  
  
      
    ) dbt_internal_test