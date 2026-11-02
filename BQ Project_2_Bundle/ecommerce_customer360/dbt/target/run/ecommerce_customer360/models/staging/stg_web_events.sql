

  create or replace view `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_web_events`
  OPTIONS()
  as 

with source as (
    select *
    from `project-d8d88b02-3334-4b57-b24`.`RAW`.`raw_web_events`
    where customer_id is not null
      and event_timestamp is not null
),

sessionized as (
    select
        *,
        sum(is_new_session) over (
            partition by customer_id
            order by cast(event_timestamp as timestamp)
            rows between unbounded preceding and current row
        ) as session_number
    from (
        select
            *,
            case
                when timestamp_diff(
                    cast(event_timestamp as timestamp),
                    lag(cast(event_timestamp as timestamp)) over (
                        partition by customer_id
                        order by cast(event_timestamp as timestamp)
                    ),
                    minute
                ) > 30
                or lag(event_timestamp) over (
                    partition by customer_id
                    order by cast(event_timestamp as timestamp)
                ) is null
                then 1
                else 0
            end as is_new_session
        from source
    )
)

select
    event_id,
    customer_id,

    to_hex(md5(cast(coalesce(cast(customer_id as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cast(session_number as string) as string), '_dbt_utils_surrogate_key_null_') as string))) as session_id,

    cast(event_timestamp as timestamp) as event_timestamp,

    event_type,

    cast(null as string) as device_type,

    cast(
        json_value(payload, '$.product_id')
        as string
    ) as product_id,

    cast(null as string) as page_url,
    cast(null as string) as search_query,
    cast(null as numeric) as cart_value,
    cast(null as int64) as cart_size,

    to_json_string(payload) as payload_json,

    user_agent,
    ip_address,
    referrer,

    case
        when referrer like '%google%' then 'google'
        when referrer like '%facebook%' then 'facebook'
        else 'unknown'
    end as referrer_channel

from sessionized;

