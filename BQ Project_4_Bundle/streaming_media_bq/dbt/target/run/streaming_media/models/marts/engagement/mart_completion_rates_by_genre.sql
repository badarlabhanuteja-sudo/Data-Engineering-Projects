
  
    

    create or replace table `streaming-media-498412`.`dbt_dev_marts`.`mart_completion_rates_by_genre`
      
    
    

    
    OPTIONS(
      description=""""""
    )
    as (
      

with v as (select * from `streaming-media-498412`.`dbt_dev_staging`.`stg_view_events`),
     t as (select * from `streaming-media-498412`.`dbt_dev_staging`.`stg_titles`)

select
    t.primary_genre,
    t.content_type,
    count(distinct v.user_id)                                   as unique_viewers,
    count(*)                                                    as total_events,
    sum(case when v.event_type = 'play'     then 1 else 0 end)  as plays,
    sum(case when v.event_type = 'complete' then 1 else 0 end)  as completes,
    sum(case when v.event_type = 'abandon'  then 1 else 0 end)  as abandons,
    
    CASE WHEN NULLIF(sum(case when v.event_type = 'play' then 1 else 0 end), 0) = 0 OR NULLIF(sum(case when v.event_type = 'play' then 1 else 0 end), 0) IS NULL
         THEN NULL
         ELSE SAFE_DIVIDE(CAST(sum(case when v.event_type = 'complete' then 1 else 0 end) AS FLOAT64), CAST(NULLIF(sum(case when v.event_type = 'play' then 1 else 0 end), 0) AS FLOAT64))
    END
 as completion_rate,
    
    CASE WHEN NULLIF(sum(case when v.event_type = 'play' then 1 else 0 end), 0) = 0 OR NULLIF(sum(case when v.event_type = 'play' then 1 else 0 end), 0) IS NULL
         THEN NULL
         ELSE SAFE_DIVIDE(CAST(sum(case when v.event_type = 'abandon'  then 1 else 0 end) AS FLOAT64), CAST(NULLIF(sum(case when v.event_type = 'play' then 1 else 0 end), 0) AS FLOAT64))
    END
 as abandon_rate
from t
left join v on t.title_id = v.title_id
group by 1, 2
order by 4 desc nulls last
    );
  