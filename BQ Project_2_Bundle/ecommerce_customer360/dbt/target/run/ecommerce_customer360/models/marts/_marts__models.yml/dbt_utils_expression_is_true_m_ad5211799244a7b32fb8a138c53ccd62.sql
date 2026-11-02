
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `project-d8d88b02-3334-4b57-b24`.`dbt_test_failures`.`dbt_utils_expression_is_true_m_ad5211799244a7b32fb8a138c53ccd62`
    
      
    ) dbt_internal_test