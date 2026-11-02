-- Total revenue must be conserved across all 5 attribution models.
-- (Each model redistributes the same revenue universe; sums should be ≈ equal.)

with totals as (
    select model, SUM(attributed_revenue) as total_attributed
      from `marketing-attribution-498615`.`analytics`.`mart_channel_roas_compared`
     group by 1
),
expected as (
    select SUM(revenue) as expected_total from `marketing-attribution-498615`.`raw`.`stg_conversions`
)
select t.model, t.total_attributed, e.expected_total,
       ABS(t.total_attributed - e.expected_total) as delta
  from totals t
 cross join expected e
 where ABS(t.total_attributed - e.expected_total) > e.expected_total * 0.20