

-- Sandbox workaround: use raw customers instead of snapshot
select
    to_hex(md5(cast(coalesce(cast(customer_id as string), '_dbt_utils_surrogate_key_null_') as string)))  as customer_sk,
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
from `project-d8d88b02-3334-4b57-b24`.`RAW`.`raw_customers`