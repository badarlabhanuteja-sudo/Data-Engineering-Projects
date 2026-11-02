{{ config(materialized='table') }}

with sources as (
    select distinct
        country_code,
        state,
        city
    from {{ ref('stg_customers') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['country_code', 'state', 'city']) }} as geography_sk,
    country_code,
    state,
    city,
    case country_code
        when 'IN' then 'India'
        when 'GB' then 'United Kingdom'
        when 'US' then 'United States'
        when 'CA' then 'Canada'
        when 'AU' then 'Australia'
        else country_code
    end                                  as country_name,
    case
        when country_code = 'IN' then 'APAC'
        when country_code in ('GB') then 'EMEA'
        when country_code in ('US', 'CA') then 'NAM'
        when country_code = 'AU' then 'APAC'
        else 'OTHER'
    end                                  as region
from sources

