-- BigQuery: assert every recommendation references a valid title in dim_title
SELECT r.title_id
  FROM `streaming-media-498412`.marts.mart_user_recommendations r
 WHERE NOT EXISTS (
     SELECT 1
       FROM `streaming-media-498412`.`dbt_dev_marts`.`dim_title` t
      WHERE t.title_business_key = r.title_id
 )