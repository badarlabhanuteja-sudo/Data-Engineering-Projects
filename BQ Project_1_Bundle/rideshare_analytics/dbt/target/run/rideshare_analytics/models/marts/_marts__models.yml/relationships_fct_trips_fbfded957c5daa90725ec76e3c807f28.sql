
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `project-d8d88b02-3334-4b57-b24`.`dbt_test_failures`.`relationships_fct_trips_fbfded957c5daa90725ec76e3c807f28`
    
      
    ) dbt_internal_test