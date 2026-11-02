
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `project-d8d88b02-3334-4b57-b24`.`dbt_test_failures`.`accepted_values_mart_clv_segme_3a7ee86934935df85b553715e7202a6e`
    
      
    ) dbt_internal_test