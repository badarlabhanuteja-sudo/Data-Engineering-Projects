{% snapshot users_snapshot %}
    {{
        config(
            target_database=env_var('GCP_PROJECT_ID'),
            target_schema='snapshots',
            unique_key='user_id',
            strategy='check',
            check_cols=['plan_tier','country_code','is_active','profile_count','preferred_language'],
            invalidate_hard_deletes=True
        )
    }}
    select
        user_id, email, country_code, plan_tier, is_active,
        age_band, profile_count, preferred_language, updated_at
    from {{ ref('stg_users') }}
{% endsnapshot %}
