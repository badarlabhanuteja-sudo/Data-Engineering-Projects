-- =====================================================================
-- 02_setup_raw_tables.sql
-- Creates the RAW (bronze) tables that the data generator loads into.
-- These mirror the source-system schemas exactly.
--
-- Notes:
--   • TIMESTAMP_NTZ  → DATETIME   (no timezone)
--   • TIMESTAMP_LTZ  → TIMESTAMP  (UTC)
--   • NUMBER(38,0)   → INT64
--   • NUMBER(12,2)   → NUMERIC(12,2)
--   • BOOLEAN        → BOOL
--   • VARIANT        → JSON
--   • _loaded_at defaults to CURRENT_TIMESTAMP() on insert
-- =====================================================================

-- ---------------------------------------------------------------------
-- raw_customers
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `RAW.raw_customers` (
    customer_id          INT64          NOT NULL,
    email                STRING,
    first_name           STRING,
    last_name            STRING,
    gender               STRING,
    date_of_birth        DATE,
    country              STRING,
    state_or_region      STRING,
    city                 STRING,
    postal_code          STRING,
    signup_date          DATE,
    signup_channel       STRING,
    is_email_subscriber  BOOL,
    customer_tier        STRING,
    created_at           DATETIME,
    updated_at           DATETIME,
    _loaded_at           TIMESTAMP  DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------
-- raw_products
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `RAW.raw_products` (
    product_id     INT64           NOT NULL,
    product_name   STRING,
    category_id    INT64,
    brand          STRING,
    supplier       STRING,
    unit_price     NUMERIC(12, 2),
    cost           NUMERIC(12, 2),
    is_active      BOOL,
    launch_date    DATE,
    created_at     DATETIME,
    updated_at     DATETIME,
    _loaded_at     TIMESTAMP  DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------
-- raw_categories
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `RAW.raw_categories` (
    category_id        INT64   NOT NULL,
    category_name      STRING,
    parent_category_id INT64,
    department         STRING,
    _loaded_at         TIMESTAMP  DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------
-- raw_orders
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `RAW.raw_orders` (
    order_id         INT64           NOT NULL,
    customer_id      INT64,
    order_date       DATE,
    order_timestamp  DATETIME,
    order_status     STRING,
    payment_method   STRING,
    shipping_method  STRING,
    promo_code       STRING,
    discount_amount  NUMERIC(12, 2),
    shipping_amount  NUMERIC(12, 2),
    tax_amount       NUMERIC(12, 2),
    total_amount     NUMERIC(12, 2),
    currency         STRING,
    is_first_order   BOOL,
    created_at       DATETIME,
    updated_at       DATETIME,
    _loaded_at       TIMESTAMP  DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------
-- raw_order_items
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `RAW.raw_order_items` (
    order_item_id  INT64           NOT NULL,
    order_id       INT64,
    product_id     INT64,
    quantity       INT64,
    unit_price     NUMERIC(12, 2),
    line_total     NUMERIC(12, 2),
    discount_pct   NUMERIC(5, 2),
    created_at     DATETIME,
    _loaded_at     TIMESTAMP  DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------
-- raw_web_events  (JSON for nested event payload)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `RAW.raw_web_events` (
    event_id         STRING    NOT NULL,
    customer_id      INT64,
    session_id       STRING,
    event_timestamp  DATETIME,
    event_type       STRING,
    payload          JSON,
    user_agent       STRING,
    ip_address       STRING,
    referrer         STRING,
    _loaded_at       TIMESTAMP  DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------
-- raw_email_events
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `RAW.raw_email_events` (
    email_event_id  STRING   NOT NULL,
    customer_id     INT64,
    campaign_id     STRING,
    event_type      STRING,
    event_timestamp DATETIME,
    subject_line    STRING,
    _loaded_at      TIMESTAMP  DEFAULT CURRENT_TIMESTAMP()
);

-- Verify
SELECT table_name, creation_time
  FROM `RAW.INFORMATION_SCHEMA.TABLES`
 ORDER BY table_name;
