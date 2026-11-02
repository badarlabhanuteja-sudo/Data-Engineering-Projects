
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `project-d8d88b02-3334-4b57-b24`.`dbt_test_failures`.`relationships_stg_orders_96411fe0c89b49c3f4da955dfd358ba0`
    
      
    ) dbt_internal_test