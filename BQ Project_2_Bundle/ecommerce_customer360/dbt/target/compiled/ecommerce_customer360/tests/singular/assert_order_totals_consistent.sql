-- Asserts that for each order, the sum of order_items.line_total is within 5%
-- of gross_merchandise_value on the order header (allows for tax/shipping rounding).
-- No Snowflake-specific syntax; GREATEST is standard SQL supported by BigQuery.
 
with order_totals as (
    select order_id, gross_merchandise_value
      from `ecommerce-customer360`.`marts`.`fct_orders`
),
item_totals as (
    select order_id, sum(line_total) as items_sum
      from `ecommerce-customer360`.`marts`.`fct_order_items`
     group by 1
)
select
    o.order_id,
    o.gross_merchandise_value,
    i.items_sum,
    abs(o.gross_merchandise_value - i.items_sum) as delta
  from order_totals o
  left join item_totals i using (order_id)
 where i.items_sum is null
    or abs(o.gross_merchandise_value - i.items_sum)
       > greatest(0.01, o.gross_merchandise_value * 0.05)