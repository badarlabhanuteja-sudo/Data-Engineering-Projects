{{ config(materialized='table') }}

select
    t.request_date,
    t.city_id,
    c.city_name,
    count(*)                                                       as trips,
    sum(case when t.is_completed then 1 else 0 end)                as completed_trips,
    sum(case when t.is_cancelled then 1 else 0 end)                as cancelled_trips,
    sum(t.final_fare)                                              as gross_revenue_inr,
    sum(t.surge_uplift_inr)                                        as surge_uplift_inr,
    avg(t.surge_multiplier)                                        as avg_surge,
    sum(case when t.is_paid_success = 1 then t.paid_amount else 0 end) as collected_revenue_inr,
    {{ safe_divide('sum(case when t.is_paid_failed = 1 then 1 else 0 end)',
                   'count(*)') }}                                  as payment_failure_rate
from {{ ref('fct_trips') }} t
join {{ ref('dim_city') }} c on t.city_id = c.city_business_key
group by 1, 2, 3
order by 1, 2

