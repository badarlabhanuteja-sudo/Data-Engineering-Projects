
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `project-d8d88b02-3334-4b57-b24`.`dbt_test_failures`.`accepted_values_stg_drivers_82e21092597e268f1cfaa54d261090e2`
    
      
    ) dbt_internal_test