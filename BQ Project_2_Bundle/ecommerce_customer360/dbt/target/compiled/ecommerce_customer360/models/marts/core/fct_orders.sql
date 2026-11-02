

with stg as (
select *
from `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_orders`


    where updated_at >= (
        select coalesce(
            max(updated_at),
            datetime('1900-01-01')
        )
        from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`fct_orders`
    )



),

cust as (
select
customer_sk,
customer_business_key,
valid_from,
valid_to
from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`dim_customer_scd2`
)

select
s.order_id,
c.customer_sk,
s.customer_id as customer_business_key,
s.order_date,

to_hex(md5(cast(coalesce(cast(s.order_date as string), '_dbt_utils_surrogate_key_null_') as string))) as date_sk,

s.order_timestamp,
s.order_status,
s.payment_method,
s.shipping_method,
s.promo_code,
s.discount_amount,
s.shipping_amount,
s.tax_amount,
s.total_amount,
s.gross_merchandise_value,
s.currency,
s.is_first_order,
s.is_completed,

s.created_at,
s.updated_at,

current_timestamp() as _dbt_inserted_at


from stg s

left join cust c
on s.customer_id = c.customer_business_key
and cast(s.order_date as timestamp) >= c.valid_from
and cast(s.order_date as timestamp) < coalesce(
    cast(c.valid_to as timestamp),
    cast('9999-12-31' as timestamp)
)