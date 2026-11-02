{{ config(materialized='table') }}

with snap as (select * from {{ ref('riders_snapshot') }})

select
    {{ dbt_utils.generate_surrogate_key(['rider_id', 'dbt_valid_from']) }} as rider_sk,
    rider_id                                  as rider_business_key,
    first_name,
    last_name,
    email,
    home_city_id,
    rider_tier,
    is_active,
    dbt_valid_from                            as valid_from,
    coalesce(dbt_valid_to, '9999-12-31')      as valid_to,
    case when dbt_valid_to is null then true else false end as is_current
from snap
