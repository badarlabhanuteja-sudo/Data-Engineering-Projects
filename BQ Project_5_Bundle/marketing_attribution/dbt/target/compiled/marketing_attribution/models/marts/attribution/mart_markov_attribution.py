"""
mart_markov_attribution.py
BigQuery Python dbt model for Markov-chain attribution.

The Markov-chain method (Anderl et al., 2016; Shao & Li, 2011) computes each
channel's contribution to overall conversion probability via a removal-effect
analysis:

  1. Build a transition matrix from observed paths: states = {channels} +
     {start, conversion, null}.
  2. Compute baseline conversion probability of the full graph.
  3. For each channel C, "remove" C from the graph and re-compute conversion
     probability. The drop equals C's contribution.
  4. Normalise contributions to 1.0; multiply by total revenue.

NOTE: BigQuery dbt Python models run on Dataproc Serverless.
Ensure your BigQuery connection has Dataproc configured, or convert this
model to SQL using the equivalent logic commented below.
"""

import pandas as pd
import numpy as np


def model(dbt, session):
    dbt.config(
        materialized="table",
        tags=["attribution", "markov"]
    )

    # Load input data as a pandas DataFrame
    paths_df = dbt.ref("int_conversion_paths").to_pandas()
    paths_df.columns = [c.lower() for c in paths_df.columns]

    # Order touchpoints by conversion + position
    paths_df = paths_df.sort_values(["conversion_id", "touch_position"])

    # Build per-conversion path lists
    conversions = paths_df.groupby("conversion_id").agg(
        path=("channel", list),
        revenue=("revenue", "first"),
    ).reset_index()

    # Total revenue (the universe to redistribute)
    total_revenue = float(conversions["revenue"].sum())

    # All distinct channels (states)
    channels = sorted(set(c for path in conversions["path"] for c in path))
    states = ["START"] + channels + ["CONVERSION"]
    state_idx = {s: i for i, s in enumerate(states)}
    n = len(states)

    # ---- Build transition matrix from observed paths -----------------
    transitions = np.zeros((n, n), dtype=float)
    for path in conversions["path"]:
        prev = "START"
        for ch in path:
            transitions[state_idx[prev], state_idx[ch]] += 1
            prev = ch
        transitions[state_idx[prev], state_idx["CONVERSION"]] += 1

    # Row-normalise to probabilities
    row_sums = transitions.sum(axis=1, keepdims=True)
    row_sums[row_sums == 0] = 1.0
    P = transitions / row_sums

    # ---- Baseline conversion probability ----------------------------
    def conv_prob(P_mat):
        v = np.zeros(n)
        v[state_idx["START"]] = 1.0
        for _ in range(50):
            v = v @ P_mat
        return float(v[state_idx["CONVERSION"]])

    baseline = conv_prob(P)

    # ---- Removal-effect per channel ---------------------------------
    contributions = {}
    for ch in channels:
        P_removed = P.copy()
        idx = state_idx[ch]
        P_removed[:, idx] = 0
        P_removed[idx, :] = 0
        rs = P_removed.sum(axis=1, keepdims=True)
        rs[rs == 0] = 1.0
        P_removed = P_removed / rs
        prob_without = conv_prob(P_removed)
        contributions[ch] = max(0.0, baseline - prob_without)

    # Normalise so contributions sum to 1.0
    total_contrib = sum(contributions.values())
    if total_contrib == 0:
        normalised = {ch: 1.0 / len(channels) for ch in channels}
    else:
        normalised = {ch: v / total_contrib for ch, v in contributions.items()}

    # Build output dataframe
    rows = []
    for ch in channels:
        share = float(normalised[ch])
        rev   = round(share * total_revenue, 2)
        rows.append({
            "model": "markov",
            "channel": ch,
            "attributed_conversions": int(len(conversions)),
            "attributed_revenue": rev,
            "attributed_share": share,
        })

    out = pd.DataFrame(rows).sort_values("attributed_revenue", ascending=False)
    return out


# This part is user provided model code
# you will need to copy the next section to run the code
# COMMAND ----------
# this part is dbt logic for get ref work, do not modify

def ref(*args, **kwargs):
    refs = {"int_conversion_paths": "marketing-attribution-498615.raw.int_conversion_paths"}
    key = '.'.join(args)
    version = kwargs.get("v") or kwargs.get("version")
    if version:
        key += f".v{version}"
    dbt_load_df_function = kwargs.get("dbt_load_df_function")
    return dbt_load_df_function(refs[key])


def source(*args, dbt_load_df_function):
    sources = {}
    key = '.'.join(args)
    return dbt_load_df_function(sources[key])


config_dict = {}
meta_dict = {}


class config:
    def __init__(self, *args, **kwargs):
        pass

    @staticmethod
    def get(key, default=None):
        return config_dict.get(key, default)

    @staticmethod
    def meta_get(key, default=None):
        return meta_dict.get(key, default)

class this:
    """dbt.this() or dbt.this.identifier"""
    database = "marketing-attribution-498615"
    schema = "analytics"
    identifier = "mart_markov_attribution"
    
    def __repr__(self):
        return 'marketing-attribution-498615.analytics.mart_markov_attribution'


class dbtObj:
    def __init__(self, load_df_function) -> None:
        self.source = lambda *args: source(*args, dbt_load_df_function=load_df_function)
        self.ref = lambda *args, **kwargs: ref(*args, **kwargs, dbt_load_df_function=load_df_function)
        self.config = config
        self.this = this()
        self.is_incremental = False

# COMMAND ----------


