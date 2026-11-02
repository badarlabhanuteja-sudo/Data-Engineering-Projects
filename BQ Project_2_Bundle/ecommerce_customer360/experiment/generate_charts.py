"""
generate_charts.py
Produces five publication-quality charts for the dissertation Results chapter.

Outputs in /workspace/experiment/results/charts/ as 300 DPI PNG.

  1. box_plot_metrics.png       — paired box plots per metric
  2. distribution_f1.png        — overlaid violin/density plots of F1 scores
  3. paired_diff_plot.png       — connected paired-difference plot
  4. metric_timeseries.png      — metrics across the 20 experimental runs
  5. summary_radar.png          — radar chart of mean metrics
"""

import os
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from dotenv import load_dotenv
from google.cloud import bigquery

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

OUT = Path(__file__).resolve().parent / "results" / "charts"
OUT.mkdir(parents=True, exist_ok=True)

sns.set_theme(style="whitegrid", context="paper", font_scale=1.1)
plt.rcParams["figure.dpi"] = 300
plt.rcParams["savefig.dpi"] = 300
plt.rcParams["savefig.bbox"] = "tight"

BASELINE_COLOR     = "#7B8FA1"
INTERVENTION_COLOR = "#2E75B6"
KEY_METRICS = ["precision", "recall", "f1", "roc_auc", "pr_auc",
               "precision_top_1000", "precision_top_5000"]


def get_client():
    # Authenticates via GOOGLE_APPLICATION_CREDENTIALS env var (service account)
    # or application-default credentials (`gcloud auth application-default login`)
    return bigquery.Client(
        project="ecommerce-customer360"
    )


def fetch_metrics():
    client = get_client()
    query = """
        SELECT m.run_uuid, m.condition, m.metric_name, m.metric_value, r.run_index
        FROM `ecommerce-customer360.meta.experiment_metrics` m
        JOIN `meta.experiment_runs`    r USING (run_uuid, condition)
    """
    df = client.query(query).to_dataframe()
    df.columns = [c.lower() for c in df.columns]
    return df


# =====================================================================
# Plotters
# =====================================================================
def plot_box(df):
    fig, ax = plt.subplots(figsize=(10, 5))
    sub = df[df["metric_name"].isin(KEY_METRICS)].copy()
    sub["metric_name"] = pd.Categorical(sub["metric_name"], categories=KEY_METRICS)
    sns.boxplot(
        data=sub, x="metric_name", y="metric_value", hue="condition",
        palette={"BASELINE_RFM": BASELINE_COLOR, "INTERVENTION_ML": INTERVENTION_COLOR},
        ax=ax,
    )
    ax.set_title("Classifier metrics: 20 paired runs", fontweight="bold")
    ax.set_xlabel(""); ax.set_ylabel("Value")
    ax.legend(title="", loc="lower right")
    plt.xticks(rotation=20, ha="right")
    fig.savefig(OUT / "box_plot_metrics.png")
    plt.close(fig)


def plot_distribution_f1(df):
    fig, ax = plt.subplots(figsize=(8, 5))
    sub = df[df["metric_name"] == "f1"]
    sns.violinplot(
        data=sub, x="condition", y="metric_value",
        palette={"BASELINE_RFM": BASELINE_COLOR, "INTERVENTION_ML": INTERVENTION_COLOR},
        ax=ax, inner="point", cut=0,
    )
    ax.set_title("Distribution of F1 scores across 20 runs", fontweight="bold")
    ax.set_xlabel(""); ax.set_ylabel("F1")
    fig.savefig(OUT / "distribution_f1.png")
    plt.close(fig)


def plot_paired_diff(df):
    fig, ax = plt.subplots(figsize=(8, 5))
    sub = df[df["metric_name"] == "f1"].pivot_table(
        index="run_uuid", columns="condition", values="metric_value", aggfunc="first"
    ).dropna()
    for _, row in sub.iterrows():
        ax.plot([0, 1], [row["BASELINE_RFM"], row["INTERVENTION_ML"]],
                color="gray", alpha=0.4, marker="o")
    ax.scatter([0]*len(sub), sub["BASELINE_RFM"],     color=BASELINE_COLOR,     s=60, zorder=3, label="Baseline RFM")
    ax.scatter([1]*len(sub), sub["INTERVENTION_ML"], color=INTERVENTION_COLOR, s=60, zorder=3, label="Intervention ML")
    ax.set_xticks([0, 1])
    ax.set_xticklabels(["Baseline (RFM)", "Intervention (XGBoost)"])
    ax.set_ylabel("F1")
    ax.set_title("Paired F1 differences across 20 runs", fontweight="bold")
    ax.legend(loc="lower right")
    fig.savefig(OUT / "paired_diff_plot.png")
    plt.close(fig)


def plot_timeseries(df):
    fig, ax = plt.subplots(figsize=(10, 5))
    metrics_to_plot = ["f1", "precision", "recall"]
    for metric in metrics_to_plot:
        for cond, color in [("BASELINE_RFM", BASELINE_COLOR), ("INTERVENTION_ML", INTERVENTION_COLOR)]:
            sub = df[(df["metric_name"] == metric) & (df["condition"] == cond)] \
                  .sort_values("run_index")
            if sub.empty: continue
            ax.plot(sub["run_index"], sub["metric_value"],
                    marker="o", linewidth=1, alpha=0.75,
                    label=f"{cond.split('_')[0]} {metric}")
    ax.set_xlabel("Experimental run index")
    ax.set_ylabel("Metric value")
    ax.set_title("Metrics across 20 experimental runs", fontweight="bold")
    ax.legend(ncol=2, fontsize=8)
    fig.savefig(OUT / "metric_timeseries.png")
    plt.close(fig)


def plot_summary_radar(df):
    metrics = ["precision", "recall", "f1", "roc_auc", "pr_auc"]
    means = df.groupby(["condition", "metric_name"])["metric_value"].mean().unstack(fill_value=0)

    angles = np.linspace(0, 2 * np.pi, len(metrics), endpoint=False).tolist()
    angles += angles[:1]

    fig, ax = plt.subplots(figsize=(7, 7), subplot_kw={"projection": "polar"})
    for cond, color in [("BASELINE_RFM", BASELINE_COLOR), ("INTERVENTION_ML", INTERVENTION_COLOR)]:
        if cond not in means.index: continue
        values = [means.loc[cond, m] if m in means.columns else 0 for m in metrics]
        values += values[:1]
        ax.plot(angles, values, label=cond.replace("_", " "), color=color, linewidth=2)
        ax.fill(angles, values, color=color, alpha=0.18)

    ax.set_xticks(angles[:-1])
    ax.set_xticklabels([m.upper() for m in metrics])
    ax.set_ylim(0, 1)
    ax.set_title("Mean metric comparison (radar)", fontweight="bold", pad=20)
    ax.legend(loc="upper right", bbox_to_anchor=(1.25, 1.05))
    fig.savefig(OUT / "summary_radar.png")
    plt.close(fig)


def main():
    print("fetching metrics …")
    df = fetch_metrics()
    if df.empty:
        print("ERROR: no metrics found.")
        return

    print(f"  {df['run_uuid'].nunique()} runs, {df['metric_name'].nunique()} metrics")
    plot_box(df);                     print("  ✓ box_plot_metrics.png")
    plot_distribution_f1(df);         print("  ✓ distribution_f1.png")
    plot_paired_diff(df);             print("  ✓ paired_diff_plot.png")
    plot_timeseries(df);              print("  ✓ metric_timeseries.png")
    plot_summary_radar(df);           print("  ✓ summary_radar.png")
    print(f"\nall charts written to {OUT}")


if __name__ == "__main__":
    main()
