{{ config(materialized='view') }}

select
    spend_id,
    spend_date,
    channel,
    campaign_id,
    spend_amount,
    impressions,
    clicks,
    {{ safe_divide('clicks', 'NULLIF(impressions, 0)') }} as ctr

from {{ source('raw', 'raw_ad_spend') }}
