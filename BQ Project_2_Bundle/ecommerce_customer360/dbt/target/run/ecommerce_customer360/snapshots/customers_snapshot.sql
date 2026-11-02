
      merge into `project-d8d88b02-3334-4b57-b24`.`SNAPSHOTS`.`customers_snapshot` as DBT_INTERNAL_DEST
    using `project-d8d88b02-3334-4b57-b24`.`SNAPSHOTS`.`customers_snapshot__dbt_tmp` as DBT_INTERNAL_SOURCE
    on DBT_INTERNAL_SOURCE.dbt_scd_id = DBT_INTERNAL_DEST.dbt_scd_id

    when matched
     
       and DBT_INTERNAL_DEST.dbt_valid_to is null
     
     and DBT_INTERNAL_SOURCE.dbt_change_type in ('update', 'delete')
        then update
        set dbt_valid_to = DBT_INTERNAL_SOURCE.dbt_valid_to

    when not matched
     and DBT_INTERNAL_SOURCE.dbt_change_type = 'insert'
        then insert (`customer_id`, `email`, `first_name`, `last_name`, `gender`, `country_code`, `state`, `city`, `postal_code`, `signup_channel`, `is_email_subscriber`, `customer_tier`, `updated_at`, `dbt_updated_at`, `dbt_valid_from`, `dbt_valid_to`, `dbt_scd_id`)
        values (`customer_id`, `email`, `first_name`, `last_name`, `gender`, `country_code`, `state`, `city`, `postal_code`, `signup_channel`, `is_email_subscriber`, `customer_tier`, `updated_at`, `dbt_updated_at`, `dbt_valid_from`, `dbt_valid_to`, `dbt_scd_id`)


  