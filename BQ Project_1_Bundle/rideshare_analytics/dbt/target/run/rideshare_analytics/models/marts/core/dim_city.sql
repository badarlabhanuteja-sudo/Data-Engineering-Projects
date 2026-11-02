
  
    

    create or replace table `project-d8d88b02-3334-4b57-b24`.`marts`.`dim_city`
      
    
    

    
    OPTIONS(
      description=""""""
    )
    as (
      

select
    to_hex(md5(cast(coalesce(cast(city_id as string), '_dbt_utils_surrogate_key_null_') as string))) as city_sk,
    city_id                                              as city_business_key,
    city_name,
    state,
    country_code,
    timezone,
    population,
    case
        when population >= 10000000 then 'mega'
        when population >=  5000000 then 'large'
        when population >=  2000000 then 'mid'
        else 'small'
    end                                                  as city_size_band,
    is_active
from `project-d8d88b02-3334-4b57-b24`.`staging`.`stg_cities`
    );
  