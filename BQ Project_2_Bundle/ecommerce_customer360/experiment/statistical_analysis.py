"""
statistical_analysis.py
Reads experiment results from meta.experiment_metrics and produces:
  - Paired Wilcoxon signed-rank test per metric
  - Cohen's d effect size
  - Bootstrapped 95% confidence intervals on the paired mean difference
  - Summary CSV + JSON for the dissertation Results chapter

Output:
  /workspace/experiment/results/statistical_summary.csv
  /workspace/experiment/results/statistical_summary.json
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

OUT = Path(__file__).resolve().parent / "results"
OUT.mkdir(exist_ok=True)


def get_client():
    # Authenticates via GOOGLE_APPLICATION_CREDENTIALS env var (service account)
    # or application-default credentials (`gcloud auth application-default login`)
    return bigquery.Client(
        project=os.environ.get("BIGQUERY_PROJECT", "ecommerce-customer360")
    )


def fetch_long():
    client = get_client()
    query = """
        SELECT run_uuid, condition, metric_name, metric_value
        FROM `ecommerce-customer360.meta.experiment_metrics`
    """
    df = client.query(query).to_dataframe()
    df.columns = [c.lower() for c in df.columns]
    return df


def cohens_d_paired(x, y):
    diff = np.array(x) - np.array(y)
    return float(diff.mean() / (diff.std(ddof=1) + 1e-12))


def bootstrap_ci(diff, n_boot=10000, alpha=0.05, seed=42):
    rng = np.random.default_rng(seed)
    diff = np.array(diff)
    boots = np.empty(n_boot)
    for i in range(n_boot):
        sample = rng.choice(diff, size=len(diff), replace=True)
        boots[i] = sample.mean()
    return float(np.quantile(boots, alpha / 2)), float(np.quantile(boots, 1 - alpha / 2))


def main():
    print("fetching experiment_metrics …")
    df = fetch_long()
    print(f"  {len(df):,} metric rows from {df['run_uuid'].nunique()} runs")

    if df.empty:
        print("ERROR: no experiment results found; run run_experiment.py first.")
        return

    # Pivot to one row per (run, metric) with baseline + intervention columns
    wide = df.pivot_table(
        index=["run_uuid", "metric_name"],
        columns="condition",
        values="metric_value",
        aggfunc="first",
    ).reset_index()

    summary_rows = []
    for metric in sorted(wide["metric_name"].unique()):
        sub = wide[wide["metric_name"] == metric].dropna(
            subset=["BASELINE_RFM", "INTERVENTION_ML"])
        if len(sub) < 5:
            continue
        b = sub["BASELINE_RFM"].astype(float).values
        i = sub["INTERVENTION_ML"].astype(float).values
        diff = i - b

        # Wilcoxon signed-rank (one-sided: intervention > baseline)
        try:
            w_stat, w_p_two = stats.wilcoxon(i, b, zero_method="wilcox")
            # convert to one-sided p
            w_p_one = w_p_two / 2 if diff.mean() > 0 else 1 - w_p_two / 2
        except ValueError:
            w_stat, w_p_two, w_p_one = float("nan"), float("nan"), float("nan")

        d = cohens_d_paired(i, b)
        ci_low, ci_high = bootstrap_ci(diff)

        summary_rows.append({
            "metric": metric,
            "n_pairs": len(sub),
            "baseline_mean":     float(b.mean()),
            "baseline_std":      float(b.std(ddof=1)),
            "intervention_mean": float(i.mean()),
            "intervention_std":  float(i.std(ddof=1)),
            "mean_diff":         float(diff.mean()),
            "diff_ci95_low":     ci_low,
            "diff_ci95_high":    ci_high,
            "wilcoxon_stat":     float(w_stat) if not np.isnan(w_stat) else None,
            "wilcoxon_p_2sided": float(w_p_two) if not np.isnan(w_p_two) else None,
            "wilcoxon_p_1sided": float(w_p_one) if not np.isnan(w_p_one) else None,
            "cohens_d":          d,
            "significant_at_0p05": (not np.isnan(w_p_two)) and (w_p_two < 0.05),
        })

    summary = pd.DataFrame(summary_rows).sort_values("metric")
    summary.to_csv(OUT / "statistical_summary.csv", index=False)

    with open(OUT / "statistical_summary.json", "w") as f:
        json.dump(summary_rows, f, indent=2, default=str)

    print(f"\nwrote {len(summary)} metrics → {OUT}/statistical_summary.csv")
    print("\nsummary:")
    pd.set_option("display.max_columns", None)
    pd.set_option("display.width", 220)
    print(summary[["metric", "baseline_mean", "intervention_mean",
                   "mean_diff", "wilcoxon_p_2sided", "cohens_d",
                   "significant_at_0p05"]].to_string(index=False))


if __name__ == "__main__":
    main()
