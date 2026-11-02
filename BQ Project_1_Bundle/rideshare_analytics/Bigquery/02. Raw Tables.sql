CREATE OR REPLACE TABLE `your-project-id.raw.raw_cities` (
    city_id         INT64,
    city_name       STRING,
    state           STRING,
    country_code    STRING,
    timezone        STRING,
    population      INT64,
    is_active       BOOL,
    _loaded_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE `your-project-id.raw.raw_drivers` (
    driver_id       INT64,
    first_name      STRING,
    last_name       STRING,
    phone           STRING,
    license_number  STRING,
    vehicle_type    STRING,
    vehicle_number  STRING,
    rating          NUMERIC,
    home_city_id    INT64,
    onboarding_date DATE,
    status          STRING,
    is_active       BOOL,
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP,
    _loaded_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE `your-project-id.raw.raw_riders` (
    rider_id        INT64,
    first_name      STRING,
    last_name       STRING,
    email           STRING,
    phone           STRING,
    home_city_id    INT64,
    signup_date     DATE,
    rider_tier      STRING,
    is_active       BOOL,
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP,
    _loaded_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE `your-project-id.raw.raw_trips` (
    trip_id             INT64,
    rider_id            INT64,
    driver_id           INT64,
    city_id             INT64,
    request_timestamp   TIMESTAMP,
    pickup_timestamp    TIMESTAMP,
    dropoff_timestamp   TIMESTAMP,
    pickup_lat          NUMERIC,
    pickup_lng          NUMERIC,
    dropoff_lat         NUMERIC,
    dropoff_lng         NUMERIC,
    distance_km         NUMERIC,
    duration_min        NUMERIC,
    base_fare           NUMERIC,
    surge_multiplier    NUMERIC,
    final_fare          NUMERIC,
    payment_method      STRING,
    trip_status         STRING,
    rating_by_rider     NUMERIC,
    rating_by_driver    NUMERIC,
    created_at          TIMESTAMP,
    updated_at          TIMESTAMP,
    _loaded_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    _experiment_run_uuid STRING
);

CREATE OR REPLACE TABLE `your-project-id.raw.raw_payments` (
    payment_id          STRING,
    trip_id             INT64,
    payment_status      STRING,
    amount              NUMERIC,
    payment_method      STRING,
    payment_timestamp   TIMESTAMP,
    failure_reason      STRING,
    _loaded_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE `your-project-id.raw.raw_location_pings` (
    ping_id             STRING,
    driver_id           INT64,
    ping_timestamp      TIMESTAMP,
    lat                 FLOAT64,
    lng                 FLOAT64,
    speed_kmph          FLOAT64,
    heading             INT64,
    is_on_trip          BOOL,
    battery_pct         INT64,
    _loaded_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);