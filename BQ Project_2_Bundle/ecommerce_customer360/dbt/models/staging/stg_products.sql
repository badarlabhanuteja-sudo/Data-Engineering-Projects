{{ config(materialized='view') }}

select
    product_id,
    product_name,
    category_id,
    brand,
    supplier,
    unit_price,
    cost,
    round(unit_price - cost, 2)            as margin,
    round((unit_price - cost) / nullif(unit_price, 0), 4) as margin_pct,
    is_active,
    launch_date,
    created_at,
    updated_at
from {{ source('RAW', 'raw_products') }}

