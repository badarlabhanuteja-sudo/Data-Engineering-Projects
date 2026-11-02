
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `project-d8d88b02-3334-4b57-b24`.`dbt_test_failures`.`dbt_expectations_expect_column_2e3177e68eea27dc877597dc52d6e0e6`
    
      
    ) dbt_internal_test