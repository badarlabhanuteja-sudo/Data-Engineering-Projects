
      merge into `project-d8d88b02-3334-4b57-b24`.`SNAPSHOTS`.`products_snapshot` as DBT_INTERNAL_DEST
    using `project-d8d88b02-3334-4b57-b24`.`SNAPSHOTS`.`products_snapshot__dbt_tmp` as DBT_INTERNAL_SOURCE
    on DBT_INTERNAL_SOURCE.dbt_scd_id = DBT_INTERNAL_DEST.dbt_scd_id

    when matched
     
       and DBT_INTERNAL_DEST.dbt_valid_to is null
     
     and DBT_INTERNAL_SOURCE.dbt_change_type in ('update', 'delete')
        then update
        set dbt_valid_to = DBT_INTERNAL_SOURCE.dbt_valid_to

    when not matched
     and DBT_INTERNAL_SOURCE.dbt_change_type = 'insert'
        then insert (`product_id`, `product_name`, `category_id`, `brand`, `supplier`, `unit_price`, `cost`, `is_active`, `launch_date`, `updated_at`, `dbt_updated_at`, `dbt_valid_from`, `dbt_valid_to`, `dbt_scd_id`)
        values (`product_id`, `product_name`, `category_id`, `brand`, `supplier`, `unit_price`, `cost`, `is_active`, `launch_date`, `updated_at`, `dbt_updated_at`, `dbt_valid_from`, `dbt_valid_to`, `dbt_scd_id`)


  