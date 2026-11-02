
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `streaming-media-498412`.`dbt_dev_dbt_test_failures`.`accepted_values_stg_users_9d6631bbe7a23892d00a2ef92c7bc58a`
    
      
    ) dbt_internal_test