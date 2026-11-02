
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `project-d8d88b02-3334-4b57-b24`.`dbt_test_failures`.`accepted_values_stg_web_events_b291758d2421358a4cb1bca890fdb220`
    
      
    ) dbt_internal_test