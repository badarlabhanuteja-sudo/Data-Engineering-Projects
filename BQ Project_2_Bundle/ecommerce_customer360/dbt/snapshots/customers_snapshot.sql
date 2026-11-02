{{
    config(
        target_project=env_var('BIGQUERY_PROJECT', 'project-d8d88b02-3334-4b57-b24'),
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='check',
        check_cols=['customer_tier', 'is_email_subscriber', 'city', 'country_code'],
        invalidate_hard_deletes=True
    )
}}

select
    customer_id,
    email,
    first_name,
    last_name,
    gender,
    country_code,
    state,
    city,
    postal_code,
    signup_channel,
    is_email_subscriber,
    customer_tier,
    updated_at
from {{ ref('stg_customers') }}
