{% snapshot riders_snapshot %}
    {{ config(
        target_schema='snapshots',
        unique_key='rider_id',
        strategy='check',
        check_cols=['rider_tier','home_city_id','is_active'],
        invalidate_hard_deletes=True
    ) }}
    select
        rider_id, first_name, last_name, email, home_city_id,
        rider_tier, is_active, updated_at
    from {{ ref('stg_riders') }}
{% endsnapshot %}