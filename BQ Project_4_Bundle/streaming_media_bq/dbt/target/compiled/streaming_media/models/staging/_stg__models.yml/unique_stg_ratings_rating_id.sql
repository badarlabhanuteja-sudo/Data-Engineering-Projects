
    
    

with dbt_test__target as (

  select rating_id as unique_field
  from `streaming-media-498412`.`dbt_dev_staging`.`stg_ratings`
  where rating_id is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


