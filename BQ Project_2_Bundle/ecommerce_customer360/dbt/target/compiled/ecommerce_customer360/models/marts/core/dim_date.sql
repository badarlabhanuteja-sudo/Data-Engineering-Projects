

with date_spine as (
    





with rawdata as (

    

    

    with p as (
        select 0 as generated_number union all select 1
    ), unioned as (

    select

    
    p0.generated_number * power(2, 0)
     + 
    
    p1.generated_number * power(2, 1)
     + 
    
    p2.generated_number * power(2, 2)
     + 
    
    p3.generated_number * power(2, 3)
     + 
    
    p4.generated_number * power(2, 4)
     + 
    
    p5.generated_number * power(2, 5)
     + 
    
    p6.generated_number * power(2, 6)
     + 
    
    p7.generated_number * power(2, 7)
     + 
    
    p8.generated_number * power(2, 8)
     + 
    
    p9.generated_number * power(2, 9)
     + 
    
    p10.generated_number * power(2, 10)
    
    
    + 1
    as generated_number

    from

    
    p as p0
     cross join 
    
    p as p1
     cross join 
    
    p as p2
     cross join 
    
    p as p3
     cross join 
    
    p as p4
     cross join 
    
    p as p5
     cross join 
    
    p as p6
     cross join 
    
    p as p7
     cross join 
    
    p as p8
     cross join 
    
    p as p9
     cross join 
    
    p as p10
    
    

    )

    select *
    from unioned
    where generated_number <= 1825
    order by generated_number



),

all_periods as (

    select (
        

        datetime_add(
            cast( cast('2022-01-01' as date) as datetime),
        interval row_number() over (order by 1) - 1 day
        )


    ) as date_day
    from rawdata

),

filtered as (

    select *
    from all_periods
    where date_day <= cast('2026-12-31' as date)

)

select * from filtered


)

select
    date_day                                                              as date_day,
    to_hex(md5(cast(coalesce(cast(date_day as string), '_dbt_utils_surrogate_key_null_') as string)))                  as date_sk,
    extract(year     from date_day)                                       as year_number,
    extract(quarter  from date_day)                                       as quarter_number,
    extract(month    from date_day)                                       as month_number,
    format_date('%B', date_day)                                           as month_name,
    extract(isoweek  from date_day)                                       as iso_week_number,
    extract(day      from date_day)                                       as day_of_month,
    format_date('%A', date_day)                                           as day_name,
    extract(dayofweek from date_day)                                      as day_of_week_number,
    case when extract(dayofweek from date_day) in (1, 7) then true
         else false end                                                   as is_weekend,
    date_trunc(date_day, month)                                           as month_start_date,
    last_day(date_day, month)                                             as month_end_date,
    date_trunc(date_day, quarter)                                         as quarter_start_date,
    last_day(date_day, quarter)                                           as quarter_end_date,
    case when date_day = current_date() then true else false end           as is_today,
    case when date_day < current_date() then true else false end           as is_past
from date_spine