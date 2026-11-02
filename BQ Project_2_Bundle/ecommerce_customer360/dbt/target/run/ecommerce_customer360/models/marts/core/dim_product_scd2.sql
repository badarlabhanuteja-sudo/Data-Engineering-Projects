
  
    

    create or replace table `project-d8d88b02-3334-4b57-b24`.`MARTS`.`dim_product_scd2`
      
    
    

    
    OPTIONS()
    as (
      

-- Sandbox workaround: use raw products instead of snapshot
select
    to_hex(md5(cast(coalesce(cast(product_id as string), '_dbt_utils_surrogate_key_null_') as string)))  as product_sk,
    product_id                          as product_business_key,
    product_name,
    category_id,
    brand,
    unit_price,
    cost,
    is_active,
    cast(created_at as date)            as valid_from,
    cast(null as date)                  as valid_to,
    true                                as is_current,
    created_at                          as dbt_updated_at
from `project-d8d88b02-3334-4b57-b24`.`RAW`.`raw_products`
    );
  