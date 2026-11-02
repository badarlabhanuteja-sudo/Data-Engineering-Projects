

select
    order_id,
    customer_id,
    order_date,
    order_timestamp,
    order_status,
    payment_method,
    shipping_method,
    promo_code,
    CAST(coalesce(discount_amount, 0) AS NUMERIC)                   as discount_amount,
    CAST(coalesce(shipping_amount, 0) AS NUMERIC)                   as shipping_amount,
    CAST(coalesce(tax_amount, 0)      AS NUMERIC)                   as tax_amount,
    total_amount,
    currency,
    is_first_order,
    -- Net merchandise value (excluding tax + shipping)
    CAST(
        (total_amount - coalesce(tax_amount, 0) - coalesce(shipping_amount, 0)
                      + coalesce(discount_amount, 0))
    AS NUMERIC)                                                     as gross_merchandise_value,
    case when order_status = 'delivered' then true else false end    as is_completed,
    created_at,
    updated_at
from `project-d8d88b02-3334-4b57-b24`.`RAW`.`raw_orders`