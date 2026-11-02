

with first_orders as (
    select
        customer_id,
        DATE_TRUNC(min(order_date), MONTH) as cohort_month
    from `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_orders`
    where is_completed
    group by 1
),

orders_with_cohort as (
    select
        o.customer_id,
        f.cohort_month,
        DATE_TRUNC(o.order_date, MONTH)                                        as order_month,
        DATE_DIFF(DATE_TRUNC(o.order_date, MONTH), f.cohort_month, MONTH)      as months_since_signup,
        o.gross_merchandise_value
    from `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_orders` o
    join first_orders f using (customer_id)
    where o.is_completed
),

cohort_sizes as (
    select cohort_month, count(*) as cohort_size from first_orders group by 1
)

select
    o.cohort_month,
    o.months_since_signup,
    cs.cohort_size,
    count(distinct o.customer_id)                                                          as active_customers,
    CAST(count(distinct o.customer_id) AS FLOAT64) / nullif(cs.cohort_size, 0)            as retention_rate,
    sum(o.gross_merchandise_value)                                                         as revenue
from orders_with_cohort o
join cohort_sizes cs using (cohort_month)
group by 1, 2, 3
order by 1, 2