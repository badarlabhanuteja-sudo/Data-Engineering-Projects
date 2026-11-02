
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `project-d8d88b02-3334-4b57-b24`.`dbt_test_failures`.`accepted_values_stg_email_even_e3293887acbc9c9c9ef168aae986a77a`
    
      
    ) dbt_internal_test