CREATE OR REPLACE VIEW
  `ecommerce-customer360.streams_dt.mart_rfm_segments_mv`
AS
SELECT
  c.customer_id,
  c.customer_tier,
  DATE_DIFF(CURRENT_DATE(), MAX(o.order_date), DAY)   AS recency_days,
  APPROX_COUNT_DISTINCT(o.order_id)                   AS frequency,
  SUM(o.gross_merchandise_value)                      AS monetary_value,
  CASE
    WHEN DATE_DIFF(CURRENT_DATE(), MAX(o.order_date), DAY) <= 30
         AND APPROX_COUNT_DISTINCT(o.order_id) >= 5
         AND SUM(o.gross_merchandise_value) >= 500  THEN 'Champions'
    WHEN DATE_DIFF(CURRENT_DATE(), MAX(o.order_date), DAY) <= 90
         AND APPROX_COUNT_DISTINCT(o.order_id) >= 3  THEN 'Loyal Customers'
    WHEN DATE_DIFF(CURRENT_DATE(), MAX(o.order_date), DAY) <= 30  THEN 'Recent Customers'
    WHEN APPROX_COUNT_DISTINCT(o.order_id) >= 3  THEN 'Potential Loyalists'
    WHEN DATE_DIFF(CURRENT_DATE(), MAX(o.order_date), DAY) <= 180 THEN 'At Risk'
    WHEN DATE_DIFF(CURRENT_DATE(), MAX(o.order_date), DAY) <= 365 THEN 'Cannot Lose Them'
    ELSE 'Lost'
  END                                                  AS rfm_segment,
  CURRENT_TIMESTAMP()                                  AS last_refreshed_at
FROM `ecommerce-customer360.staging.stg_customers` c
LEFT JOIN `ecommerce-customer360.staging.stg_orders` o
  USING (customer_id)
GROUP BY 1, 2;