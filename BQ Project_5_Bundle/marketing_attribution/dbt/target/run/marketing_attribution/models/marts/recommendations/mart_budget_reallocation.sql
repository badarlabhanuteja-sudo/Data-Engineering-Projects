
  
    

    create or replace table `marketing-attribution-498615`.`analytics`.`mart_budget_reallocation`
      
    
    

    
    OPTIONS(
      description="""Recommended budget per channel, by attribution model"""
    )
    as (
      

with cmp as (
    select * from `marketing-attribution-498615`.`analytics`.`mart_channel_roas_compared`
),
spend_total as (
    select SUM(total_spend) as budget from cmp
),
realloc as (
    select
        c.model,
        c.channel,
        c.total_spend                                                          as current_spend,
        c.attributed_share,
        ROUND(c.attributed_share * (select budget from spend_total), 2)        as recommended_spend,
        ROUND(c.attributed_share * (select budget from spend_total) - c.total_spend, 2)
                                                                               as recommended_change,
        case
            when c.total_spend = 0 then null
            else (c.attributed_share * (select budget from spend_total) - c.total_spend)
                 / c.total_spend
        end                                                                    as recommended_change_pct
    from cmp c
    where c.total_spend is not null
)
select *
from realloc
order by model, recommended_change_pct desc nulls last
    );
  