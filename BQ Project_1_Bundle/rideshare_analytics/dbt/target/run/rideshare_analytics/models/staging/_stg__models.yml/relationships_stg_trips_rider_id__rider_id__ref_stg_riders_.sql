
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `project-d8d88b02-3334-4b57-b24`.`dbt_test_failures`.`relationships_stg_trips_rider_id__rider_id__ref_stg_riders_`
    
      
    ) dbt_internal_test