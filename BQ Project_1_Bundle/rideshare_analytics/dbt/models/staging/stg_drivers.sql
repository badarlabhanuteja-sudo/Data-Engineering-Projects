{{ config(materialized='view') }}

select
    driver_id,
    initcap(first_name)                          as first_name,
    initcap(last_name)                           as last_name,
    phone,
    license_number,
    lower(vehicle_type)                          as vehicle_type,
    upper(vehicle_number)                        as vehicle_number,
    rating,
    home_city_id,
    onboarding_date,
    lower(status)                                as status,
    is_active,
    DATE_DIFF(current_date(), onboarding_date, DAY) as tenure_days,
    created_at,
    updated_at,
    CURRENT_TIMESTAMP() as _loaded_at
from {{ source('raw', 'raw_drivers') }}
