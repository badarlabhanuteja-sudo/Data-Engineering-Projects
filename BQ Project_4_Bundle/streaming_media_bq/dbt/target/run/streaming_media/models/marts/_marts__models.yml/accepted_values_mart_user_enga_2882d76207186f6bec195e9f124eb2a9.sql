
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `streaming-media-498412`.`dbt_dev_dbt_test_failures`.`accepted_values_mart_user_enga_2882d76207186f6bec195e9f124eb2a9`
    
      
    ) dbt_internal_test