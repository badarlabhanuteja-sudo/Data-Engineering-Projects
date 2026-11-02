{{ config(materialized='view') }}

select
    payment_id,
    trip_id,
    lower(payment_status)         as payment_status,
    coalesce(amount, 0)           as amount,
    payment_method,
    payment_timestamp,
    failure_reason,
    case when payment_status = 'success'  then true else false end as is_success,
    case when payment_status = 'failed'   then true else false end as is_failed,
    case when payment_status = 'refunded' then true else false end as is_refunded,
    CURRENT_TIMESTAMP() as _loaded_at
from {{ source('raw', 'raw_payments') }}

