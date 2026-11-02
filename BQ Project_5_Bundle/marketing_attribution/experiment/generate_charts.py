"""
generate_charts.py
Five publication-quality charts for the dissertation Results chapter.

  1. attribution_grouped_bar.png   - per-channel revenue share, 5 models side by side
  2. reallocation_heatmap.png      - heatmap of disagreement (channel × model)
  3. paired_diff_violin.png        - per-channel violin of the 5-model spread
  4. budget_recommendation.png     - recommended budget delta vs current spend
  5. summary_radar.png             - radar of mean attributed share across channels
"""

import os
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from dotenv import load_dotenv
import snowflake.connector

load_dotenv(Path(__file__).resolve().parent.parent / ".env")
OUT = Path(__file__).resolve().parent / "results" / "charts"
OUT.mkdir(parents=True, exist_ok=True)

sns.set_theme(style="whitegrid", context="paper", font_scale=1.05)
plt.rcParams.update({"figure.dpi": 300, "savefig.dpi": 300, "savefig.bbox": "tight"})

MODEL_COLORS = {
    "first_touch": "#7B8FA1",
    "last_touch":  "#C0504D",
    "linear":      "#9BBB59",
    "time_decay":  "#F79646",
    "markov":      "#2E75B6",
}


def get_conn():
    return snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        role=os.environ.get("SNOWFLAKE_ROLE", "DBT_ROLE"),
        warehouse="EXPT_WH_S",
        database=os.environ.get("SNOWFLAKE_DATABASE", "MARKETING_DB"),
        schema="META",
    )


def fetch():
    c = get_conn(); cur = c.cursor()
    cur.execute("""
        SELECT run_uuid, model, channel,
               attributed_revenue, attributed_share, recommended_budget
          FROM META.experiment_attribution
    """)
    cols = [d[0].lower() for d in cur.description]
    df = pd.DataFrame(cur.fetchall(), columns=cols)
    cur.close(); c.close()
    return df


def fetch_current_spend():
    c = get_conn(); cur = c.cursor()
    cur.execute("SELECT channel, SUM(spend_amount) FROM MARKETING_DB.STAGING.STG_AD_SPEND GROUP BY 1")
    rows = cur.fetchall()
    cur.close(); c.close()
    return {r[0]: float(r[1]) for r in rows}


def plot_grouped_bar(df):
    fig, ax = plt.subplots(figsize=(10, 5))
    means = df.groupby(["channel", "model"])["attributed_share"].mean().unstack()
    if not means.empty:
        means = means[[m for m in MODEL_COLORS.keys() if m in means.columns]]
        means.plot(kind="bar", ax=ax,
                   color=[MODEL_COLORS[m] for m in means.columns], edgecolor="white")
    ax.set_title("Attribution share by channel and model (mean over runs)", fontweight="bold")
    ax.set_xlabel(""); ax.set_ylabel("Attributed share")
    ax.legend(title="Model", bbox_to_anchor=(1.02, 1), loc="upper left")
    plt.xticks(rotation=20, ha="right")
    fig.savefig(OUT / "attribution_grouped_bar.png"); plt.close(fig)


def plot_reallocation_heatmap(df):
    means = df.groupby(["channel", "model"])["attributed_share"].mean().unstack()
    if means.empty: return
    means = means[[m for m in MODEL_COLORS.keys() if m in means.columns]]
    fig, ax = plt.subplots(figsize=(8, 5))
    sns.heatmap(means, annot=True, fmt=".3f", cmap="RdYlBu_r",
                cbar_kws={"label": "Attributed share"}, ax=ax)
    ax.set_title("Channel × Model attribution heatmap", fontweight="bold")
    ax.set_xlabel("Model"); ax.set_ylabel("Channel")
    fig.savefig(OUT / "reallocation_heatmap.png"); plt.close(fig)


def plot_paired_diff_violin(df):
    fig, ax = plt.subplots(figsize=(10, 5))
    sns.violinplot(data=df, x="channel", y="attributed_share", hue="model",
                   palette=MODEL_COLORS, ax=ax, cut=0, inner=None)
    ax.set_title("Per-channel distribution of attributed share across models", fontweight="bold")
    ax.set_xlabel(""); ax.set_ylabel("Attributed share")
    ax.legend(title="Model", bbox_to_anchor=(1.02, 1), loc="upper left", fontsize=8)
    plt.xticks(rotation=20, ha="right")
    fig.savefig(OUT / "paired_diff_violin.png"); plt.close(fig)


def plot_budget_recommendation(df, current_spend):
    rec = df.groupby(["model", "channel"])["recommended_budget"].mean().reset_index()
    rec["current_spend"]      = rec["channel"].map(current_spend).fillna(0)
    rec["recommended_change"] = rec["recommended_budget"] - rec["current_spend"]

    fig, ax = plt.subplots(figsize=(10, 5))
    pivot = rec.pivot(index="channel", columns="model", values="recommended_change")
    if not pivot.empty:
        pivot = pivot[[m for m in MODEL_COLORS.keys() if m in pivot.columns]]
        pivot.plot(kind="bar", ax=ax,
                   color=[MODEL_COLORS[m] for m in pivot.columns], edgecolor="white")
    ax.axhline(0, color="black", linewidth=0.8)
    ax.set_title("Recommended budget change vs current spend (per model)", fontweight="bold")
    ax.set_xlabel(""); ax.set_ylabel("Δ Spend (positive = increase)")
    ax.legend(title="Model", bbox_to_anchor=(1.02, 1), loc="upper left", fontsize=8)
    plt.xticks(rotation=20, ha="right")
    fig.savefig(OUT / "budget_recommendation.png"); plt.close(fig)


def plot_summary_radar(df):
    means = df.groupby(["model", "channel"])["attributed_share"].mean().unstack(fill_value=0)
    if means.empty: return

    channels = list(means.columns)
    angles = np.linspace(0, 2 * np.pi, len(channels), endpoint=False).tolist()
    angles += angles[:1]

    fig, ax = plt.subplots(figsize=(8, 8), subplot_kw={"projection": "polar"})
    for model in means.index:
        if model not in MODEL_COLORS: continue
        values = means.loc[model].tolist() + [means.loc[model].iloc[0]]
        ax.plot(angles, values, color=MODEL_COLORS[model], linewidth=2, label=model)
        ax.fill(angles, values, color=MODEL_COLORS[model], alpha=0.10)
    ax.set_xticks(angles[:-1])
    ax.set_xticklabels(channels)
    ax.set_title("Attribution share — radar comparison", fontweight="bold", pad=20)
    ax.legend(loc="upper right", bbox_to_anchor=(1.30, 1.10))
    fig.savefig(OUT / "summary_radar.png"); plt.close(fig)


def main():
    df = fetch()
    if df.empty:
        print("no metrics — run run_experiment.py first"); return
    print(f"{df['run_uuid'].nunique()} runs, {df['model'].nunique()} models, "
          f"{df['channel'].nunique()} channels")

    cs = fetch_current_spend()
    plot_grouped_bar(df);             print("  ✓ attribution_grouped_bar.png")
    plot_reallocation_heatmap(df);    print("  ✓ reallocation_heatmap.png")
    plot_paired_diff_violin(df);      print("  ✓ paired_diff_violin.png")
    plot_budget_recommendation(df, cs); print("  ✓ budget_recommendation.png")
    plot_summary_radar(df);           print("  ✓ summary_radar.png")
    print(f"\nall charts → {OUT}")


if __name__ == "__main__":
    main()
