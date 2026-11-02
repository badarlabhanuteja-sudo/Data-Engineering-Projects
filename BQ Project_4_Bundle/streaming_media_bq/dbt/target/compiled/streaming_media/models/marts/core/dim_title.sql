

select
    to_hex(md5(cast(coalesce(cast(title_id as string), '_dbt_utils_surrogate_key_null_') as string)))  as title_sk,
    title_id                              as title_business_key,
    title_name,
    content_type,
    series_id,
    season_number,
    episode_number,
    genres,
    primary_genre,
    primary_language,
    release_year,
    case
        when release_year >= 2020 then 'recent'
        when release_year >= 2010 then 'modern'
        when release_year >= 2000 then '2000s'
        else 'classic'
    end                                   as era_band,
    runtime_minutes,
    is_original,
    licence_start_date,
    licence_end_date,
    is_currently_licensed
from `streaming-media-498412`.`dbt_dev_staging`.`stg_titles`