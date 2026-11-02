CREATE OR REPLACE VIEW
`ecommerce-customer360.streams_dt.mart_churn_features_mv`
AS
SELECT
  c.customer_id,
  c.customer_tier,
  0 AS days_since_signup,
  COALESCE(o.total_orders, 0) AS total_orders,
  COALESCE(o.total_revenue, 0) AS total_revenue,
  COALESCE(o.avg_order_value, 0) AS avg_order_value,
  COALESCE(o.recency_days, 999) AS recency_days,
  COALESCE(w.total_sessions, 0) AS total_sessions,
  0 AS avg_session_duration_sec,
  COALESCE(e.email_open_rate, 0) AS email_open_rate,
  0 AS actual_churn,
  CURRENT_TIMESTAMP() AS last_refreshed_at
FROM `ecommerce-customer360.staging.stg_customers` c

LEFT JOIN (
  SELECT 
    customer_id,
    APPROX_COUNT_DISTINCT(order_id) AS total_orders,
    SUM(gross_merchandise_value) AS total_revenue,
    AVG(gross_merchandise_value) AS avg_order_value,
    DATE_DIFF(CURRENT_DATE(), MAX(order_date), DAY) AS recency_days
  FROM `ecommerce-customer360.staging.stg_orders`
  GROUP BY customer_id
) o USING (customer_id)

LEFT JOIN (
  SELECT 
    customer_id,
    APPROX_COUNT_DISTINCT(session_id) AS total_sessions
  FROM `ecommerce-customer360.staging.stg_web_events`
  GROUP BY customer_id
) w USING (customer_id)

LEFT JOIN (
  SELECT 
    customer_id,
    SAFE_DIVIDE(COUNTIF(event_type = 'open'), COUNT(*)) AS email_open_rate
  FROM `ecommerce-customer360.staging.stg_email_events`
  GROUP BY customer_id
) e USING (customer_id);

