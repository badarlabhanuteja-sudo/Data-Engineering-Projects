
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `project-d8d88b02-3334-4b57-b24`.`dbt_test_failures`.`accepted_values_stg_customers_a482c0d00a76d878230aaee61c691d79`
    
      
    ) dbt_internal_test