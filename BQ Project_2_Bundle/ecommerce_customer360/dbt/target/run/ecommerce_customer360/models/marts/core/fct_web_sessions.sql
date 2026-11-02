-- back compat for old kwarg name
  
  
        
            
            
            
            
        
    

    

    merge into `project-d8d88b02-3334-4b57-b24`.`MARTS`.`fct_web_sessions` as DBT_INTERNAL_DEST
        using (
        select
        * from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`fct_web_sessions__dbt_tmp`
        ) as DBT_INTERNAL_SOURCE
        on ((DBT_INTERNAL_SOURCE.session_id = DBT_INTERNAL_DEST.session_id))

    
    when matched then update set
        `session_id` = DBT_INTERNAL_SOURCE.`session_id`,`customer_sk` = DBT_INTERNAL_SOURCE.`customer_sk`,`customer_business_key` = DBT_INTERNAL_SOURCE.`customer_business_key`,`session_start` = DBT_INTERNAL_SOURCE.`session_start`,`session_end` = DBT_INTERNAL_SOURCE.`session_end`,`session_date` = DBT_INTERNAL_SOURCE.`session_date`,`date_sk` = DBT_INTERNAL_SOURCE.`date_sk`,`session_duration_sec` = DBT_INTERNAL_SOURCE.`session_duration_sec`,`event_count` = DBT_INTERNAL_SOURCE.`event_count`,`distinct_event_types` = DBT_INTERNAL_SOURCE.`distinct_event_types`,`page_views` = DBT_INTERNAL_SOURCE.`page_views`,`product_views` = DBT_INTERNAL_SOURCE.`product_views`,`cart_adds` = DBT_INTERNAL_SOURCE.`cart_adds`,`checkouts_started` = DBT_INTERNAL_SOURCE.`checkouts_started`,`purchases_completed` = DBT_INTERNAL_SOURCE.`purchases_completed`,`has_purchase` = DBT_INTERNAL_SOURCE.`has_purchase`,`_dbt_inserted_at` = DBT_INTERNAL_SOURCE.`_dbt_inserted_at`
    

    when not matched then insert
        (`session_id`, `customer_sk`, `customer_business_key`, `session_start`, `session_end`, `session_date`, `date_sk`, `session_duration_sec`, `event_count`, `distinct_event_types`, `page_views`, `product_views`, `cart_adds`, `checkouts_started`, `purchases_completed`, `has_purchase`, `_dbt_inserted_at`)
    values
        (`session_id`, `customer_sk`, `customer_business_key`, `session_start`, `session_end`, `session_date`, `date_sk`, `session_duration_sec`, `event_count`, `distinct_event_types`, `page_views`, `product_views`, `cart_adds`, `checkouts_started`, `purchases_completed`, `has_purchase`, `_dbt_inserted_at`)


    