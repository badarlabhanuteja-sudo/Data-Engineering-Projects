

with sources as (
    select distinct
        country_code,
        state,
        city
    from `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_customers`
)

select
    to_hex(md5(cast(coalesce(cast(country_code as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(state as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(city as string), '_dbt_utils_surrogate_key_null_') as string))) as geography_sk,
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