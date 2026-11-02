
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select conversion_id
from `marketing-attribution-498615`.`raw`.`stg_conversions`
where conversion_id is null



  
  
      
    ) dbt_internal_test