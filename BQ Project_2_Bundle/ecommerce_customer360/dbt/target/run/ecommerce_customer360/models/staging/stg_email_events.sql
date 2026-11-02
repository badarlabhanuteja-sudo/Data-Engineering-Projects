

  create or replace view `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_email_events`
  OPTIONS()
  as 

select
    email_event_id,
    customer_id,
    campaign_id,
    -- Derive campaign type from campaign_id pattern: camp_<type>_<yyyymm>
    SPLIT(campaign_id, '_')[SAFE_OFFSET(1)]  as campaign_type,
    event_type,
    event_timestamp,
    subject_line
from `project-d8d88b02-3334-4b57-b24`.`RAW`.`raw_email_events`;

