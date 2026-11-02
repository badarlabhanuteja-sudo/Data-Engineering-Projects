

  create or replace view `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_order_items`
  OPTIONS()
  as 

select
order_item_id,
order_id,
product_id,
quantity,
unit_price,
line_total,
created_at
from `project-d8d88b02-3334-4b57-b24`.`RAW`.`raw_order_items`;

