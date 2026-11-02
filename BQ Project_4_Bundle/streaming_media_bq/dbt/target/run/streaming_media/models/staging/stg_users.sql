

  create or replace view `streaming-media-498412`.`dbt_dev_staging`.`stg_users`
  OPTIONS(
      description=""""""
    )
  as 
select
    user_id,
    lower(trim(email))                                    as email,
    upper(country)                                        as country_code,
    lower(plan_tier)                                      as plan_tier,
    signup_date,
    is_active,
    age_band,
    profile_count,
    preferred_language,
    DATE_DIFF(CURRENT_DATE(), signup_date, DAY)           as tenure_days,
    created_at,
    updated_at,
    created_at                                            as _loaded_at
from `streaming-media-498412`.`raw`.`raw_users`;

