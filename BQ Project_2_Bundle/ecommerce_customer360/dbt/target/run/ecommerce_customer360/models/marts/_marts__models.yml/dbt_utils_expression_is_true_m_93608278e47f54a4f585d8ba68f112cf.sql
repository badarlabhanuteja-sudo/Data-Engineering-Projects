
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `project-d8d88b02-3334-4b57-b24`.`dbt_test_failures`.`dbt_utils_expression_is_true_m_93608278e47f54a4f585d8ba68f112cf`
    
      
    ) dbt_internal_test