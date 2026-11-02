{{ config(materialized='table') }}

-- Sandbox workaround: use raw customers instead of snapshot
select
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }}  as customer_sk,
    customer_id                                   as customer_business_key,
    email,
    first_name,
    last_name,
    gender,
    country                                       as country_code,
    country,
    state_or_region                               as state,
    city,
    customer_tier,
    signup_channel,
    is_email_subscriber,
    cast(created_at as timestamp)                 as valid_from,
    cast(null as timestamp)                       as valid_to,
    true                                          as is_current,
    created_at                                    as dbt_updated_at
from {{ source('RAW', 'raw_customers') }}

