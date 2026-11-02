
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `ecommerce-customer360`.`dbt_test_failures`.`dbt_utils_expression_is_true_m_e161e6045cf99feb5c067cd2ac35ed28`
    
      
    ) dbt_internal_test