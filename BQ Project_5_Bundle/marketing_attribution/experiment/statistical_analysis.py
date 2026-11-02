"""
statistical_analysis.py
For the 5-model attribution comparison:

  - Friedman test:     do the 5 models give significantly different per-channel
                       revenue allocations on the same data? (per channel)
  - Pairwise Wilcoxon: which model pairs differ most on a given channel?
  - Cohen's d:         effect size of disagreement.
  - Kendall tau:       do recommended-budget rankings agree across models?
  - Reallocation magnitude: max % difference in channel allocation between any
                       two models.
"""

import os
import json
from pathlib import Path
import numpy as np
import pandas as pd
from dotenv import load_dotenv
from scipy import stats
import snowflake.connector

load_dotenv(Path(__file__).resolve().parent.parent / ".env")
OUT = Path(__file__).resolve().parent / "results"
OUT.mkdir(exist_ok=True)


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


def cohens_d(x, y):
    diff = np.array(x) - np.array(y)
    return float(diff.mean() / (diff.std(ddof=1) + 1e-12))


def main():
    df = fetch()
    if df.empty:
        print("no metrics — run run_experiment.py first"); return

    print(f"loaded {len(df):,} attribution records "
          f"({df['run_uuid'].nunique()} runs × "
          f"{df['model'].nunique()} models × "
          f"{df['channel'].nunique()} channels)\n")

    models = sorted(df["model"].unique())
    channels = sorted(df["channel"].unique())

    # ---- 1. Friedman test per channel --------------------------------
    friedman_rows = []
    for ch in channels:
        # rows = run_uuid, columns = model, values = attributed_share
        sub = df[df["channel"] == ch].pivot_table(
            index="run_uuid", columns="model",
            values="attributed_share", aggfunc="first"
        ).dropna()

        if len(sub) < 5 or len(sub.columns) < 3:
            continue

        # Friedman expects each column as a separate sample (paired)
        try:
            stat, p = stats.friedmanchisquare(*[sub[m].values for m in sub.columns])
        except Exception:
            stat, p = float("nan"), float("nan")

        friedman_rows.append({
            "channel": ch,
            "n_runs": len(sub),
            "n_models": len(sub.columns),
            "friedman_statistic": float(stat) if not np.isnan(stat) else None,
            "friedman_p_value": float(p) if not np.isnan(p) else None,
            "significant_at_0p05": (not np.isnan(p)) and p < 0.05,
            **{f"mean_share_{m}": float(sub[m].mean()) for m in sub.columns}
        })

    friedman_df = pd.DataFrame(friedman_rows).sort_values("channel")
    friedman_df.to_csv(OUT / "friedman_by_channel.csv", index=False)
    print(f"  Friedman test results → {OUT}/friedman_by_channel.csv")
    print(friedman_df[["channel", "friedman_p_value", "significant_at_0p05"]].to_string(index=False))
    print()

    # ---- 2. Pairwise Wilcoxon per channel ----------------------------
    pairwise_rows = []
    for ch in channels:
        sub = df[df["channel"] == ch].pivot_table(
            index="run_uuid", columns="model",
            values="attributed_share", aggfunc="first"
        ).dropna()
        if len(sub) < 5: continue
        for i, m1 in enumerate(models):
            for m2 in models[i+1:]:
                if m1 not in sub.columns or m2 not in sub.columns: continue
                a, b = sub[m1].values, sub[m2].values
                try:
                    w_stat, p = stats.wilcoxon(a, b, zero_method="wilcox")
                except ValueError:
                    w_stat, p = float("nan"), float("nan")
                pairwise_rows.append({
                    "channel": ch, "model_a": m1, "model_b": m2,
                    "mean_diff": float((a - b).mean()),
                    "wilcoxon_p": float(p) if not np.isnan(p) else None,
                    "cohens_d": cohens_d(a, b),
                    "significant_at_0p05": (not np.isnan(p)) and p < 0.05,
                })
    pd.DataFrame(pairwise_rows).to_csv(OUT / "pairwise_wilcoxon.csv", index=False)
    print(f"  Pairwise Wilcoxon → {OUT}/pairwise_wilcoxon.csv")

    # ---- 3. Reallocation magnitude per channel -----------------------
    realloc_rows = []
    for ch in channels:
        sub = df[df["channel"] == ch].groupby("model")["attributed_share"].mean()
        if len(sub) < 2: continue
        realloc_rows.append({
            "channel": ch,
            "min_share":   float(sub.min()),
            "max_share":   float(sub.max()),
            "spread":      float(sub.max() - sub.min()),
            "spread_pct":  float((sub.max() - sub.min()) / max(sub.mean(), 1e-9)),
            "by_model":    sub.to_dict(),
        })
    realloc_df = pd.DataFrame(realloc_rows).sort_values("spread", ascending=False)
    realloc_df.to_csv(OUT / "reallocation_magnitude.csv", index=False)
    print(f"  Reallocation magnitude → {OUT}/reallocation_magnitude.csv")
    print(realloc_df[["channel", "spread", "spread_pct"]].to_string(index=False))
    print()

    # ---- 4. Kendall tau across model recommendations -----------------
    # For each pair of models, rank their channel recommendations and
    # compute Kendall tau correlation.
    rec = df.groupby(["model", "channel"])["recommended_budget"].mean().unstack(fill_value=0)
    tau_rows = []
    for i, m1 in enumerate(models):
        for m2 in models[i+1:]:
            if m1 not in rec.index or m2 not in rec.index: continue
            tau, p = stats.kendalltau(rec.loc[m1].values, rec.loc[m2].values)
            tau_rows.append({
                "model_a": m1, "model_b": m2,
                "kendall_tau": float(tau) if not np.isnan(tau) else None,
                "p_value":    float(p) if not np.isnan(p) else None,
            })
    pd.DataFrame(tau_rows).to_csv(OUT / "kendall_tau.csv", index=False)
    print(f"  Kendall tau (rank-agreement) → {OUT}/kendall_tau.csv")

    # Combined summary JSON for the dissertation
    summary = {
        "n_runs":   int(df["run_uuid"].nunique()),
        "models":   models,
        "channels": channels,
        "friedman": friedman_rows,
        "pairwise": pairwise_rows,
        "reallocation": realloc_rows,
        "kendall_tau": tau_rows,
    }
    with open(OUT / "statistical_summary.json", "w") as f:
        json.dump(summary, f, indent=2, default=str)
    print(f"\n  Combined JSON → {OUT}/statistical_summary.json")


if __name__ == "__main__":
    main()
