





    with grouped_expression as (
    select
        
        
    
  
( 1=1 and length(
        email
    ) >= 5 and length(
        email
    ) <= 255
)
 as expression


    from `project-d8d88b02-3334-4b57-b24`.`STAGING`.`stg_customers`
    

),
validation_errors as (

    select
        *
    from
        grouped_expression
    where
        not(expression = true)

)

select *
from validation_errors






