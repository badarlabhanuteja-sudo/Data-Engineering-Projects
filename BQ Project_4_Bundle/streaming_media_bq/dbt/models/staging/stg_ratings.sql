{{ config(materialized='view') }}
select
    rating_id,
    user_id,
    title_id,
    rating,
    rated_at,
    DATE(rated_at)                as rated_date,
    (rating - 0.5) / 4.5          as rating_normalized,
    rated_at                      as _loaded_at
from {{ source('raw', 'raw_ratings') }}
