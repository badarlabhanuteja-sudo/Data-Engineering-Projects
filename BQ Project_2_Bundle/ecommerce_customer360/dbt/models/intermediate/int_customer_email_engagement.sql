{{ config(materialized='ephemeral') }}

with emails as (
    select * from {{ ref('stg_email_events') }}
)

select
    customer_id,
    count(*)                                                    as total_email_events,
    sum(case when event_type = 'sent'        then 1 else 0 end) as emails_sent,
    sum(case when event_type = 'open'        then 1 else 0 end) as emails_opened,
    sum(case when event_type = 'click'       then 1 else 0 end) as emails_clicked,
    sum(case when event_type = 'unsubscribe' then 1 else 0 end) as unsubscribes,
    {{ safe_divide('sum(case when event_type = \'open\' then 1 else 0 end)',
                   'nullif(sum(case when event_type = \'sent\' then 1 else 0 end), 0)') }} as open_rate,
    {{ safe_divide('sum(case when event_type = \'click\' then 1 else 0 end)',
                   'nullif(sum(case when event_type = \'sent\' then 1 else 0 end), 0)') }} as click_rate,
    max(case when event_type = 'unsubscribe' then 1 else 0 end) as is_unsubscribed,
    max(event_timestamp)                                        as last_email_event_at
from emails
group by 1
