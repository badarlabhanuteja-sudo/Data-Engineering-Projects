

with stg as (

select *
from `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_order_items`


    where created_at >= (
        select coalesce(
            max(created_at),
            datetime('1900-01-01 00:00:00')
        )
        from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`fct_order_items`
    )



),

orders as (

select
    order_id,
    customer_sk,
    order_date
from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`fct_orders`


),

products as (

select
    product_sk,
    product_business_key
from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`dim_product_scd2`


)

select
s.order_item_id,
s.order_id,

o.customer_sk,

p.product_sk,

s.product_id as product_business_key,

o.order_date,

s.quantity,
s.unit_price,
s.line_total,

s.created_at,

current_timestamp() as _dbt_inserted_at


from stg s

left join orders o
on s.order_id = o.order_id

left join products p
on s.product_id = p.product_business_key