-- Returns rows that violate the assertion. Empty result = pass.
select customer_id, gross_revenue
  from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`mart_customer_360`
 where gross_revenue < 0