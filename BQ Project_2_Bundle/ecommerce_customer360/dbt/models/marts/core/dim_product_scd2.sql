{{ config(materialized='table') }}

-- Sandbox workaround: use raw products instead of snapshot
select
    {{ dbt_utils.generate_surrogate_key(['product_id']) }}  as product_sk,
    product_id                          as product_business_key,
    product_name,
    category_id,
    brand,
    unit_price,
    cost,
    is_active,
    cast(created_at as date)            as valid_from,
    cast(null as date)                  as valid_to,
    true                                as is_current,
    created_at                          as dbt_updated_at
from {{ source('RAW', 'raw_products') }}

