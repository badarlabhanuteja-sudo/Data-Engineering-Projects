
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `ecommerce-customer360`.`dbt_test_failures`.`unique_mart_churn_prediction_customer_id`
    
      
    ) dbt_internal_test