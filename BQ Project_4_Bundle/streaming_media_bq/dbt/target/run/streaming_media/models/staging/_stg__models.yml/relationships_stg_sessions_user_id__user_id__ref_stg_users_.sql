
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `streaming-media-498412`.`dbt_dev_dbt_test_failures`.`relationships_stg_sessions_user_id__user_id__ref_stg_users_`
    
      
    ) dbt_internal_test