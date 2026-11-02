"""
generate_charts.py

Creates 5 publication-quality charts from the BigQuery
experiment results.

Source:
    project-d8d88b02-3334-4b57-b24.meta.experiment_metrics
    project-d8d88b02-3334-4b57-b24.meta.experiment_runs
"""

from pathlib import Path

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from google.cloud import bigquery


# ============================================================
# CONFIG
# ============================================================

PROJECT = "project-d8d88b02-3334-4b57-b24"

METRICS = (
    f"{PROJECT}.meta.experiment_metrics"
)

RUNS = (
    f"{PROJECT}.meta.experiment_runs"
)

OUT = (
    Path(__file__).resolve().parent
    / "results"
    / "charts"
)

OUT.mkdir(
    parents=True,
    exist_ok=True
)


# ============================================================
# CHART STYLE
# ============================================================

sns.set_theme(
    style="whitegrid",
    context="paper",
    font_scale=1.1
)

plt.rcParams.update({
    "figure.dpi": 300,
    "savefig.dpi": 300,
    "savefig.bbox": "tight"
})


BASELINE_COLOR = "#7B8FA1"
INTERVENTION_COLOR = "#2E75B6"

BASELINE = "BASELINE_INCREMENTAL"

INTERVENTION = (
    "INTERVENTION_MATERIALIZED_VIEW"
)


# ============================================================
# BIGQUERY
# ============================================================

client = bigquery.Client(
    project=PROJECT
)


# ============================================================
# FETCH DATA
# ============================================================

def fetch():

    sql = f"""
        SELECT
            m.run_uuid,
            m.condition,
            m.metric_name,
            m.metric_value,
            r.run_index

        FROM `{METRICS}` AS m

        LEFT JOIN `{RUNS}` AS r
            ON m.run_uuid = r.run_uuid
            AND m.condition = r.condition

        ORDER BY
            r.run_index,
            m.condition,
            m.metric_name
    """

    df = client.query(sql).to_dataframe()

    if df.empty:
        return df

    df["metric_value"] = pd.to_numeric(
        df["metric_value"],
        errors="coerce"
    )

    df["run_index"] = pd.to_numeric(
        df["run_index"],
        errors="coerce"
    )

    return df


# ============================================================
# 1. BOX PLOT
# ============================================================

def plot_box(df):

    metrics = [
        "freshness_lag_seconds",
        "n_events"
    ]

    sub = df[
        df["metric_name"].isin(metrics)
    ].copy()

    if sub.empty:
        print(
            "  Skipped box plot: "
            "required metrics not found"
        )
        return

    fig, ax = plt.subplots(
        figsize=(9, 5)
    )

    sns.boxplot(
        data=sub,
        x="metric_name",
        y="metric_value",
        hue="condition",
        palette={
            BASELINE:
                BASELINE_COLOR,

            INTERVENTION:
                INTERVENTION_COLOR
        },
        ax=ax
    )

    ax.set_title(
        "Freshness lag and event count",
        fontweight="bold"
    )

    ax.set_xlabel("")

    ax.set_ylabel(
        "Metric value"
    )

    fig.savefig(
        OUT / "box_plot_metrics.png"
    )

    plt.close(fig)


# ============================================================
# 2. FRESHNESS LAG DISTRIBUTION
# ============================================================

def plot_lag_distribution(df):

    sub = df[
        df["metric_name"]
        == "freshness_lag_seconds"
    ].copy()

    if sub.empty:
        print(
            "  Skipped lag distribution: "
            "freshness_lag_seconds not found"
        )
        return

    fig, ax = plt.subplots(
        figsize=(8, 5)
    )

    sns.violinplot(
        data=sub,
        x="condition",
        y="metric_value",
        hue="condition",
        palette={
            BASELINE:
                BASELINE_COLOR,

            INTERVENTION:
                INTERVENTION_COLOR
        },
        legend=False,
        ax=ax,
        inner="point",
        cut=0
    )

    ax.set_title(
        "Distribution of freshness lag",
        fontweight="bold"
    )

    ax.set_xlabel("")

    ax.set_ylabel(
        "Freshness lag (seconds)"
    )

    ax.set_xticklabels([
        "Baseline\n(Incremental)",
        "Intervention\n(Materialized View)"
    ])

    fig.savefig(
        OUT / "freshness_lag_distribution.png"
    )

    plt.close(fig)


# ============================================================
# 3. PAIRED LAG
# ============================================================

def plot_paired_lag(df):

    sub = df[
        df["metric_name"]
        == "freshness_lag_seconds"
    ].copy()

    if sub.empty:
        print(
            "  Skipped paired lag: "
            "freshness_lag_seconds not found"
        )
        return

    wide = sub.pivot_table(
        index="run_uuid",
        columns="condition",
        values="metric_value",
        aggfunc="first"
    ).dropna(
        subset=[
            BASELINE,
            INTERVENTION
        ]
    )

    if wide.empty:
        print(
            "  Skipped paired lag: "
            "no complete pairs"
        )
        return

    fig, ax = plt.subplots(
        figsize=(8, 5)
    )

    for _, row in wide.iterrows():

        ax.plot(
            [0, 1],
            [
                row[BASELINE],
                row[INTERVENTION]
            ],
            color="gray",
            alpha=0.4,
            marker="o"
        )

    ax.scatter(
        [0] * len(wide),
        wide[BASELINE],
        color=BASELINE_COLOR,
        s=60,
        zorder=3,
        label="Baseline"
    )

    ax.scatter(
        [1] * len(wide),
        wide[INTERVENTION],
        color=INTERVENTION_COLOR,
        s=60,
        zorder=3,
        label="Materialized View"
    )

    ax.set_xticks([0, 1])

    ax.set_xticklabels([
        "Baseline\n(Incremental)",
        "Intervention\n(Materialized View)"
    ])

    ax.set_ylabel(
        "Freshness lag (seconds)"
    )

    ax.set_title(
        "Paired freshness-lag differences",
        fontweight="bold"
    )

    ax.legend(
        loc="upper right"
    )

    fig.savefig(
        OUT / "paired_lag.png"
    )

    plt.close(fig)


# ============================================================
# 4. TIME SERIES
# ============================================================

def plot_timeseries(df):

    fig, ax = plt.subplots(
        figsize=(10, 5)
    )

    found = False

    for condition, color, label in [
        (
            BASELINE,
            BASELINE_COLOR,
            "Baseline"
        ),
        (
            INTERVENTION,
            INTERVENTION_COLOR,
            "Materialized View"
        )
    ]:

        sub = df[
            (df["metric_name"]
             == "freshness_lag_seconds")
            &
            (df["condition"]
             == condition)
        ].sort_values(
            "run_index"
        )

        if not sub.empty:

            found = True

            ax.plot(
                sub["run_index"],
                sub["metric_value"],
                marker="o",
                linewidth=1.4,
                alpha=0.85,
                color=color,
                label=label
            )

    if not found:
        print(
            "  Skipped time series: "
            "no freshness data"
        )
        plt.close(fig)
        return

    ax.set_xlabel(
        "Experimental run index"
    )

    ax.set_ylabel(
        "Freshness lag (seconds)"
    )

    ax.set_title(
        "Freshness lag across experimental runs",
        fontweight="bold"
    )

    ax.legend(
        loc="upper right"
    )

    fig.savefig(
        OUT / "lag_timeseries.png"
    )

    plt.close(fig)


# ============================================================
# 5. COST VS LAG
# ============================================================

def plot_cost_vs_lag(df):

    required = [
        "freshness_lag_seconds",
        "slot_ms",
        "bytes_processed"
    ]

    available = set(
        df["metric_name"].unique()
    )

    # Prefer slot_ms because your experiment records it.
    if (
        "freshness_lag_seconds" not in available
        or "slot_ms" not in available
    ):

        print(
            "  Skipped cost-vs-lag: "
            "freshness_lag_seconds or slot_ms "
            "not found"
        )

        return

    wide = df[
        df["metric_name"].isin(
            [
                "freshness_lag_seconds",
                "slot_ms"
            ]
        )
    ].pivot_table(
        index=[
            "run_uuid",
            "condition"
        ],
        columns="metric_name",
        values="metric_value",
        aggfunc="first"
    ).reset_index()

    fig, ax = plt.subplots(
        figsize=(8, 5)
    )

    for condition, color, label in [
        (
            BASELINE,
            BASELINE_COLOR,
            "Baseline"
        ),
        (
            INTERVENTION,
            INTERVENTION_COLOR,
            "Materialized View"
        )
    ]:

        sub = wide[
            wide["condition"]
            == condition
        ]

        if not sub.empty:

            ax.scatter(
                sub["freshness_lag_seconds"],
                sub["slot_ms"],
                color=color,
                s=60,
                alpha=0.7,
                label=label
            )

    ax.set_xlabel(
        "Freshness lag (seconds)"
    )

    ax.set_ylabel(
        "Slot milliseconds"
    )

    ax.set_title(
        "Compute cost vs freshness lag",
        fontweight="bold"
    )

    ax.legend()

    fig.savefig(
        OUT / "cost_vs_lag.png"
    )

    plt.close(fig)


# ============================================================
# MAIN
# ============================================================

def main():

    print("=" * 70)
    print("GENERATING EXPERIMENT CHARTS")
    print("=" * 70)

    print(
        f"Project: {PROJECT}"
    )

    print(
        f"Output:  {OUT}"
    )

    print()

    df = fetch()

    if df.empty:

        print(
            "No experiment metrics found."
        )

        print(
            "Run run_experiment.py first."
        )

        return

    print(
        f"Rows:          {len(df)}"
    )

    print(
        f"Experiment IDs: "
        f"{df['run_uuid'].nunique()}"
    )

    print(
        f"Metrics:       "
        f"{df['metric_name'].nunique()}"
    )

    print(
        "Conditions:"
    )

    for condition in sorted(
        df["condition"].dropna().unique()
    ):

        count = (
            df["condition"]
            == condition
        ).sum()

        print(
            f"  {condition}: {count}"
        )

    print()

    # --------------------------------------------------------
    # GENERATE
    # --------------------------------------------------------

    plot_box(df)

    print(
        "  OK: box_plot_metrics.png"
    )

    plot_lag_distribution(df)

    print(
        "  OK: freshness_lag_distribution.png"
    )

    plot_paired_lag(df)

    print(
        "  OK: paired_lag.png"
    )

    plot_timeseries(df)

    print(
        "  OK: lag_timeseries.png"
    )

    plot_cost_vs_lag(df)

    print(
        "  OK: cost_vs_lag.png"
    )

    print()

    print(
        f"All charts saved to:\n{OUT}"
    )


if __name__ == "__main__":
    main()
