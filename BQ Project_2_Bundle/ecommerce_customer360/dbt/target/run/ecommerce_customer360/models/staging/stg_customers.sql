

  create or replace view `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_customers`
  OPTIONS()
  as 

with src as (
    select * from `project-d8d88b02-3334-4b57-b24`.`RAW`.`raw_customers`
)
select
    customer_id,
    lower(trim(email))                                              as email,
    initcap(first_name)                                             as first_name,
    initcap(last_name)                                              as last_name,
    gender,
    date_of_birth                                                   as dob,
    upper(country)                                                  as country_code,
    state_or_region                                                 as state,
    initcap(city)                                                   as city,
    postal_code,
    signup_date,
    signup_channel,
    is_email_subscriber,
    customer_tier,
    created_at,
    updated_at
from src;

