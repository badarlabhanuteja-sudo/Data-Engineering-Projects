

  create or replace view `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_categories`
  OPTIONS()
  as 

select
    category_id,
    category_name,
    parent_category_id,
    department
from `project-d8d88b02-3334-4b57-b24`.`RAW`.`raw_categories`;

