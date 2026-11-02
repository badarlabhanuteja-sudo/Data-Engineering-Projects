{{
    config(
        materialized='table',
        unique_key='payment_id',
        on_schema_change='append_new_columns',
        incremental_strategy='merge'
    )
}}

with src as (
    select * from {{ ref('stg_payments') }}
    {% if is_incremental() %}
        where _loaded_at >= (
            select COALESCE(MAX(_loaded_at), TIMESTAMP('1900-01-01')) from {{ this }}
        )
    {% endif %}
)

select
    s.payment_id,
    s.trip_id,
    s.payment_status,
    s.amount,
    s.payment_method,
    s.payment_timestamp,
    s.failure_reason,
    s.is_success, s.is_failed, s.is_refunded,
    s._loaded_at,
    CURRENT_TIMESTAMP() as _dbt_inserted_at
from src s
