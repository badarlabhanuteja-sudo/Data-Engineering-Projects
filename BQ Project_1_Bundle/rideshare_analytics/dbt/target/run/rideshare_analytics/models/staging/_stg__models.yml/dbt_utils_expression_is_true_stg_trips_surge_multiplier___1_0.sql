
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `project-d8d88b02-3334-4b57-b24`.`dbt_test_failures`.`dbt_utils_expression_is_true_stg_trips_surge_multiplier___1_0`
    
      
    ) dbt_internal_test