
  
    

    create or replace table `project-d8d88b02-3334-4b57-b24`.`MARTS`.`mart_churn_features`
      
    
    

    
    OPTIONS()
    as (
      

-- =====================================================================
-- Feature store for the INTERVENTION ML churn classifier.
-- One row per customer with engineered features.
-- =====================================================================

with c360 as (
    select * from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`mart_customer_360`
    where total_orders > 0                  -- align population with baseline
),

with_derived as (
    select
        customer_id,
        customer_sk,
        is_churned                                                   as label,

        -- Demographic / signup
        case when customer_tier = 'platinum' then 4
             when customer_tier = 'gold'     then 3
             when customer_tier = 'silver'   then 2
             else 1                                          end     as tier_ordinal,
        case when is_email_subscriber = 1 then 1 else 0 end              as is_email_subscriber_int,
        case when country_code = 'IN' then 1 else 0 end              as is_country_in,
        case when signup_channel in ('google_ads', 'meta_ads', 'tiktok') then 1 else 0 end as is_paid_acquisition,

        -- Order behaviour
        total_orders,
        gross_revenue,
        avg_order_value,
        customer_tenure_days,
        days_since_last_order,
        coalesce(orders_with_promo, 0)                               as orders_with_promo,
        coalesce(total_discount_received, 0)                         as total_discount_received,
        
    case when nullif(total_orders, 0) = 0 or nullif(total_orders, 0) is null
         then null
         else SAFE_DIVIDE(CAST(coalesce(orders_with_promo, 0) AS FLOAT64), CAST(nullif(total_orders, 0) AS FLOAT64))
    end
 as promo_fraction,
        coalesce(repeat_orders_count, 0)                             as repeat_orders_count,
        
    case when nullif(total_orders, 0) = 0 or nullif(total_orders, 0) is null
         then null
         else SAFE_DIVIDE(CAST(coalesce(repeat_orders_count, 0) AS FLOAT64), CAST(nullif(total_orders, 0) AS FLOAT64))
    end
 as repeat_fraction,

        -- Web engagement
        web_sessions,
        web_page_views,
        web_product_views,
        web_cart_adds,
        web_checkouts_started,
        web_purchases_completed,
        
    case when nullif(web_product_views, 0) = 0 or nullif(web_product_views, 0) is null
         then null
         else SAFE_DIVIDE(CAST(web_cart_adds AS FLOAT64), CAST(nullif(web_product_views, 0) AS FLOAT64))
    end
 as cart_to_view_ratio,
        
    case when nullif(web_checkouts_started, 0) = 0 or nullif(web_checkouts_started, 0) is null
         then null
         else SAFE_DIVIDE(CAST(web_purchases_completed AS FLOAT64), CAST(nullif(web_checkouts_started, 0) AS FLOAT64))
    end
 as checkout_completion_rate,

        -- Email engagement
        emails_sent,
        emails_opened,
        emails_clicked,
        email_open_rate,
        email_click_rate,
        case when is_unsubscribed = 1 then 1 else 0 end                  as is_unsubscribed_int

    from c360
)

select * from with_derived
    );
  