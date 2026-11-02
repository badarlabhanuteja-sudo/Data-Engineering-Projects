
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `streaming-media-498412`.`dbt_dev_dbt_test_failures`.`accepted_values_mart_content_p_e7b06c57358b2fe952eb426c154ec1c6`
    
      
    ) dbt_internal_test