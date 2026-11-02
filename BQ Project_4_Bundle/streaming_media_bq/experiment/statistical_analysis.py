"""statistical_analysis.py — Wilcoxon, Cohen's d, bootstrapped CIs.

BigQuery-compatible: replaces snowflake.connector with google-cloud-bigquery.
"""

import os
import json
from pathlib import Path
import numpy as np
import pandas as pd
from dotenv import load_dotenv
from scipy import stats
from google.cloud import bigquery

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

PROJECT_ID = os.environ["GCP_PROJECT_ID"]
OUT        = Path(__file__).resolve().parent / "results"
OUT.mkdir(exist_ok=True)


def get_client() -> bigquery.Client:
    return bigquery.Client(project=PROJECT_ID)


def fetch() -> pd.DataFrame:
    client = get_client()
    sql = f"""
        SELECT run_uuid, condition, metric_name, metric_value
          FROM `{PROJECT_ID}.meta.experiment_metrics`
    """
    return client.query(sql).to_dataframe()


def cohens_d_paired(x, y) -> float:
    diff = np.array(x) - np.array(y)
    return float(diff.mean() / (diff.std(ddof=1) + 1e-12))


def bootstrap_ci(diff, n_boot: int = 10000, alpha: float = 0.05, seed: int = 42):
    rng  = np.random.default_rng(seed)
    diff = np.array(diff)
    boots = np.array([rng.choice(diff, size=len(diff), replace=True).mean()
                      for _ in range(n_boot)])
    return float(np.quantile(boots, alpha / 2)), float(np.quantile(boots, 1 - alpha / 2))


def main() -> None:
    df = fetch()
    if df.empty:
        print("no metrics — run run_experiment.py first")
        return

    print(f"  {df['run_uuid'].nunique()} runs, {df['metric_name'].nunique()} metrics\n")

    wide = df.pivot_table(
        index=["run_uuid", "metric_name"], columns="condition",
        values="metric_value", aggfunc="first"
    ).reset_index()

    rows = []
    for metric in sorted(wide["metric_name"].unique()):
        sub = wide[wide["metric_name"] == metric].dropna(
            subset=["BASELINE_NIGHTLY", "INTERVENTION_HOURLY"])
        if len(sub) < 5:
            continue
        b = sub["BASELINE_NIGHTLY"].astype(float).values
        i = sub["INTERVENTION_HOURLY"].astype(float).values
        diff = i - b
        try:
            w_stat, w_p = stats.wilcoxon(i, b, zero_method="wilcox")
        except ValueError:
            w_stat, w_p = float("nan"), float("nan")
        d         = cohens_d_paired(i, b)
        ci_low, ci_high = bootstrap_ci(diff)
        rows.append({
            "metric":               metric,
            "n_pairs":              len(sub),
            "baseline_mean":        float(b.mean()),
            "baseline_std":         float(b.std(ddof=1)),
            "intervention_mean":    float(i.mean()),
            "intervention_std":     float(i.std(ddof=1)),
            "mean_diff":            float(diff.mean()),
            "diff_ci95_low":        ci_low,
            "diff_ci95_high":       ci_high,
            "wilcoxon_p_2sided":    float(w_p) if not np.isnan(w_p) else None,
            "cohens_d":             d,
            "significant_at_0p05":  (not np.isnan(w_p)) and (w_p < 0.05),
        })

    summary = pd.DataFrame(rows).sort_values("metric")
    summary.to_csv(OUT / "statistical_summary.csv", index=False)
    with open(OUT / "statistical_summary.json", "w") as f:
        json.dump(rows, f, indent=2, default=str)

    print(f"wrote {len(summary)} metrics → {OUT}/statistical_summary.csv\n")
    pd.set_option("display.width", 220)
    pd.set_option("display.max_columns", None)
    print(summary[[
        "metric", "baseline_mean", "intervention_mean",
        "mean_diff", "wilcoxon_p_2sided", "cohens_d", "significant_at_0p05"
    ]].to_string(index=False))


if __name__ == "__main__":
    main()
