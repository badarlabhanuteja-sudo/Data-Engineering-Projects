{{ config(materialized='view') }}
select
    title_id,
    title_name,
    lower(content_type)                                   as content_type,
    series_id,
    season_number,
    episode_number,
    genres,
    SPLIT(genres, ',')[SAFE_OFFSET(0)]                    as primary_genre,
    primary_language,
    release_year,
    runtime_minutes,
    is_original,
    licence_start_date,
    licence_end_date,
    case when licence_end_date < CURRENT_DATE() then false else true end as is_currently_licensed,
    created_at,
    updated_at,
    created_at                                            as _loaded_at
from {{ source('raw', 'raw_titles') }}
