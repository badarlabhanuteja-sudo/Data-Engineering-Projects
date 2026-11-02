
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from `marketing-attribution-498615`.`raw`.`stg_conversions`

where not(revenue >= 0)


  
  
      
    ) dbt_internal_test