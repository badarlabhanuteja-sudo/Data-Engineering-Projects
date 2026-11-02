{% snapshot drivers_snapshot %}
    {{ config(
        target_schema='snapshots',
        unique_key='driver_id',
        strategy='check',
        check_cols=['vehicle_type','rating','status','home_city_id','is_active'],
        invalidate_hard_deletes=True
    ) }}
    select
        driver_id, first_name, last_name, vehicle_type, vehicle_number,
        rating, home_city_id, status, is_active, updated_at
    from {{ ref('stg_drivers') }}
{% endsnapshot %}