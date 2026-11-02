
    
    

with all_values as (

    select
        clv_segment as value_field,
        count(*) as n_records

    from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`mart_clv_segments`
    group by clv_segment

)

select *
from all_values
where value_field not in (
    'Top','High','Mid','Low'
)


