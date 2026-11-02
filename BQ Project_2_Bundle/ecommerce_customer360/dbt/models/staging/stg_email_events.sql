{{ config(materialized='view') }}

select
    email_event_id,
    customer_id,
    campaign_id,
    -- Derive campaign type from campaign_id pattern: camp_<type>_<yyyymm>
    SPLIT(campaign_id, '_')[SAFE_OFFSET(1)]  as campaign_type,
    event_type,
    event_timestamp,
    subject_line
from {{ source('RAW', 'raw_email_events') }}

