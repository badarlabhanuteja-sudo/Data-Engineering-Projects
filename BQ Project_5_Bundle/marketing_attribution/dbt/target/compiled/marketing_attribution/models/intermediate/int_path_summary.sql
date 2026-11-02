

-- =====================================================================
-- One row per conversion: the ordered channel sequence as a string.
-- Powers the Markov-chain attribution model.
-- =====================================================================

with paths as (
    select
        conversion_id,
        user_id,
        revenue,
        -- BigQuery uses STRING_AGG instead of LISTAGG
        STRING_AGG(channel, ' > ' ORDER BY event_timestamp ASC) as path,
        path_length
    from `marketing-attribution-498615`.`raw`.`int_conversion_paths`
    group by conversion_id, user_id, revenue, path_length
)

select
    conversion_id,
    user_id,
    revenue,
    path,
    path_length
from paths