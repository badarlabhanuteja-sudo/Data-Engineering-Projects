"""statistical_analysis.py — Wilcoxon, Cohen's d, bootstrapped CIs. BigQuery edition."""

import os
import json
from pathlib import Path

import numpy as np
import pandas as pd
from dotenv import load_dotenv
from scipy import stats
from google.cloud import bigquery


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = BASE_DIR.parent

load_dotenv(PROJECT_ROOT / ".env")

OUT = BASE_DIR / "results"
OUT.mkdir(exist_ok=True)

PROJECT = os.environ.get("GCP_PROJECT_ID")

if not PROJECT:
    raise RuntimeError(
        "GCP_PROJECT_ID is not set. "
        "Please add GCP_PROJECT_ID=your-project-id to your .env file."
    )

client = bigquery.Client(project=PROJECT)

BASELINE = "BASELINE_INCREMENTAL"
INTERVENTION = "INTERVENTION_MATERIALIZED_VIEW"

MIN_PAIRS = 5


# ---------------------------------------------------------------------------
# BigQuery
# ---------------------------------------------------------------------------

def fetch_long():
    """Fetch experiment metrics from BigQuery."""

    query = f"""
        SELECT
            run_uuid,
            condition,
            metric_name,
            metric_value
        FROM `{PROJECT}.meta.experiment_metrics`
        WHERE run_uuid IS NOT NULL
          AND condition IS NOT NULL
          AND metric_name IS NOT NULL
          AND metric_value IS NOT NULL
    """

    print("Fetching experiment metrics from BigQuery...")

    df = client.query(query).to_dataframe()

    print(f"Fetched {len(df)} metric rows.")

    return df


# ---------------------------------------------------------------------------
# Statistics
# ---------------------------------------------------------------------------

def cohens_d_paired(x, y):
    """
    Calculate Cohen's d for paired observations.

    d = mean(x - y) / standard deviation(x - y)
    """

    x = np.asarray(x, dtype=float)
    y = np.asarray(y, dtype=float)

    diff = x - y

    if len(diff) < 2:
        return float("nan")

    std = diff.std(ddof=1)

    if np.isclose(std, 0):
        if np.isclose(diff.mean(), 0):
            return 0.0
        return float("inf") if diff.mean() > 0 else float("-inf")

    return float(diff.mean() / std)


def bootstrap_ci(diff, n_boot=10000, alpha=0.05, seed=42):
    """
    Calculate a percentile bootstrap confidence interval
    for the mean difference.
    """

    diff = np.asarray(diff, dtype=float)

    diff = diff[np.isfinite(diff)]

    if len(diff) == 0:
        return float("nan"), float("nan")

    if len(diff) == 1:
        value = float(diff[0])
        return value, value

    rng = np.random.default_rng(seed)

    # Generate all bootstrap samples at once for efficiency.
    indices = rng.integers(
        0,
        len(diff),
        size=(n_boot, len(diff))
    )

    boots = diff[indices].mean(axis=1)

    return (
        float(np.quantile(boots, alpha / 2)),
        float(np.quantile(boots, 1 - alpha / 2)),
    )


def wilcoxon_test(intervention, baseline):
    """
    Perform a two-sided paired Wilcoxon signed-rank test.

    Returns NaN when the test cannot be computed.
    """

    intervention = np.asarray(intervention, dtype=float)
    baseline = np.asarray(baseline, dtype=float)

    diff = intervention - baseline

    # Remove non-finite values.
    mask = np.isfinite(diff)
    diff = diff[mask]

    if len(diff) == 0:
        return float("nan")

    # If every paired difference is zero, there is no evidence
    # of a difference between the conditions.
    if np.allclose(diff, 0):
        return 1.0

    try:
        result = stats.wilcoxon(
            intervention[mask],
            baseline[mask],
            zero_method="wilcox",
            alternative="two-sided",
        )

        return float(result.pvalue)

    except ValueError:
        return float("nan")


# ---------------------------------------------------------------------------
# Main analysis
# ---------------------------------------------------------------------------

def main():

    # -----------------------------------------------------------------------
    # Fetch data
    # -----------------------------------------------------------------------

    df = fetch_long()

    if df.empty:
        print()
        print("ERROR: No metrics were found in BigQuery.")
        print()
        print("Run run_experiment.py first and make sure it writes")
        print("records to:")
        print(f"  {PROJECT}.meta.experiment_metrics")
        return

    required_columns = {
        "run_uuid",
        "condition",
        "metric_name",
        "metric_value",
    }

    missing_columns = required_columns - set(df.columns)

    if missing_columns:
        raise RuntimeError(
            "BigQuery result is missing required columns: "
            + ", ".join(sorted(missing_columns))
        )

    # -----------------------------------------------------------------------
    # Clean data
    # -----------------------------------------------------------------------

    df["metric_value"] = pd.to_numeric(
        df["metric_value"],
        errors="coerce"
    )

    df = df.dropna(
        subset=[
            "run_uuid",
            "condition",
            "metric_name",
            "metric_value",
        ]
    )

    if df.empty:
        print("ERROR: All metric rows became invalid after cleaning.")
        return

    print()
    print("Conditions found:")
    for condition in sorted(df["condition"].unique()):
        count = (df["condition"] == condition).sum()
        print(f"  {condition}: {count} rows")

    print()
    print("Metrics found:")

    for metric in sorted(df["metric_name"].unique()):
        count = (df["metric_name"] == metric).sum()
        print(f"  {metric}: {count} rows")

    # -----------------------------------------------------------------------
    # Convert long format to paired wide format
    # -----------------------------------------------------------------------

    wide = df.pivot_table(
        index=["run_uuid", "metric_name"],
        columns="condition",
        values="metric_value",
        aggfunc="first",
    ).reset_index()

    # Make sure the expected conditions exist.
    missing_conditions = []

    if BASELINE not in wide.columns:
        missing_conditions.append(BASELINE)

    if INTERVENTION not in wide.columns:
        missing_conditions.append(INTERVENTION)

    if missing_conditions:
        print()
        print("ERROR: Required experiment conditions are missing:")
        for condition in missing_conditions:
            print(f"  - {condition}")

        print()
        print("Expected conditions:")
        print(f"  - {BASELINE}")
        print(f"  - {INTERVENTION}")

        print()
        print("Available conditions:")
        for condition in df["condition"].unique():
            print(f"  - {condition}")

        return

    # -----------------------------------------------------------------------
    # Statistical analysis
    # -----------------------------------------------------------------------

    rows = []

    metrics = sorted(wide["metric_name"].dropna().unique())

    print()
    print(f"Analyzing {len(metrics)} metrics...")
    print()

    for metric in metrics:

        sub = wide[
            wide["metric_name"] == metric
        ].dropna(
            subset=[
                BASELINE,
                INTERVENTION,
            ]
        )

        n_pairs = len(sub)

        print(f"Metric: {metric}")
        print(f"  Matched pairs: {n_pairs}")

        # Need enough paired observations for a meaningful analysis.
        if n_pairs < MIN_PAIRS:
            print(
                f"  SKIPPED: fewer than {MIN_PAIRS} matched pairs."
            )
            print()
            continue

        baseline = sub[BASELINE].astype(float).to_numpy()
        intervention = sub[INTERVENTION].astype(float).to_numpy()

        diff = intervention - baseline

        # Remove any unexpected non-finite values.
        mask = (
            np.isfinite(baseline)
            & np.isfinite(intervention)
            & np.isfinite(diff)
        )

        baseline = baseline[mask]
        intervention = intervention[mask]
        diff = diff[mask]

        n_pairs = len(diff)

        if n_pairs < MIN_PAIRS:
            print(
                f"  SKIPPED: only {n_pairs} valid matched pairs remain."
            )
            print()
            continue

        # Wilcoxon signed-rank test.
        w_p = wilcoxon_test(
            intervention,
            baseline
        )

        # Cohen's d for paired observations.
        d = cohens_d_paired(
            intervention,
            baseline
        )

        # Bootstrap confidence interval for mean difference.
        ci_low, ci_high = bootstrap_ci(diff)

        row = {
            "metric": str(metric),
            "n_pairs": int(n_pairs),

            "baseline_mean": float(baseline.mean()),
            "baseline_std": (
                float(baseline.std(ddof=1))
                if n_pairs > 1
                else float("nan")
            ),

            "intervention_mean": float(intervention.mean()),
            "intervention_std": (
                float(intervention.std(ddof=1))
                if n_pairs > 1
                else float("nan")
            ),

            "mean_diff": float(diff.mean()),

            "diff_ci95_low": float(ci_low),
            "diff_ci95_high": float(ci_high),

            "wilcoxon_p_2sided": (
                float(w_p)
                if np.isfinite(w_p)
                else None
            ),

            "cohens_d": (
                float(d)
                if np.isfinite(d)
                else None
            ),

            "significant_at_0p05": (
                bool(np.isfinite(w_p) and w_p < 0.05)
            ),
        }

        rows.append(row)

        print(f"  Baseline mean:     {row['baseline_mean']:.6f}")
        print(f"  Intervention mean: {row['intervention_mean']:.6f}")
        print(f"  Mean difference:   {row['mean_diff']:.6f}")
        print(f"  Wilcoxon p-value:  {w_p:.6f}" if np.isfinite(w_p)
              else "  Wilcoxon p-value:  NaN")
        print(f"  Cohen's d:         {d:.6f}" if np.isfinite(d)
              else "  Cohen's d:         NaN")
        print()

    # -----------------------------------------------------------------------
    # Handle case where no metric passed the minimum-pair requirement.
    # This is the issue that caused the original KeyError.
    # -----------------------------------------------------------------------

    if not rows:

        print("=" * 70)
        print("WARNING: No metrics were available for statistical analysis.")
        print("=" * 70)
        print()
        print(
            f"Every metric had fewer than {MIN_PAIRS} matched pairs "
            "between:"
        )
        print(f"  {BASELINE}")
        print(f"  {INTERVENTION}")
        print()
        print("Check that run_experiment.py generated both conditions")
        print("for the same run_uuid values.")
        print()

        # Still create valid empty output files with the expected columns.
        columns = [
            "metric",
            "n_pairs",
            "baseline_mean",
            "baseline_std",
            "intervention_mean",
            "intervention_std",
            "mean_diff",
            "diff_ci95_low",
            "diff_ci95_high",
            "wilcoxon_p_2sided",
            "cohens_d",
            "significant_at_0p05",
        ]

        summary = pd.DataFrame(columns=columns)

        summary.to_csv(
            OUT / "statistical_summary.csv",
            index=False
        )

        with open(
            OUT / "statistical_summary.json",
            "w",
            encoding="utf-8"
        ) as f:
            json.dump([], f, indent=2)

        print(
            f"Created empty statistical summary at:\n"
            f"  {OUT / 'statistical_summary.csv'}"
        )

        return

    # -----------------------------------------------------------------------
    # Create final summary
    # -----------------------------------------------------------------------

    summary = pd.DataFrame(rows)

    # Safety check before sorting.
    if "metric" in summary.columns:
        summary = summary.sort_values(
            "metric"
        ).reset_index(drop=True)

    # -----------------------------------------------------------------------
    # Save CSV
    # -----------------------------------------------------------------------

    csv_path = OUT / "statistical_summary.csv"

    summary.to_csv(
        csv_path,
        index=False
    )

    # -----------------------------------------------------------------------
    # Save JSON
    # -----------------------------------------------------------------------

    json_path = OUT / "statistical_summary.json"

    with open(
        json_path,
        "w",
        encoding="utf-8"
    ) as f:
        json.dump(
            rows,
            f,
            indent=2,
            default=str
        )

    # -----------------------------------------------------------------------
    # Print results
    # -----------------------------------------------------------------------

    print("=" * 70)
    print(
        f"Wrote {len(summary)} metrics to:"
    )
    print(f"  {csv_path}")
    print()
    print(f"JSON output:")
    print(f"  {json_path}")
    print("=" * 70)
    print()

    pd.set_option(
        "display.width",
        220
    )

    display_columns = [
        "metric",
        "baseline_mean",
        "intervention_mean",
        "mean_diff",
        "wilcoxon_p_2sided",
        "cohens_d",
        "significant_at_0p05",
    ]

    print(
        summary[display_columns].to_string(
            index=False
        )
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    main()
