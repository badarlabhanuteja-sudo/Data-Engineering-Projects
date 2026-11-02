{{ config(materialized='view') }}

select
    rider_id,
    initcap(first_name)         as first_name,
    initcap(last_name)          as last_name,
    lower(trim(email))          as email,
    phone,
    home_city_id,
    signup_date,
    lower(rider_tier)           as rider_tier,
    is_active,
    DATE_DIFF(current_date(), signup_date, DAY) as tenure_days,
    created_at,
    updated_at,
    CURRENT_TIMESTAMP() as _loaded_at
from {{ source('raw', 'raw_riders') }}
