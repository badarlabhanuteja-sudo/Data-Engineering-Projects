

  create or replace view `marketing-attribution-498615`.`raw`.`stg_user_identity`
  OPTIONS(
      description=""""""
    )
  as 

select
    user_id,
    canonical_user_id,
    email_hash,
    first_seen_at,
    last_seen_at

from `marketing-attribution-498615`.`raw`.`raw_user_identity`;

