{{ config(materialized='table') }}

with snap as (select * from {{ ref('users_snapshot') }})

select
    {{ dbt_utils.generate_surrogate_key(['user_id', 'dbt_valid_from']) }} as user_sk,
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
