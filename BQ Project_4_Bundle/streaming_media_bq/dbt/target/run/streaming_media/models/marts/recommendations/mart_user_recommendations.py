
  
    
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName('smallTest').getOrCreate()

spark.conf.set("viewsEnabled","true")
spark.conf.set("temporaryGcsBucket","None")
spark.conf.set("enableListInference", "True")


"""
mart_user_recommendations.py
BigQuery Python dbt model — collaborative-filtering recommender.

Approach: item-based collaborative filtering with implicit feedback.
For each user, recommend the top-K titles the user has not yet watched,
ranked by sum-of-similarity to titles the user has highly engaged with.

The implicit-feedback signal combines:
  - Explicit ratings (when available) on a 0-1 normalised scale.
  - Implicit completion events (a 'complete' event = strong positive signal).

This mart produces, for each user, the top-K recommended title_ids ordered
by predicted score. The empirical study compares:
  - BASELINE_NIGHTLY:    rebuilt once per day (T+24h freshness)
  - INTERVENTION_HOURLY: rebuilt every hour (T+1h freshness)

BigQuery Python models run on BigQuery Spark (serverless).
Required packages are declared in dbt.config(packages=[...]).
"""

import pandas as pd
import numpy as np


def model(dbt, session):
    dbt.config(
        materialized="table",
        # BigQuery Python models use BQ Spark — declare pip packages here
        packages=["pandas", "numpy", "scikit-learn==1.5.2"],
        tags=["recommender", "bigquery-python"]
    )

    # Pull explicit ratings + implicit completion events
    ratings_df = dbt.ref("stg_ratings").to_pandas()
    ratings_df.columns = [c.lower() for c in ratings_df.columns]

    views_df = dbt.ref("stg_view_events").to_pandas()
    views_df.columns = [c.lower() for c in views_df.columns]

    # Build a user-item interaction frame
    # Explicit: rating_normalized (already scaled 0-1)
    explicit = ratings_df[["user_id", "title_id", "rating_normalized"]].rename(
        columns={"rating_normalized": "score"})
    explicit["source"] = "rating"

    # Implicit: complete=1.0, play=0.3, abandon=-0.5, skip=-0.2
    implicit_map = {"complete": 1.0, "play": 0.3, "abandon": -0.5, "skip": -0.2}
    implicit = views_df[views_df["event_type"].isin(implicit_map.keys())].copy()
    implicit["score"] = implicit["event_type"].map(implicit_map)
    implicit = implicit.groupby(["user_id", "title_id"], as_index=False)["score"].max()
    implicit["source"] = "view"

    # Combine: take max signal per (user, title)
    interactions = pd.concat([explicit, implicit], ignore_index=True)
    interactions = interactions.groupby(["user_id", "title_id"], as_index=False)["score"].max()
    interactions = interactions[interactions["score"] > 0]   # positive only

    if len(interactions) == 0:
        empty = pd.DataFrame(columns=["user_id", "title_id", "rank",
                                       "predicted_score", "generated_at"])
        return session.createDataFrame(empty)

    # Build user-item matrix (sparse)
    from scipy.sparse import csr_matrix
    from sklearn.preprocessing import normalize

    user_idx = {u: i for i, u in enumerate(interactions["user_id"].unique())}
    item_idx = {t: i for i, t in enumerate(interactions["title_id"].unique())}
    inv_user = {v: k for k, v in user_idx.items()}
    inv_item = {v: k for k, v in item_idx.items()}

    rows = interactions["user_id"].map(user_idx).values
    cols = interactions["title_id"].map(item_idx).values
    vals = interactions["score"].values

    user_item = csr_matrix((vals, (rows, cols)),
                           shape=(len(user_idx), len(item_idx)),
                           dtype=np.float32)

    # Item-item cosine similarity (cap at top-2000 items to limit memory)
    item_norm = normalize(user_item.T, axis=1, norm="l2")
    top_items_count = min(2000, item_norm.shape[0])
    item_popularity = np.asarray(user_item.sum(axis=0)).flatten()
    top_items = np.argsort(-item_popularity)[:top_items_count]
    item_sim = (item_norm[top_items] @ item_norm.T).toarray()

    # For each user, recommend top-K unseen titles
    K = 10
    recommendations = []
    now = pd.Timestamp.utcnow()

    user_pop = np.asarray(user_item.sum(axis=1)).flatten()
    sample_users = np.argsort(-user_pop)[:5000]    # top 5000 most-active users

    for u in sample_users:
        watched = set(user_item[u].nonzero()[1])
        scores = np.zeros(len(top_items), dtype=np.float32)
        for w in watched:
            scores += item_sim[:, w]
        for k, item_pos in enumerate(top_items):
            if item_pos in watched:
                scores[k] = -np.inf
        topk_idx = np.argsort(-scores)[:K]
        for rank, k in enumerate(topk_idx, start=1):
            score = scores[k]
            if score == -np.inf or score <= 0:
                continue
            recommendations.append({
                "user_id":         int(inv_user[u]),
                "title_id":        int(inv_item[top_items[k]]),
                "rank":            rank,
                "predicted_score": float(score),
                "generated_at":    now.isoformat(),
            })

    out = pd.DataFrame(recommendations)
    if out.empty:
        out = pd.DataFrame(columns=["user_id", "title_id", "rank",
                                     "predicted_score", "generated_at"])

    # BigQuery Python models: return a Spark DataFrame
    return session.createDataFrame(out)


# This part is user provided model code
# you will need to copy the next section to run the code
# COMMAND ----------
# this part is dbt logic for get ref work, do not modify

def ref(*args, **kwargs):
    refs = {"stg_ratings": "streaming-media-498412.dbt_dev_staging.stg_ratings", "stg_view_events": "streaming-media-498412.dbt_dev_staging.stg_view_events"}
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
    database = "streaming-media-498412"
    schema = "dbt_dev_marts"
    identifier = "mart_user_recommendations"
    
    def __repr__(self):
        return 'streaming-media-498412.dbt_dev_marts.mart_user_recommendations'


class dbtObj:
    def __init__(self, load_df_function) -> None:
        self.source = lambda *args: source(*args, dbt_load_df_function=load_df_function)
        self.ref = lambda *args, **kwargs: ref(*args, **kwargs, dbt_load_df_function=load_df_function)
        self.config = config
        self.this = this()
        self.is_incremental = False

# COMMAND ----------



dbt = dbtObj(spark.read.format("bigquery").load)
df = model(dbt, spark)

# COMMAND ----------
# this is materialization code dbt generated, please do not modify

import pyspark
# make sure pandas exists before using it
try:
  import pandas
  pandas_available = True
except ImportError:
  pandas_available = False

# make sure pyspark.pandas exists before using it
try:
  import pyspark.pandas
  pyspark_pandas_api_available = True
except ImportError:
  pyspark_pandas_api_available = False

# make sure databricks.koalas exists before using it
try:
  import databricks.koalas
  koalas_available = True
except ImportError:
  koalas_available = False

# preferentially convert pandas DataFrames to pandas-on-Spark or Koalas DataFrames first
# since they know how to convert pandas DataFrames better than `spark.createDataFrame(df)`
# and converting from pandas-on-Spark to Spark DataFrame has no overhead
if pyspark_pandas_api_available and pandas_available and isinstance(df, pandas.core.frame.DataFrame):
  df = pyspark.pandas.frame.DataFrame(df)
elif koalas_available and pandas_available and isinstance(df, pandas.core.frame.DataFrame):
  df = databricks.koalas.frame.DataFrame(df)

# convert to pyspark.sql.dataframe.DataFrame
if isinstance(df, pyspark.sql.dataframe.DataFrame):
  pass  # since it is already a Spark DataFrame
elif pyspark_pandas_api_available and isinstance(df, pyspark.pandas.frame.DataFrame):
  df = df.to_spark()
elif koalas_available and isinstance(df, databricks.koalas.frame.DataFrame):
  df = df.to_spark()
elif pandas_available and isinstance(df, pandas.core.frame.DataFrame):
  df = spark.createDataFrame(df)
else:
  msg = f"{type(df)} is not a supported type for dbt Python materialization"
  raise Exception(msg)

# For writeMethod we need to use "indirect" if materializing a partitioned table
# otherwise we can use "direct". Note that indirect will fail if the GCS bucket has a retention policy set on it.
      

df.write \
  .mode("overwrite") \
  .format("bigquery") \
  .option("writeMethod", "direct") \
  .option("writeDisposition", 'WRITE_TRUNCATE') \
  .save("streaming-media-498412.dbt_dev_marts.mart_user_recommendations")

  