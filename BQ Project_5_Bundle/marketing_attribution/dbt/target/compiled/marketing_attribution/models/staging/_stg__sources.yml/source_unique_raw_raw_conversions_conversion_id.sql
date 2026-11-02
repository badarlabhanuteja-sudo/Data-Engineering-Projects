
    
    

with dbt_test__target as (

  select conversion_id as unique_field
  from `marketing-attribution-498615`.`raw`.`raw_conversions`
  where conversion_id is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


