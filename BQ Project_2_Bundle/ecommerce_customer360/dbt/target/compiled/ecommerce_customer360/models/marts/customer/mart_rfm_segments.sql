

-- =====================================================================
-- BASELINE classifier for the empirical study.
-- Hughes (1996) quintile-binned RFM segmentation.
-- =====================================================================

with c360 as (
    select * from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`mart_customer_360`
    where total_orders > 0                       -- exclude never-purchasers
),

scored as (
    select
        customer_id,
        customer_sk,
        gross_revenue,
        total_orders,
        days_since_last_order,
        is_churned,

        
    
    
        ntile(5) over (order by days_since_last_order desc)
    
 as r_score,
        
    
    
        ntile(5) over (order by total_orders)
    
 as f_score,
        
    
    
        ntile(5) over (order by gross_revenue)
    
 as m_score
    from c360
)

select
    customer_id,
    customer_sk,
    r_score,
    f_score,
    m_score,
    (r_score * 100) + (f_score * 10) + m_score          as rfm_score_combined,
    
    case
        when r_score >= 4 and f_score >= 4 and m_score >= 4 then 'Champions'
        when r_score >= 3 and f_score >= 3 and m_score >= 3 then 'Loyal'
        when r_score >= 4 and f_score <= 2                       then 'Potential Loyalists'
        when r_score >= 4 and f_score = 3                        then 'New Customers'
        when r_score = 3 and f_score <= 2                        then 'Promising'
        when r_score = 2 and f_score >= 4                        then 'At Risk'
        when r_score <= 2 and f_score >= 4 and m_score >= 4 then 'Cannot Lose Them'
        when r_score <= 2 and f_score <= 2 and m_score >= 3 then 'Hibernating'
        when r_score = 1 and f_score = 1                         then 'Lost'
        else 'About to Sleep'
    end
 as rfm_segment,

    -- BASELINE churn prediction: classed as "at risk" if R is in bottom 2 quintiles
    case when r_score <= 2 then true else false end     as predicted_churn_baseline,
    -- A simple risk score: inverse of recency quintile
    (6 - r_score) / 5.0                                 as predicted_churn_score_baseline,

    is_churned                                          as actual_churn,
    gross_revenue,
    total_orders,
    days_since_last_order,
    CURRENT_TIMESTAMP()                                 as _dbt_inserted_at
from scored