{{ config(materialized='view') }}

select
order_item_id,
order_id,
product_id,
quantity,
unit_price,
line_total,
created_at
from {{ source('RAW', 'raw_order_items') }}