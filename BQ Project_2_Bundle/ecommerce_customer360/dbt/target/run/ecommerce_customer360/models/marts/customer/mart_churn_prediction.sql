
  
    

    create or replace table `project-d8d88b02-3334-4b57-b24`.`MARTS`.`mart_churn_prediction`
      
    
    

    
    OPTIONS()
    as (
      

with features as (
    select
        customer_id,
        customer_sk,
        label                                           as actual_churn,
        tier_ordinal,
        is_email_subscriber_int,
        is_country_in,
        is_paid_acquisition,
        total_orders,
        gross_revenue,
        coalesce(avg_order_value, 0.0)                  as avg_order_value,
        customer_tenure_days,
        coalesce(days_since_last_order, 0)              as days_since_last_order,
        orders_with_promo,
        total_discount_received,
        coalesce(promo_fraction, 0.0)                   as promo_fraction,
        repeat_orders_count,
        coalesce(repeat_fraction, 0.0)                  as repeat_fraction,
        web_sessions,
        web_page_views,
        web_product_views,
        web_cart_adds,
        web_checkouts_started,
        web_purchases_completed,
        coalesce(cart_to_view_ratio, 0.0)               as cart_to_view_ratio,
        coalesce(checkout_completion_rate, 0.0)         as checkout_completion_rate,
        emails_sent,
        emails_opened,
        emails_clicked,
        coalesce(email_open_rate, 0.0)                  as email_open_rate,
        coalesce(email_click_rate, 0.0)                 as email_click_rate,
        is_unsubscribed_int
    from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`mart_churn_features`
),

predictions as (
    select
        predicted_label                             as predicted_churn_ml,
        (
            select prob
            from unnest(predicted_label_probs)
            where label = 1
        )                                           as predicted_churn_score_ml,
        row_number() over ()                        as rn
    from ml.predict(
        MODEL `project-d8d88b02-3334-4b57-b24.marts.churn_xgb`,
        (select * except(customer_id, customer_sk, actual_churn) from features)
    )
),

features_numbered as (
    select *, row_number() over () as rn
    from features
)

select
    f.customer_id,
    f.customer_sk,
    p.predicted_churn_score_ml,
    cast(p.predicted_churn_ml as bool)              as predicted_churn_ml,
    f.actual_churn,
    current_timestamp()                             as _dbt_inserted_at
from features_numbered f
left join predictions p using (rn)
    );
  