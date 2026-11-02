
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `streaming-media-498412`.`dbt_dev_dbt_test_failures`.`accepted_values_stg_titles_content_type__movie__show__episode`
    
      
    ) dbt_internal_test