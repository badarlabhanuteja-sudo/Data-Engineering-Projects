

  create or replace view `marketing-attribution-498615`.`raw`.`stg_ad_spend`
  OPTIONS(
      description=""""""
    )
  as 

select
    spend_id,
    spend_date,
    channel,
    campaign_id,
    spend_amount,
    impressions,
    clicks,
    
    SAFE_DIVIDE(CAST(clicks AS FLOAT64), CAST(NULLIF(impressions, 0) AS FLOAT64))
 as ctr

from `marketing-attribution-498615`.`raw`.`raw_ad_spend`;

