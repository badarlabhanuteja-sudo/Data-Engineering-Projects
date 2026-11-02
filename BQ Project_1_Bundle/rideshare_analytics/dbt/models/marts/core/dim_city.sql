{{ config(materialized='table') }}

select
    {{ dbt_utils.generate_surrogate_key(['city_id']) }} as city_sk,
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
from {{ ref('stg_cities') }}
