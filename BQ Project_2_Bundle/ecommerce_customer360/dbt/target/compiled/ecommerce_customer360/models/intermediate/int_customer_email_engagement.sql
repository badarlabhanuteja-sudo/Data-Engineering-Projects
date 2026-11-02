

with emails as (
    select * from `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_email_events`
)

select
    customer_id,
    count(*)                                                    as total_email_events,
    sum(case when event_type = 'sent'        then 1 else 0 end) as emails_sent,
    sum(case when event_type = 'open'        then 1 else 0 end) as emails_opened,
    sum(case when event_type = 'click'       then 1 else 0 end) as emails_clicked,
    sum(case when event_type = 'unsubscribe' then 1 else 0 end) as unsubscribes,
    
    case when nullif(sum(case when event_type = 'sent' then 1 else 0 end), 0) = 0 or nullif(sum(case when event_type = 'sent' then 1 else 0 end), 0) is null
         then null
         else SAFE_DIVIDE(CAST(sum(case when event_type = 'open' then 1 else 0 end) AS FLOAT64), CAST(nullif(sum(case when event_type = 'sent' then 1 else 0 end), 0) AS FLOAT64))
    end
 as open_rate,
    
    case when nullif(sum(case when event_type = 'sent' then 1 else 0 end), 0) = 0 or nullif(sum(case when event_type = 'sent' then 1 else 0 end), 0) is null
         then null
         else SAFE_DIVIDE(CAST(sum(case when event_type = 'click' then 1 else 0 end) AS FLOAT64), CAST(nullif(sum(case when event_type = 'sent' then 1 else 0 end), 0) AS FLOAT64))
    end
 as click_rate,
    max(case when event_type = 'unsubscribe' then 1 else 0 end) as is_unsubscribed,
    max(event_timestamp)                                        as last_email_event_at
from emails
group by 1