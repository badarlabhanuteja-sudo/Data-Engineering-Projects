-- back compat for old kwarg name
  
  
        
            
            
            
            
        
    

    

    merge into `project-d8d88b02-3334-4b57-b24`.`MARTS`.`fct_orders` as DBT_INTERNAL_DEST
        using (
        select
        * from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`fct_orders__dbt_tmp`
        ) as DBT_INTERNAL_SOURCE
        on ((DBT_INTERNAL_SOURCE.order_id = DBT_INTERNAL_DEST.order_id))

    
    when matched then update set
        `order_id` = DBT_INTERNAL_SOURCE.`order_id`,`customer_sk` = DBT_INTERNAL_SOURCE.`customer_sk`,`customer_business_key` = DBT_INTERNAL_SOURCE.`customer_business_key`,`order_date` = DBT_INTERNAL_SOURCE.`order_date`,`date_sk` = DBT_INTERNAL_SOURCE.`date_sk`,`order_timestamp` = DBT_INTERNAL_SOURCE.`order_timestamp`,`order_status` = DBT_INTERNAL_SOURCE.`order_status`,`payment_method` = DBT_INTERNAL_SOURCE.`payment_method`,`shipping_method` = DBT_INTERNAL_SOURCE.`shipping_method`,`promo_code` = DBT_INTERNAL_SOURCE.`promo_code`,`discount_amount` = DBT_INTERNAL_SOURCE.`discount_amount`,`shipping_amount` = DBT_INTERNAL_SOURCE.`shipping_amount`,`tax_amount` = DBT_INTERNAL_SOURCE.`tax_amount`,`total_amount` = DBT_INTERNAL_SOURCE.`total_amount`,`gross_merchandise_value` = DBT_INTERNAL_SOURCE.`gross_merchandise_value`,`currency` = DBT_INTERNAL_SOURCE.`currency`,`is_first_order` = DBT_INTERNAL_SOURCE.`is_first_order`,`is_completed` = DBT_INTERNAL_SOURCE.`is_completed`,`created_at` = DBT_INTERNAL_SOURCE.`created_at`,`updated_at` = DBT_INTERNAL_SOURCE.`updated_at`,`_dbt_inserted_at` = DBT_INTERNAL_SOURCE.`_dbt_inserted_at`
    

    when not matched then insert
        (`order_id`, `customer_sk`, `customer_business_key`, `order_date`, `date_sk`, `order_timestamp`, `order_status`, `payment_method`, `shipping_method`, `promo_code`, `discount_amount`, `shipping_amount`, `tax_amount`, `total_amount`, `gross_merchandise_value`, `currency`, `is_first_order`, `is_completed`, `created_at`, `updated_at`, `_dbt_inserted_at`)
    values
        (`order_id`, `customer_sk`, `customer_business_key`, `order_date`, `date_sk`, `order_timestamp`, `order_status`, `payment_method`, `shipping_method`, `promo_code`, `discount_amount`, `shipping_amount`, `tax_amount`, `total_amount`, `gross_merchandise_value`, `currency`, `is_first_order`, `is_completed`, `created_at`, `updated_at`, `_dbt_inserted_at`)


    