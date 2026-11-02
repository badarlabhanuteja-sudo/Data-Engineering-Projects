"""generate_charts.py — 5 publication-quality charts.

BigQuery-compatible: replaces snowflake.connector with google-cloud-bigquery.
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

PROJECT_ID = os.environ["GCP_PROJECT_ID"]
OUT        = Path(__file__).resolve().parent / "results" / "charts"
OUT.mkdir(parents=True, exist_ok=True)

sns.set_theme(style="whitegrid", context="paper", font_scale=1.05)
plt.rcParams.update({"figure.dpi": 300, "savefig.dpi": 300, "savefig.bbox": "tight"})

BASELINE_COLOR     = "#7B8FA1"
INTERVENTION_COLOR = "#2E75B6"
KEY = ["hit_rate_at_10", "ndcg_at_10", "coverage_at_10", "rec_age_hours", "credits_used"]


def get_client() -> bigquery.Client:
    return bigquery.Client(project=PROJECT_ID)


def fetch() -> pd.DataFrame:
    client = get_client()
    sql = f"""
        SELECT m.run_uuid, m.condition, m.metric_name, m.metric_value, r.run_index
          FROM `{PROJECT_ID}.meta.experiment_metrics` m
          JOIN `{PROJECT_ID}.meta.experiment_runs`    r
            ON m.run_uuid = r.run_uuid AND m.condition = r.condition
    """
    return client.query(sql).to_dataframe()


def plot_box(df: pd.DataFrame) -> None:
    fig, ax = plt.subplots(figsize=(10, 5))
    sub = df[df["metric_name"].isin(KEY)].copy()
    sub["metric_name"] = pd.Categorical(sub["metric_name"], categories=KEY)
    sns.boxplot(
        data=sub, x="metric_name", y="metric_value", hue="condition",
        palette={"BASELINE_NIGHTLY": BASELINE_COLOR,
                 "INTERVENTION_HOURLY": INTERVENTION_COLOR}, ax=ax
    )
    ax.set_yscale("symlog")
    ax.set_title("Recommender quality + cost: 20 paired runs", fontweight="bold")
    ax.set_xlabel(""); ax.set_ylabel("Value (symlog scale)")
    plt.xticks(rotation=20, ha="right")
    fig.savefig(OUT / "box_plot_metrics.png"); plt.close(fig)


def plot_hit_rate_distribution(df: pd.DataFrame) -> None:
    fig, ax = plt.subplots(figsize=(8, 5))
    sub = df[df["metric_name"] == "hit_rate_at_10"]
    sns.violinplot(
        data=sub, x="condition", y="metric_value",
        palette={"BASELINE_NIGHTLY": BASELINE_COLOR,
                 "INTERVENTION_HOURLY": INTERVENTION_COLOR},
        ax=ax, inner="point", cut=0
    )
    ax.set_title("Distribution of Hit-Rate@10", fontweight="bold")
    ax.set_xlabel(""); ax.set_ylabel("Hit-Rate@10")
    fig.savefig(OUT / "hit_rate_distribution.png"); plt.close(fig)


def plot_paired_ndcg(df: pd.DataFrame) -> None:
    fig, ax = plt.subplots(figsize=(8, 5))
    sub = df[df["metric_name"] == "ndcg_at_10"].pivot_table(
        index="run_uuid", columns="condition", values="metric_value",
        aggfunc="first"
    ).dropna()
    for _, row in sub.iterrows():
        ax.plot([0, 1], [row["BASELINE_NIGHTLY"], row["INTERVENTION_HOURLY"]],
                color="gray", alpha=0.4, marker="o")
    ax.scatter([0]*len(sub), sub["BASELINE_NIGHTLY"],
               color=BASELINE_COLOR,     s=60, zorder=3, label="Nightly")
    ax.scatter([1]*len(sub), sub["INTERVENTION_HOURLY"],
               color=INTERVENTION_COLOR, s=60, zorder=3, label="Hourly")
    ax.set_xticks([0, 1])
    ax.set_xticklabels(["Baseline (Nightly)", "Intervention (Hourly)"])
    ax.set_ylabel("NDCG@10")
    ax.set_title("Paired NDCG@10 differences across 20 runs", fontweight="bold")
    ax.legend(loc="best")
    fig.savefig(OUT / "paired_ndcg.png"); plt.close(fig)


def plot_freshness_vs_quality(df: pd.DataFrame) -> None:
    fig, ax = plt.subplots(figsize=(8, 5))
    wide = df.pivot_table(
        index=["run_uuid", "condition"], columns="metric_name",
        values="metric_value", aggfunc="first"
    ).reset_index()
    for cond, color in [("BASELINE_NIGHTLY", BASELINE_COLOR),
                        ("INTERVENTION_HOURLY", INTERVENTION_COLOR)]:
        sub = wide[wide["condition"] == cond]
        if (not sub.empty
                and "rec_age_hours" in sub.columns
                and "ndcg_at_10" in sub.columns):
            ax.scatter(sub["rec_age_hours"], sub["ndcg_at_10"],
                       color=color, s=60, alpha=0.7,
                       label=cond.replace("_", " ").title())
    ax.set_xlabel("Recommendation age (hours)")
    ax.set_ylabel("NDCG@10")
    ax.set_title("Freshness vs recommendation quality", fontweight="bold")
    ax.legend()
    fig.savefig(OUT / "freshness_vs_quality.png"); plt.close(fig)


def plot_summary_radar(df: pd.DataFrame) -> None:
    metrics = ["hit_rate_at_10", "ndcg_at_10", "coverage_at_10"]
    means   = df.groupby(["condition", "metric_name"])["metric_value"].mean().unstack(fill_value=0)
    angles  = np.linspace(0, 2 * np.pi, len(metrics), endpoint=False).tolist()
    angles += angles[:1]
    fig, ax = plt.subplots(figsize=(7, 7), subplot_kw={"projection": "polar"})
    for cond, color in [("BASELINE_NIGHTLY", BASELINE_COLOR),
                        ("INTERVENTION_HOURLY", INTERVENTION_COLOR)]:
        if cond not in means.index:
            continue
        values = [means.loc[cond, m] if m in means.columns else 0 for m in metrics]
        values += values[:1]
        ax.plot(angles, values, color=color, linewidth=2,
                label=cond.replace("_", " ").title())
        ax.fill(angles, values, color=color, alpha=0.18)
    ax.set_xticks(angles[:-1])
    ax.set_xticklabels([m.upper() for m in metrics])
    ax.set_ylim(0, 1)
    ax.set_title("Mean recommender metrics — radar", fontweight="bold", pad=20)
    ax.legend(loc="upper right", bbox_to_anchor=(1.30, 1.10))
    fig.savefig(OUT / "summary_radar.png"); plt.close(fig)


def main() -> None:
    df = fetch()
    if df.empty:
        print("no metrics — run run_experiment.py first")
        return
    print(f"{df['run_uuid'].nunique()} runs, {df['metric_name'].nunique()} metrics")
    plot_box(df);                   print("  ✓ box_plot_metrics.png")
    plot_hit_rate_distribution(df); print("  ✓ hit_rate_distribution.png")
    plot_paired_ndcg(df);           print("  ✓ paired_ndcg.png")
    plot_freshness_vs_quality(df);  print("  ✓ freshness_vs_quality.png")
    plot_summary_radar(df);         print("  ✓ summary_radar.png")
    print(f"\nall charts → {OUT}")


if __name__ == "__main__":
    main()
