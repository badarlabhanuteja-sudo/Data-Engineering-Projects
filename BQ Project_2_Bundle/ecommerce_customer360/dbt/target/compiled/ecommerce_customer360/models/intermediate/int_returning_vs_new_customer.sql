

with orders as (
    select * from `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_orders`
    where is_completed
),

with_seq as (
    select
        order_id,
        customer_id,
        order_date,
        gross_merchandise_value,
        row_number() over (partition by customer_id order by order_date asc, order_id asc) as customer_order_seq
    from orders
)

select
    customer_id,
    sum(case when customer_order_seq = 1 then 1 else 0 end) as first_orders_count,
    sum(case when customer_order_seq > 1 then 1 else 0 end) as repeat_orders_count,
    sum(case when customer_order_seq = 1 then gross_merchandise_value else 0 end) as first_order_revenue,
    sum(case when customer_order_seq > 1 then gross_merchandise_value else 0 end) as repeat_order_revenue
from with_seq
group by 1