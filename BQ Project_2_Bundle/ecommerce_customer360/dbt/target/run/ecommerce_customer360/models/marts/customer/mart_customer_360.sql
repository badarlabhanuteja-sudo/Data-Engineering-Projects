
  
    

    create or replace table `project-d8d88b02-3334-4b57-b24`.`MARTS`.`mart_customer_360`
      
    
    cluster by country_code, customer_tier

    
    OPTIONS()
    as (
      
with  __dbt__cte__int_customer_orders_history as (


with orders as (
    select * from `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_orders`
    where is_completed                   -- exclude cancellations / returns
),

per_customer as (
    select
        customer_id,
        count(distinct order_id)                                        as total_orders,
        count(distinct date_trunc(order_date, month))                   as active_months,
        sum(gross_merchandise_value)                                    as gross_revenue,
        sum(total_amount)                                               as total_revenue_inc_tax,
        avg(gross_merchandise_value)                                    as avg_order_value,
        min(order_date)                                                 as first_order_date,
        max(order_date)                                                 as last_order_date,
        date_diff(
            max(order_date),
            min(order_date),
            day)                                                        as customer_tenure_days,
        sum(case when promo_code is not null then 1 else 0 end)         as orders_with_promo,
        count(distinct promo_code)                                      as unique_promos_used,
        sum(discount_amount)                                            as total_discount_received
    from orders
    group by 1
),

recency as (
    select
        customer_id,
        date_diff(
            date('2025-12-31'),
            last_order_date,
            day)                                                        as days_since_last_order
    from per_customer
)

select
    p.*,
    r.days_since_last_order,
    case
        when r.days_since_last_order > 90 then true
        else false
    end as is_churned
from per_customer p
join recency r using (customer_id)
),  __dbt__cte__int_customer_email_engagement as (


with emails as (
    select * from `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_email_events`
)

select
    customer_id,
    count(*)                                                    as total_email_events,
    sum(case when event_type = 'sent'        then 1 else 0 end) as emails_sent,
    sum(case when event_type = 'open'        then 1 else 0 end) as emails_opened,
    sum(case when event_type = 'click'       then 1 else 0 end) as emails_clicked,
    sum(case when event_type = 'unsubscribe' then 1 else 0 end) as unsubscribes,
    
    case when nullif(sum(case when event_type = 'sent' then 1 else 0 end), 0) = 0 or nullif(sum(case when event_type = 'sent' then 1 else 0 end), 0) is null
         then null
         else SAFE_DIVIDE(CAST(sum(case when event_type = 'open' then 1 else 0 end) AS FLOAT64), CAST(nullif(sum(case when event_type = 'sent' then 1 else 0 end), 0) AS FLOAT64))
    end
 as open_rate,
    
    case when nullif(sum(case when event_type = 'sent' then 1 else 0 end), 0) = 0 or nullif(sum(case when event_type = 'sent' then 1 else 0 end), 0) is null
         then null
         else SAFE_DIVIDE(CAST(sum(case when event_type = 'click' then 1 else 0 end) AS FLOAT64), CAST(nullif(sum(case when event_type = 'sent' then 1 else 0 end), 0) AS FLOAT64))
    end
 as click_rate,
    max(case when event_type = 'unsubscribe' then 1 else 0 end) as is_unsubscribed,
    max(event_timestamp)                                        as last_email_event_at
from emails
group by 1
),  __dbt__cte__int_returning_vs_new_customer as (


with orders as (
    select * from `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_orders`
    where is_completed
),

with_seq as (
    select
        order_id,
        customer_id,
        order_date,
        gross_merchandise_value,
        row_number() over (partition by customer_id order by order_date asc, order_id asc) as customer_order_seq
    from orders
)

select
    customer_id,
    sum(case when customer_order_seq = 1 then 1 else 0 end) as first_orders_count,
    sum(case when customer_order_seq > 1 then 1 else 0 end) as repeat_orders_count,
    sum(case when customer_order_seq = 1 then gross_merchandise_value else 0 end) as first_order_revenue,
    sum(case when customer_order_seq > 1 then gross_merchandise_value else 0 end) as repeat_order_revenue
from with_seq
group by 1
), cust as (
    select * from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`dim_customer_scd2`
    where is_current
),
orders as (select * from __dbt__cte__int_customer_orders_history),
sessions_agg as (
    select
        customer_business_key                          as customer_id,
        count(*)                                       as total_sessions,
        sum(page_views)                                as total_page_views,
        sum(product_views)                             as total_product_views,
        sum(cart_adds)                                 as total_cart_adds,
        sum(checkouts_started)                         as total_checkouts_started,
        sum(purchases_completed)                       as total_purchases_completed,
        max(session_start)                             as last_session_at
    from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`fct_web_sessions`
    where customer_business_key is not null
    group by 1
),
email as (select * from __dbt__cte__int_customer_email_engagement),
returning as (select * from __dbt__cte__int_returning_vs_new_customer)
select
    c.customer_business_key                            as customer_id,
    c.customer_sk,
    c.email,
    c.first_name,
    c.last_name,
    c.gender,
    c.country_code,
    c.state,
    c.city,
    c.signup_channel,
    cast(c.is_email_subscriber as int64)               as is_email_subscriber,
    c.customer_tier,
    -- Order behaviour
    coalesce(o.total_orders, 0)                        as total_orders,
    coalesce(o.gross_revenue, 0)                       as gross_revenue,
    o.avg_order_value,
    o.first_order_date,
    o.last_order_date,
    o.customer_tenure_days,
    o.days_since_last_order,
    coalesce(cast(o.is_churned as int64), 1)                          as is_churned,
    coalesce(o.orders_with_promo, 0)                   as orders_with_promo,
    coalesce(o.total_discount_received, 0)             as total_discount_received,
    coalesce(r.repeat_orders_count, 0)                 as repeat_orders_count,
    -- Web engagement
    coalesce(s.total_sessions, 0)                      as web_sessions,
    coalesce(s.total_page_views, 0)                    as web_page_views,
    coalesce(s.total_product_views, 0)                 as web_product_views,
    coalesce(s.total_cart_adds, 0)                     as web_cart_adds,
    coalesce(s.total_checkouts_started, 0)             as web_checkouts_started,
    coalesce(s.total_purchases_completed, 0)           as web_purchases_completed,
    s.last_session_at,
    -- Email engagement
    coalesce(e.emails_sent, 0)                         as emails_sent,
    coalesce(e.emails_opened, 0)                       as emails_opened,
    coalesce(e.emails_clicked, 0)                      as emails_clicked,
    coalesce(cast(e.open_rate as float64), 0.0)        as email_open_rate,
    coalesce(cast(e.click_rate as float64), 0.0)       as email_click_rate,
    coalesce(cast(e.is_unsubscribed as int64), 0)                     as is_unsubscribed,
    CURRENT_TIMESTAMP()                                as _dbt_inserted_at
from cust c
left join orders        o on c.customer_business_key = o.customer_id
left join sessions_agg  s on c.customer_business_key = s.customer_id
left join email         e on c.customer_business_key = e.customer_id
left join returning     r on c.customer_business_key = r.customer_id
    );
  