{{ config(materialized='view') }}

select
    category_id,
    category_name,
    parent_category_id,
    department
from {{ source('RAW', 'raw_categories') }}

