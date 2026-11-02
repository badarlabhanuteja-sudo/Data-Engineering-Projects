
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `streaming-media-498412`.`dbt_dev_dbt_test_failures`.`relationships_fct_view_events_1ed594cc3a8b5dea669c0f75414bd53b`
    
      
    ) dbt_internal_test