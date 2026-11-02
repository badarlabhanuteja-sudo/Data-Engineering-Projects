
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `streaming-media-498412`.`dbt_dev_dbt_test_failures`.`dbt_utils_expression_is_true_s_0cb06eff997b12a0bbfb9a331dd3ce4e`
    
      
    ) dbt_internal_test