{{
    config(
        materialized='table'
    )
}}
with src as (
    select * from {{ ref('int_session_engagement') }}
)
select
    *,
    {{ dbt_utils.generate_surrogate_key(['user_id']) }}                   as user_sk,
    {{ dbt_utils.generate_surrogate_key(['DATE(session_start)']) }}       as date_sk,
    CURRENT_TIMESTAMP()                                                    as _dbt_inserted_at
from src
