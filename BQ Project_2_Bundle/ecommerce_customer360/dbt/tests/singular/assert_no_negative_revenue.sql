-- Returns rows that violate the assertion. Empty result = pass.
select customer_id, gross_revenue
  from {{ ref('mart_customer_360') }}
 where gross_revenue < 0
