
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from `project-d8d88b02-3334-4b57-b24`.`dbt_test_failures`.`relationships_stg_order_items_b3d7cdbd08ebfad01e3226c01c10bba0`
    
      
    ) dbt_internal_test