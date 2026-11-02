

  create or replace view `marketing-attribution-498615`.`raw`.`stg_conversions`
  OPTIONS(
      description=""""""
    )
  as 

select
    conversion_id,
    user_id,
    conversion_type,
    revenue,
    conversion_timestamp,
    DATE(conversion_timestamp) as conversion_date

from `marketing-attribution-498615`.`raw`.`raw_conversions`;

