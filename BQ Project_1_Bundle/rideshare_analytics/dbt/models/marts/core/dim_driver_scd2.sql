{{ config(materialized='table') }}

with snap as (select * from {{ ref('drivers_snapshot') }})

select
    {{ dbt_utils.generate_surrogate_key(['driver_id', 'dbt_valid_from']) }} as driver_sk,
    driver_id                                  as driver_business_key,
    first_name,
    last_name,
    vehicle_type,
    vehicle_number,
    rating,
    home_city_id,
    status,
    is_active,
    dbt_valid_from                             as valid_from,
    coalesce(dbt_valid_to, '9999-12-31')       as valid_to,
    case when dbt_valid_to is null then true else false end as is_current
from snap
