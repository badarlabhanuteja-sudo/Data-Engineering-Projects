

with snap as (select * from `project-d8d88b02-3334-4b57-b24`.`snapshots`.`riders_snapshot`)

select
    to_hex(md5(cast(coalesce(cast(rider_id as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(dbt_valid_from as string), '_dbt_utils_surrogate_key_null_') as string))) as rider_sk,
    rider_id                                  as rider_business_key,
    first_name,
    last_name,
    email,
    home_city_id,
    rider_tier,
    is_active,
    dbt_valid_from                            as valid_from,
    coalesce(dbt_valid_to, '9999-12-31')      as valid_to,
    case when dbt_valid_to is null then true else false end as is_current
from snap