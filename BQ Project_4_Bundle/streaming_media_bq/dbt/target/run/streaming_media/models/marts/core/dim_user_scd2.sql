
  
    

    create or replace table `streaming-media-498412`.`dbt_dev_marts`.`dim_user_scd2`
      
    
    

    
    OPTIONS(
      description=""""""
    )
    as (
      

with snap as (select * from `streaming-media-498412`.`snapshots`.`users_snapshot`)

select
    to_hex(md5(cast(coalesce(cast(user_id as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(dbt_valid_from as string), '_dbt_utils_surrogate_key_null_') as string))) as user_sk,
    user_id                                   as user_business_key,
    email,
    country_code,
    plan_tier,
    is_active,
    age_band,
    profile_count,
    preferred_language,
    dbt_valid_from                            as valid_from,
    -- BigQuery: COALESCE with TIMESTAMP literal
    coalesce(dbt_valid_to,
             CAST('9999-12-31' AS TIMESTAMP)) as valid_to,
    case when dbt_valid_to is null then true else false end as is_current
from snap
    );
  