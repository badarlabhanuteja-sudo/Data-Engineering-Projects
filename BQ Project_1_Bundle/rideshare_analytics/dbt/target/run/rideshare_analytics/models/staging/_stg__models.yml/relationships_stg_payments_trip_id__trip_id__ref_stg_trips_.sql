
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `project-d8d88b02-3334-4b57-b24`.`dbt_test_failures`.`relationships_stg_payments_trip_id__trip_id__ref_stg_trips_`
    
      
    ) dbt_internal_test