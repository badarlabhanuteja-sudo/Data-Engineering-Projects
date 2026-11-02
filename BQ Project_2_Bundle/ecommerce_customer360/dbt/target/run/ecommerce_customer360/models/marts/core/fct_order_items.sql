-- back compat for old kwarg name
  
  
        
            
            
            
            
        
    

    

    merge into `project-d8d88b02-3334-4b57-b24`.`MARTS`.`fct_order_items` as DBT_INTERNAL_DEST
        using (
        select
        * from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`fct_order_items__dbt_tmp`
        ) as DBT_INTERNAL_SOURCE
        on ((DBT_INTERNAL_SOURCE.order_item_id = DBT_INTERNAL_DEST.order_item_id))

    
    when matched then update set
        `order_item_id` = DBT_INTERNAL_SOURCE.`order_item_id`,`order_id` = DBT_INTERNAL_SOURCE.`order_id`,`customer_sk` = DBT_INTERNAL_SOURCE.`customer_sk`,`product_sk` = DBT_INTERNAL_SOURCE.`product_sk`,`product_business_key` = DBT_INTERNAL_SOURCE.`product_business_key`,`order_date` = DBT_INTERNAL_SOURCE.`order_date`,`quantity` = DBT_INTERNAL_SOURCE.`quantity`,`unit_price` = DBT_INTERNAL_SOURCE.`unit_price`,`line_total` = DBT_INTERNAL_SOURCE.`line_total`,`created_at` = DBT_INTERNAL_SOURCE.`created_at`,`_dbt_inserted_at` = DBT_INTERNAL_SOURCE.`_dbt_inserted_at`
    

    when not matched then insert
        (`order_item_id`, `order_id`, `customer_sk`, `product_sk`, `product_business_key`, `order_date`, `quantity`, `unit_price`, `line_total`, `created_at`, `_dbt_inserted_at`)
    values
        (`order_item_id`, `order_id`, `customer_sk`, `product_sk`, `product_business_key`, `order_date`, `quantity`, `unit_price`, `line_total`, `created_at`, `_dbt_inserted_at`)


    