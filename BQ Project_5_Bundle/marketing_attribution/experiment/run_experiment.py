"""
run_experiment.py
Bootstrapped 5-model attribution comparison.

For 20 bootstrap iterations:
  1. Sample N conversions with replacement from int_conversion_paths.
  2. Compute each of the 5 attribution models on the resampled data.
  3. Record per-channel revenue allocation and resulting recommended budget.

The 20 paired observations per (model, channel) form the basis for:
  - Friedman test: do the 5 models produce significantly different
    per-channel revenue allocations on the same data?
  - Pairwise Wilcoxon: which model pairs differ most?
  - Cohen's d: effect size of the disagreement.
  - Kendall tau: do model-recommended budgets agree on rank-order?
"""

import os
import sys
import time
import uuid
from pathlib import Path
from datetime import datetime
import numpy as np
import pandas as pd
from dotenv import load_dotenv
import snowflake.connector

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

NUM_RUNS  = int(os.environ.get("EXPERIMENT_NUM_RUNS", "20"))
BASE_SEED = int(os.environ.get("EXPERIMENT_RANDOM_SEED", "42"))


def get_conn():
    return snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        role=os.environ.get("SNOWFLAKE_ROLE", "DBT_ROLE"),
        warehouse="EXPT_WH_S",
        database=os.environ.get("SNOWFLAKE_DATABASE", "MARKETING_DB"),
    )


def fetch_conversion_paths():
    c = get_conn(); cur = c.cursor()
    cur.execute("""
        SELECT conversion_id, channel, event_timestamp, hours_to_conversion,
               touch_position, path_length, is_first_touch, is_last_touch, revenue
          FROM MARKETING_DB.MARTS.INT_CONVERSION_PATHS
    """)
    cols = [d[0].lower() for d in cur.description]
    df = pd.DataFrame(cur.fetchall(), columns=cols)
    cur.close(); c.close()
    return df


def fetch_total_spend():
    c = get_conn(); cur = c.cursor()
    cur.execute("SELECT SUM(spend_amount) FROM MARKETING_DB.STAGING.STG_AD_SPEND")
    total = cur.fetchone()[0] or 0
    cur.close(); c.close()
    return float(total)


# =====================================================================
# Attribution models — each takes path-frame, returns per-channel revenue
# =====================================================================

def first_touch(df):
    sub = df[df["is_first_touch"]]
    return sub.groupby("channel")["revenue"].sum()


def last_touch(df):
    sub = df[df["is_last_touch"]]
    return sub.groupby("channel")["revenue"].sum()


def linear(df):
    df = df.copy()
    df["alloc"] = df["revenue"] / df["path_length"]
    return df.groupby("channel")["alloc"].sum()


def time_decay(df, half_life_days=7):
    df = df.copy()
    df["w"] = np.exp(-df["hours_to_conversion"] / (half_life_days * 24.0))
    sums = df.groupby("conversion_id")["w"].transform("sum")
    df["alloc"] = df["revenue"] * df["w"] / sums
    return df.groupby("channel")["alloc"].sum()


def markov(df):
    """Removal-effect Markov chain attribution."""
    paths = (df.sort_values(["conversion_id", "touch_position"])
               .groupby("conversion_id")
               .agg(path=("channel", list), revenue=("revenue", "first"))
               .reset_index())

    total_revenue = float(paths["revenue"].sum())
    channels = sorted(set(c for p in paths["path"] for c in p))
    states = ["START"] + channels + ["CONVERSION"]
    sidx = {s: i for i, s in enumerate(states)}
    n = len(states)

    T = np.zeros((n, n))
    for p in paths["path"]:
        prev = "START"
        for ch in p:
            T[sidx[prev], sidx[ch]] += 1
            prev = ch
        T[sidx[prev], sidx["CONVERSION"]] += 1

    rs = T.sum(axis=1, keepdims=True); rs[rs == 0] = 1.0
    P = T / rs

    def conv_prob(M):
        v = np.zeros(n); v[sidx["START"]] = 1.0
        for _ in range(50):
            v = v @ M
        return float(v[sidx["CONVERSION"]])

    base = conv_prob(P)
    contrib = {}
    for ch in channels:
        Pr = P.copy()
        i = sidx[ch]
        Pr[:, i] = 0; Pr[i, :] = 0
        rs = Pr.sum(axis=1, keepdims=True); rs[rs == 0] = 1.0
        Pr = Pr / rs
        contrib[ch] = max(0.0, base - conv_prob(Pr))

    total = sum(contrib.values())
    if total == 0:
        normalised = {ch: 1.0 / len(channels) for ch in channels}
    else:
        normalised = {ch: v / total for ch, v in contrib.items()}

    return pd.Series({ch: normalised[ch] * total_revenue for ch in channels})


MODELS = {
    "first_touch": first_touch,
    "last_touch":  last_touch,
    "linear":      linear,
    "time_decay":  time_decay,
    "markov":      markov,
}


# =====================================================================
# Persistence
# =====================================================================
def insert_run(cur, run_uuid, model, run_index, started_at, completed_at):
    cur.execute("""
        INSERT INTO META.experiment_runs
          (run_uuid, model, run_index, started_at, completed_at, duration_seconds)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (run_uuid, model, run_index, started_at.isoformat(),
          completed_at.isoformat(), (completed_at - started_at).total_seconds()))


def insert_attribution(cur, run_uuid, model, channel, revenue, share, recommended):
    cur.execute("""
        INSERT INTO META.experiment_attribution
          (run_uuid, model, channel, attributed_revenue, attributed_share, recommended_budget)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (run_uuid, model, channel, float(revenue),
          float(share), float(recommended)))


# =====================================================================
def main():
    print(f"=== experiment ===  num_runs={NUM_RUNS}  seed={BASE_SEED}\n")

    print("loading conversion paths …")
    full_df = fetch_conversion_paths()
    print(f"  {len(full_df):,} touchpoint-conversion rows, "
          f"{full_df['conversion_id'].nunique():,} conversions")

    if full_df.empty:
        print("ERROR: no data — run dbt first."); sys.exit(1)

    total_spend = fetch_total_spend()
    print(f"  total ad spend (for budget reallocation): {total_spend:,.0f} INR\n")

    conn = get_conn(); cur = conn.cursor()
    rng = np.random.default_rng(BASE_SEED)

    conversion_ids = full_df["conversion_id"].unique()

    for run_idx in range(NUM_RUNS):
        run_uuid = uuid.uuid4().hex
        seed = BASE_SEED + run_idx
        print(f"run {run_idx+1}/{NUM_RUNS}  uuid={run_uuid[:8]}")

        # bootstrap sample of conversions
        sampled_ids = rng.choice(conversion_ids, size=len(conversion_ids), replace=True)
        sample_df   = full_df[full_df["conversion_id"].isin(set(sampled_ids))].copy()

        for model_name, model_fn in MODELS.items():
            t0 = datetime.utcnow()
            channel_revenue = model_fn(sample_df)
            t1 = datetime.utcnow()

            total = float(channel_revenue.sum())
            insert_run(cur, run_uuid, model_name, run_idx, t0, t1)

            for ch, rev in channel_revenue.items():
                share = float(rev) / total if total > 0 else 0.0
                recommended = share * total_spend
                insert_attribution(cur, run_uuid, model_name, str(ch),
                                   float(rev), share, recommended)
            conn.commit()
            print(f"    {model_name:<12s} done  "
                  f"({(t1-t0).total_seconds():.2f}s, {len(channel_revenue)} channels)")

    cur.close(); conn.close()
    print("\n=== experiment complete ===")
    print("next: python /workspace/experiment/statistical_analysis.py")


if __name__ == "__main__":
    main()
