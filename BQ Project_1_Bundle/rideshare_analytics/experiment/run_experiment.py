import time
import uuid
import subprocess
from pathlib import Path
from datetime import datetime, timezone, timedelta

import numpy as np
from google.cloud import bigquery


# ============================================================
# CONFIG
# ============================================================

PROJECT = "project-d8d88b02-3334-4b57-b24"

DBT_DIR = Path(
    r"C:\Users\lohit\BQ Project_1_Bundle\rideshare_analytics\dbt"
)

DBT_PROJECT = DBT_DIR / "dbt_project.yml"

NUM_RUNS = 20
TRIPS_PER_RUN = 50
OBS_SECS = 300
SEED = 42


# ============================================================
# VERIFY DBT PROJECT
# ============================================================

if not DBT_PROJECT.exists():
    raise RuntimeError(
        f"dbt_project.yml not found:\n{DBT_PROJECT}"
    )


# ============================================================
# BIGQUERY TABLES
# ============================================================

RAW = f"{PROJECT}.raw.raw_trips"

BASE = f"{PROJECT}.marts.mart_driver_utilization_baseline"

MV = f"{PROJECT}.streams_dt.mart_driver_utilization_mv"

RUNS = f"{PROJECT}.meta.experiment_runs"

METRICS = f"{PROJECT}.meta.experiment_metrics"


client = bigquery.Client(project=PROJECT)


# ============================================================
# HELPERS
# ============================================================

def query(sql):
    return list(client.query(sql).result())


def now():
    return datetime.now(timezone.utc)


def insert_rows(table, rows):

    if not rows:
        return

    errors = client.insert_rows_json(table, rows)

    if errors:
        raise RuntimeError(
            f"BigQuery insert failed:\n{errors}"
        )


# ============================================================
# INSERT SYNTHETIC TRIPS
# ============================================================

def insert_trips(first_trip_id, driver_start, seed):

    rng = np.random.default_rng(seed)
    created = now()
    rows = []

    for i in range(TRIPS_PER_RUN):

        distance = round(
            float(rng.uniform(1, 25)),
            2
        )

        duration = round(
            distance / 25 * 60,
            1
        )

        request = (
            created
            - timedelta(
                minutes=int(
                    rng.integers(0, 20)
                )
            )
        )

        pickup = (
            request
            + timedelta(
                seconds=int(
                    rng.integers(30, 180)
                )
            )
        )

        dropoff = (
            pickup
            + timedelta(minutes=duration)
        )

        base_fare = round(
            distance * 12 + 30,
            2
        )

        surge = 1.5

        final_fare = round(
            base_fare * surge,
            2
        )

        rows.append(
            {
                "trip_id": first_trip_id + i,

                "rider_id": int(
                    rng.integers(1, 200000)
                ),

                "driver_id": driver_start + i,

                "city_id": int(
                    rng.integers(1, 11)
                ),

                "request_timestamp":
                    request.isoformat(),

                "pickup_timestamp":
                    pickup.isoformat(),

                "dropoff_timestamp":
                    dropoff.isoformat(),

                "pickup_lat": 19.0,
                "pickup_lng": 72.8,

                "dropoff_lat": 19.1,
                "dropoff_lng": 72.9,

                "distance_km": distance,

                "duration_min": duration,

                "base_fare": base_fare,

                "surge_multiplier": surge,

                "final_fare": final_fare,

                "payment_method": "upi",

                "trip_status": "completed",

                "rating_by_rider": 4.5,

                "rating_by_driver": 4.7,

                "created_at":
                    created.isoformat(),

                "updated_at":
                    created.isoformat()
            }
        )

    config = bigquery.LoadJobConfig(
        write_disposition="WRITE_APPEND"
    )

    job = client.load_table_from_json(
        rows,
        RAW,
        job_config=config
    )

    job.result()


# ============================================================
# WAIT FOR MART
# ============================================================

def wait_for_mart(mart, driver_start):

    started = time.time()

    driver_end = (
        driver_start
        + TRIPS_PER_RUN
        - 1
    )

    while (
        time.time() - started
        < OBS_SECS
    ):

        result = query(
            f"""
            SELECT COUNT(*) AS n
            FROM `{mart}`
            WHERE driver_id BETWEEN
                {driver_start}
                AND {driver_end}
            """
        )

        count = int(
            result[0].n or 0
        )

        if count >= TRIPS_PER_RUN:

            return round(
                time.time() - started,
                3
            )

        time.sleep(3)

    return float(OBS_SECS)


# ============================================================
# CLEANUP
# ============================================================

def cleanup(first_trip_id, last_trip_id):

    query(
        f"""
        DELETE FROM `{RAW}`
        WHERE trip_id BETWEEN
            {first_trip_id}
            AND {last_trip_id}
        """
    )


# ============================================================
# RUN DBT BASELINE
# ============================================================

def run_baseline():

    command = [
        "dbt",
        "run",
        "--project-dir",
        str(DBT_DIR),
        "--select",
        "mart_driver_utilization_baseline"
    ]

    result = subprocess.run(
        command,
        cwd=str(DBT_DIR),
        capture_output=True,
        text=True
    )

    if result.returncode != 0:

        print()
        print("========== DBT ERROR ==========")
        print(result.stdout)
        print(result.stderr)
        print("================================")
        print()

        raise RuntimeError(
            "dbt baseline failed."
        )


# ============================================================
# SAVE RESULTS
# ============================================================

def save_result(
    run_id,
    run_uuid,
    index,
    condition,
    lag
):

    # NUMERIC columns require clean decimal-compatible values.
    lag = round(float(lag), 3)

    timestamp = now().isoformat()

    insert_rows(
        RUNS,
        [
            {
                "run_id": int(run_id),

                "run_uuid": run_uuid,

                "condition": condition,

                "run_index": int(index),

                "started_at": timestamp,

                "completed_at": timestamp,

                "duration_seconds": lag,

                "notes": ""
            }
        ]
    )

    insert_rows(
        METRICS,
        [
            {
                "metric_id":
                    int(time.time_ns()),

                "run_uuid":
                    run_uuid,

                "condition":
                    condition,

                "metric_name":
                    "freshness_lag_seconds",

                "metric_value":
                    round(float(lag), 3)
            },

            {
                "metric_id":
                    int(time.time_ns()) + 1,

                "run_uuid":
                    run_uuid,

                "condition":
                    condition,

                "metric_name":
                    "n_events",

                "metric_value":
                    float(TRIPS_PER_RUN)
            }
        ]
    )


# ============================================================
# MAIN
# ============================================================

def main():

    print("=" * 70)
    print("RIDESHARE ANALYTICS EXPERIMENT")
    print("=" * 70)

    print(
        f"Project:          {PROJECT}"
    )

    print(
        f"dbt project:      {DBT_DIR}"
    )

    print(
        f"Number of runs:   {NUM_RUNS}"
    )

    print(
        f"Trips per run:    {TRIPS_PER_RUN}"
    )

    print(
        f"Observation sec:  {OBS_SECS}"
    )

    print(
        f"Random seed:      {SEED}"
    )

    print()

    # --------------------------------------------------------
    # CHECK TABLES
    # --------------------------------------------------------

    print(
        "Checking BigQuery tables..."
    )

    for table in [
        RAW,
        BASE,
        MV,
        RUNS,
        METRICS
    ]:

        client.get_table(table)

        print(
            f"  OK: {table}"
        )

    print()

    # --------------------------------------------------------
    # START TRIP ID
    # --------------------------------------------------------

    result = query(
        f"""
        SELECT
            COALESCE(
                MAX(trip_id),
                0
            ) AS max_id
        FROM `{RAW}`
        """
    )

    first_trip_id = (
        int(
            result[0].max_id or 0
        )
        + 1000000
    )

    # --------------------------------------------------------
    # START RUN ID
    # --------------------------------------------------------

    result = query(
        f"""
        SELECT
            COALESCE(
                MAX(run_id),
                0
            ) AS max_id
        FROM `{RUNS}`
        """
    )

    run_id = (
        int(
            result[0].max_id or 0
        )
        + 1
    )

    driver_start = 900000

    print(
        f"Starting trip_id: {first_trip_id}"
    )

    print(
        f"Starting run_id:  {run_id}"
    )

    print()

    # --------------------------------------------------------
    # EXPERIMENT LOOP
    # --------------------------------------------------------

    for i in range(NUM_RUNS):

        print(
            f"Experiment {i + 1}/{NUM_RUNS}"
        )

        run_uuid = uuid.uuid4().hex

        print(
            f"  run_uuid = {run_uuid}"
        )

        first = first_trip_id

        last = (
            first
            + TRIPS_PER_RUN
            - 1
        )

        try:

            # ------------------------------------------------
            # INSERT
            # ------------------------------------------------

            insert_trips(
                first,
                driver_start,
                SEED + i
            )

            # ------------------------------------------------
            # BASELINE
            # ------------------------------------------------

            print(
                "  Running baseline..."
            )

            baseline_start = time.time()

            run_baseline()

            baseline_lag = wait_for_mart(
                BASE,
                driver_start
            )

            baseline_total = round(
                time.time()
                - baseline_start,
                3
            )

            # ------------------------------------------------
            # MATERIALIZED VIEW
            # ------------------------------------------------

            print(
                "  Waiting for "
                "materialized view..."
            )

            intervention_start = time.time()

            intervention_lag = wait_for_mart(
                MV,
                driver_start
            )

            intervention_total = round(
                time.time()
                - intervention_start,
                3
            )

            # ------------------------------------------------
            # SAVE
            # ------------------------------------------------

            save_result(
                run_id,
                run_uuid,
                i,
                "BASELINE_INCREMENTAL",
                baseline_lag
            )

            save_result(
                run_id + 1,
                run_uuid,
                i,
                "INTERVENTION_MATERIALIZED_VIEW",
                intervention_lag
            )

            # ------------------------------------------------
            # OUTPUT
            # ------------------------------------------------

            print(
                f"  B_lag={baseline_lag:.3f}s "
                f"I_lag={intervention_lag:.3f}s"
            )

            print(
                f"  B_total={baseline_total:.3f}s "
                f"I_total={intervention_total:.3f}s"
            )

        finally:

            # ------------------------------------------------
            # CLEANUP
            # ------------------------------------------------

            print(
                "  Cleaning up..."
            )

            try:

                cleanup(
                    first,
                    last
                )

                print(
                    "  Cleanup OK"
                )

            except Exception as exc:

                print(
                    f"  Cleanup warning: "
                    f"{exc}"
                )

        first_trip_id += TRIPS_PER_RUN

        driver_start += TRIPS_PER_RUN

        run_id += 2

        print()

    # --------------------------------------------------------
    # VERIFY PAIRS
    # --------------------------------------------------------

    result = query(
        f"""
        SELECT COUNT(*) AS pairs
        FROM (
            SELECT DISTINCT
                run_uuid
            FROM `{METRICS}`
            WHERE condition =
                'BASELINE_INCREMENTAL'
        ) b
        INNER JOIN (
            SELECT DISTINCT
                run_uuid
            FROM `{METRICS}`
            WHERE condition =
                'INTERVENTION_MATERIALIZED_VIEW'
        ) i
        USING (run_uuid)
        """
    )

    pairs = int(
        result[0].pairs or 0
    )

    print("=" * 70)
    print("EXPERIMENT COMPLETE")
    print("=" * 70)

    print(
        f"Matched pairs:  {pairs}"
    )

    print(
        f"Expected pairs: {NUM_RUNS}"
    )

    if pairs == NUM_RUNS:

        print(
            "SUCCESS: all pairs are valid."
        )

    else:

        print(
            "WARNING: pair count does not match."
        )

    print()

    print(
        "Next command:"
    )

    print(
        "python statistical_analysis.py"
    )


if __name__ == "__main__":
    main()
