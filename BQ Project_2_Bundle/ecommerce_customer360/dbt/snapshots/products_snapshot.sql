{% snapshot products_snapshot %}

{{
config(
target_database=var('gcp_project', 'project-d8d88b02-3334-4b57-b24'),
target_schema='SNAPSHOTS',
unique_key='product_id',
strategy='check',
check_cols=[
'unit_price',
'cost',
'brand',
'supplier',
'is_active',
'category_id'
],
hard_deletes='invalidate'
)
}}

select
product_id,
product_name,
category_id,
brand,
supplier,
unit_price,
cost,
is_active,
launch_date,
cast(updated_at as timestamp) as updated_at
from {{ ref('stg_products') }}

{% endsnapshot %}