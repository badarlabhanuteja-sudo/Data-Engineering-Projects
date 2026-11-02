CREATE OR REPLACE VIEW 
`ecommerce-customer360.streams_dt.mart_customer_360_mv`
AS
SELECT
  c.customer_id,
  c.customer_tier,
  0 AS days_since_signup,
  0 AS is_churned,
  COALESCE(o.total_orders, 0) AS total_orders,
  COALESCE(o.total_revenue, 0) AS gross_revenue,
  COALESCE(o.recency_days, 999) AS recency_days,
  r.rfm_segment,
  CURRENT_TIMESTAMP() AS last_refreshed_at
FROM `ecommerce-customer360.staging.stg_customers` c
LEFT JOIN (
  SELECT customer_id,
    APPROX_COUNT_DISTINCT(order_id) AS total_orders,
    SUM(gross_merchandise_value) AS total_revenue,
    DATE_DIFF(CURRENT_DATE(), MAX(order_date), DAY) AS recency_days
  FROM `ecommerce-customer360.staging.stg_orders`
  GROUP BY customer_id
) o USING (customer_id)
LEFT JOIN `ecommerce-customer360.streams_dt.mart_rfm_segments_mv` r
USING (customer_id);
