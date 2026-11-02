-- =====================================================================
-- 02_setup_raw_tables.sql
-- One RAW table per source channel + ad spend + conversions + identity.
-- Run in BigQuery Console against your project.
-- Replace YOUR_PROJECT with your actual GCP project ID.
-- =====================================================================

-- =====================================================================
-- Per-channel touchpoint tables
-- =====================================================================

CREATE TABLE IF NOT EXISTS `YOUR_PROJECT.raw.raw_google_ads` (
    google_event_id    STRING        NOT NULL,
    user_id            STRING,
    google_click_id    STRING,
    campaign_id        STRING,
    ad_group_id        STRING,
    creative_id        STRING,
    keyword            STRING,
    event_type         STRING,
    event_timestamp    TIMESTAMP,
    cost               NUMERIC,
    _loaded_at         TIMESTAMP     DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS `YOUR_PROJECT.raw.raw_meta_ads` (
    meta_event_id      STRING        NOT NULL,
    user_id            STRING,
    fbclid             STRING,
    campaign_id        STRING,
    ad_set_id          STRING,
    ad_id              STRING,
    placement          STRING,
    event_type         STRING,
    event_timestamp    TIMESTAMP,
    cost               NUMERIC,
    _loaded_at         TIMESTAMP     DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS `YOUR_PROJECT.raw.raw_tiktok_ads` (
    tiktok_event_id    STRING        NOT NULL,
    user_id            STRING,
    ttclid             STRING,
    campaign_id        STRING,
    ad_group_id        STRING,
    creative_id        STRING,
    event_type         STRING,
    event_timestamp    TIMESTAMP,
    cost               NUMERIC,
    _loaded_at         TIMESTAMP     DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS `YOUR_PROJECT.raw.raw_email_events` (
    email_event_id     STRING        NOT NULL,
    user_id            STRING,
    campaign_id        STRING,
    event_type         STRING,
    event_timestamp    TIMESTAMP,
    subject_line       STRING,
    _loaded_at         TIMESTAMP     DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS `YOUR_PROJECT.raw.raw_web_events` (
    event_id           STRING        NOT NULL,
    user_id            STRING,
    session_id         STRING,
    event_type         STRING,
    page_url           STRING,
    referrer           STRING,
    utm_source         STRING,
    utm_medium         STRING,
    utm_campaign       STRING,
    event_timestamp    TIMESTAMP,
    payload            JSON,
    _loaded_at         TIMESTAMP     DEFAULT CURRENT_TIMESTAMP()
);

-- =====================================================================
-- Conversions (the events being attributed)
-- =====================================================================
CREATE TABLE IF NOT EXISTS `YOUR_PROJECT.raw.raw_conversions` (
    conversion_id        STRING        NOT NULL,
    user_id              STRING,
    conversion_type      STRING,
    revenue              NUMERIC,
    conversion_timestamp TIMESTAMP,
    _loaded_at           TIMESTAMP     DEFAULT CURRENT_TIMESTAMP()
);

-- =====================================================================
-- Ad spend (daily per-channel cost for ROAS)
-- =====================================================================
CREATE TABLE IF NOT EXISTS `YOUR_PROJECT.raw.raw_ad_spend` (
    spend_id        STRING        NOT NULL,
    spend_date      DATE,
    channel         STRING,
    campaign_id     STRING,
    spend_amount    NUMERIC,
    impressions     INT64,
    clicks          INT64,
    _loaded_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP()
);

-- =====================================================================
-- Identity stitching map
-- =====================================================================
CREATE TABLE IF NOT EXISTS `YOUR_PROJECT.raw.raw_user_identity` (
    user_id           STRING        NOT NULL,
    canonical_user_id STRING,
    email_hash        STRING,
    first_seen_at     TIMESTAMP,
    last_seen_at      TIMESTAMP,
    _loaded_at        TIMESTAMP     DEFAULT CURRENT_TIMESTAMP()
);
