
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `streaming-media-498412`.`dbt_dev_dbt_test_failures`.`accepted_values_stg_view_event_19c2af4527cec469a95194d7b2b6deb6`
    
      
    ) dbt_internal_test