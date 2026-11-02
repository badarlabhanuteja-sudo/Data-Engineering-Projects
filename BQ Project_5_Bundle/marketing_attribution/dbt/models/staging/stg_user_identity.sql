{{ config(materialized='view') }}

select
    user_id,
    canonical_user_id,
    email_hash,
    first_seen_at,
    last_seen_at

from {{ source('raw', 'raw_user_identity') }}
