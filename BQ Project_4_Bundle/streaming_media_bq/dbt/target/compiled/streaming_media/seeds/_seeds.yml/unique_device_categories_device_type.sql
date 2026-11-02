
    
    

with dbt_test__target as (

  select device_type as unique_field
  from `streaming-media-498412`.`dbt_dev_seeds`.`device_categories`
  where device_type is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


