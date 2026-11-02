
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `ecommerce-customer360`.`dbt_test_failures`.`assert_order_totals_consistent`
    
      
    ) dbt_internal_test