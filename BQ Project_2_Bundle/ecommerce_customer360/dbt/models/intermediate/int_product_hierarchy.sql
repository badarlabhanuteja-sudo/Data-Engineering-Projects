{{ config(materialized='ephemeral') }}

with products  as (select * from {{ ref('stg_products') }}),
     categories as (select * from {{ ref('stg_categories') }})

select
    p.product_id,
    p.product_name,
    p.brand,
    p.supplier,
    p.unit_price,
    p.cost,
    p.margin,
    p.margin_pct,
    p.is_active,
    p.launch_date,
    -- Leaf category
    c.category_id                       as category_id,
    c.category_name                     as category_name,
    -- Parent category (if any)
    parent.category_id                  as parent_category_id,
    parent.category_name                as parent_category_name,
    coalesce(parent.department, c.department) as department
from products p
left join categories c       on p.category_id = c.category_id
left join categories parent  on c.parent_category_id = parent.category_id
