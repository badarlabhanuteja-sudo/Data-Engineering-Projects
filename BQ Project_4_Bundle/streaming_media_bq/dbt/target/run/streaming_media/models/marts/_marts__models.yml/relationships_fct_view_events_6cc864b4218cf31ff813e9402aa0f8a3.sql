
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `streaming-media-498412`.`dbt_dev_dbt_test_failures`.`relationships_fct_view_events_6cc864b4218cf31ff813e9402aa0f8a3`
    
      
    ) dbt_internal_test