
    
    

with dbt_test__target as (

  select country_code as unique_field
  from `project-d8d88b02-3334-4b57-b24`.`seeds`.`country_codes`
  where country_code is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


