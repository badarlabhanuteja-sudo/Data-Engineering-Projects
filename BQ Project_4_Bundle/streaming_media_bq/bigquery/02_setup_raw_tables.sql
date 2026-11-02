-- =====================================================================
-- 02_setup_raw_tables.sql
-- BigQuery Sandbox: Raw table DDL
--
-- Key Snowflake → BigQuery type mappings:
--   NUMBER(38,0)       → INT64
--   NUMBER(n,m)        → NUMERIC(n,m) or FLOAT64
--   VARCHAR(n)         → STRING
--   BOOLEAN            → BOOL
--   TIMESTAMP_NTZ      → DATETIME  (no timezone)
--   TIMESTAMP_LTZ      → TIMESTAMP (UTC)
--   VARIANT            → JSON      (BigQuery native JSON type)
--   DATE               → DATE
--
-- BigQuery Sandbox has a 10 GB storage limit and 1 TB/month query limit.
-- No COPY INTO or PUT — use bq load CLI or BigQuery Data Transfer Service.
-- =====================================================================

-- ---------------------------------------------------------------------
-- raw_titles — content catalogue (movies + episodes + series)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.raw.raw_titles` (
    title_id            INT64        NOT NULL,
    title_name          STRING,
    content_type        STRING,          -- movie / show / episode
    series_id           INT64,           -- null for movies
    season_number       INT64,
    episode_number      INT64,
    genres              STRING,          -- comma-separated
    primary_language    STRING,
    release_year        INT64,
    runtime_minutes     INT64,
    is_original         BOOL,
    licence_start_date  DATE,
    licence_end_date    DATE,
    created_at          DATETIME,
    updated_at          DATETIME,
    _loaded_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------
-- raw_users
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.raw.raw_users` (
    user_id             INT64        NOT NULL,
    email               STRING,
    country             STRING,
    plan_tier           STRING,          -- basic / standard / premium / family
    signup_date         DATE,
    is_active           BOOL,
    age_band            STRING,
    profile_count       INT64,
    preferred_language  STRING,
    created_at          DATETIME,
    updated_at          DATETIME,
    _loaded_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------
-- raw_sessions — viewing sessions
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.raw.raw_sessions` (
    session_id          STRING       NOT NULL,
    user_id             INT64,
    profile_id          STRING,
    device_type         STRING,          -- web / ios / android / smart_tv / roku / chromecast
    device_os           STRING,
    session_start       DATETIME,
    session_end         DATETIME,
    network_type        STRING,          -- wifi / cellular / ethernet
    country             STRING,
    _loaded_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------
-- raw_view_events — fine-grained view events
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.raw.raw_view_events` (
    view_event_id           STRING       NOT NULL,
    session_id              STRING,
    user_id                 INT64,
    title_id                INT64,
    event_type              STRING,      -- play / pause / resume / stop / complete / abandon / skip
    event_timestamp         DATETIME,
    playback_position_sec   INT64,
    quality_level           STRING,      -- 480p / 720p / 1080p / 4k
    buffering_seconds       FLOAT64,
    payload                 JSON,        -- BigQuery native JSON type
    _loaded_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------
-- raw_ratings
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.raw.raw_ratings` (
    rating_id           STRING       NOT NULL,
    user_id             INT64,
    title_id            INT64,
    rating              FLOAT64,         -- 0.5 to 5.0 in 0.5 steps
    rated_at            DATETIME,
    _loaded_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------
-- raw_recommendation_clicks — experiment CTR simulation
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.raw.raw_recommendation_clicks` (
    click_id                STRING       NOT NULL,
    user_id                 INT64,
    recommended_title_id    INT64,
    rec_strategy            STRING,      -- BASELINE_NIGHTLY | INTERVENTION_HOURLY
    served_at               DATETIME,
    clicked_at              DATETIME,
    rec_age_seconds         INT64,
    _loaded_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);
