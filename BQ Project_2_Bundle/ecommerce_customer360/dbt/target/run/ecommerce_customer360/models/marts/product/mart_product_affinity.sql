
  
    

    create or replace table `project-d8d88b02-3334-4b57-b24`.`MARTS`.`mart_product_affinity`
      
    
    

    
    OPTIONS()
    as (
      

with items as (
    select order_id, product_business_key as product_id
    from `project-d8d88b02-3334-4b57-b24`.`MARTS`.`fct_order_items`
),

-- Pairs of products that co-occur in the same order
pairs as (
    select
        a.product_id as anchor_product_id,
        b.product_id as paired_product_id,
        count(distinct a.order_id) as co_occurrences
    from items a
    join items b on a.order_id = b.order_id
                 and a.product_id < b.product_id
    group by 1, 2
    having count(distinct a.order_id) >= 5         -- noise filter
),

product_orders as (
    select product_id, count(distinct order_id) as orders_with_product
    from items
    group by 1
),

total_orders as (
    select count(distinct order_id) as total_orders from items
)

select
    p.anchor_product_id,
    p.paired_product_id,
    p.co_occurrences,
    a.orders_with_product as anchor_orders,
    b.orders_with_product as paired_orders,
    t.total_orders        as total_orders,
    -- Support, confidence, lift
    CAST(p.co_occurrences AS FLOAT64) / nullif(t.total_orders, 0)                          as support,
    CAST(p.co_occurrences AS FLOAT64) / nullif(a.orders_with_product, 0)                   as confidence,
    (CAST(p.co_occurrences AS FLOAT64) / nullif(a.orders_with_product, 0))
        / nullif(CAST(b.orders_with_product AS FLOAT64) / nullif(t.total_orders, 0), 0)    as lift
from pairs p
join product_orders a on p.anchor_product_id = a.product_id
join product_orders b on p.paired_product_id = b.product_id
cross join total_orders t
order by lift desc nulls last
    );
  