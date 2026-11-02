
    
    

with dbt_test__target as (

  select date_sk as unique_field
  from `streaming-media-498412`.`dbt_dev_marts`.`dim_date`
  where date_sk is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


