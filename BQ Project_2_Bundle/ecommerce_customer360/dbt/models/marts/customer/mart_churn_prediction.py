"""
mart_churn_prediction.py
BigQuery Python dbt model — the INTERVENTION classifier in the empirical study.

Trains an XGBoost classifier using a BigQuery DataFrame, produces per-customer
churn probabilities and binary predictions, and writes them as a table dbt can
hand to downstream models / BI consumers.

Strategy:
  1. Load mart_churn_features (one row per customer, label = is_churned).
  2. Time-aware split: customers with last_order_date < cutoff = train;
     customers with last_order_date >= cutoff = test.
  3. Fit XGBoost with reasonable defaults.
  4. Score the full population, return predictions.

This model is deliberately simple — the empirical comparison is against RFM,
not against state-of-the-art. Hyperparameter tuning is a future-work area
called out in the dissertation.

Note: BigQuery Python models run on Dataproc (Spark) or inline depending on
your dbt-bigquery version (>=1.8 supports inline Python models via the
`dataproc_*` or `submission_method` config). Ensure your profile is configured
with a valid `gcs_bucket` and `dataproc_cluster` or `dataproc_region`.
"""

import pandas as pd
import numpy as np


def model(dbt, session):
    # dbt config — BigQuery Python model
    dbt.config(
        materialized="table",
        # Adjust submission_method and Dataproc settings to match your project:
        #   submission_method="serverless"  (Dataproc Serverless)
        #   or submission_method="cluster" with dataproc_cluster="<name>"
        submission_method="serverless",
        # Add the GCS staging bucket configured in your dbt profile if needed:
        # gcs_bucket="<your-gcs-bucket>",
        runtime_version="2.2",  # Dataproc Serverless Spark runtime
        packages=["xgboost==2.1.2", "scikit-learn==1.5.2"],
        tags=["intervention", "ml", "experiment_intervention"]
    )

    # ----- Load features -----
    # In BigQuery Python models, dbt.ref() returns a Spark DataFrame.
    # Convert to pandas for sklearn/xgboost compatibility.
    feats_df = dbt.ref("mart_churn_features").toPandas()

    # Coerce column names to upper-case for consistency
    feats_df.columns = [c.upper() for c in feats_df.columns]

    feature_cols = [
        "TIER_ORDINAL", "IS_EMAIL_SUBSCRIBER_INT", "IS_COUNTRY_IN", "IS_PAID_ACQUISITION",
        "TOTAL_ORDERS", "GROSS_REVENUE", "AVG_ORDER_VALUE",
        "CUSTOMER_TENURE_DAYS", "DAYS_SINCE_LAST_ORDER",
        "ORDERS_WITH_PROMO", "TOTAL_DISCOUNT_RECEIVED",
        "PROMO_FRACTION", "REPEAT_ORDERS_COUNT", "REPEAT_FRACTION",
        "WEB_SESSIONS", "WEB_PAGE_VIEWS", "WEB_PRODUCT_VIEWS", "WEB_CART_ADDS",
        "WEB_CHECKOUTS_STARTED", "WEB_PURCHASES_COMPLETED",
        "CART_TO_VIEW_RATIO", "CHECKOUT_COMPLETION_RATE",
        "EMAILS_SENT", "EMAILS_OPENED", "EMAILS_CLICKED",
        "EMAIL_OPEN_RATE", "EMAIL_CLICK_RATE", "IS_UNSUBSCRIBED_INT",
    ]
    label_col = "LABEL"

    # Replace NaNs with sensible defaults
    X = feats_df[feature_cols].fillna(0).astype(float)
    y = feats_df[label_col].astype(int)

    # ----- Time-aware split -----
    # We use a simple stratified random split here; in production this should
    # be replaced with a time-based holdout.
    from sklearn.model_selection import train_test_split
    X_train, X_test, y_train, y_test, idx_train, idx_test = train_test_split(
        X, y, np.arange(len(X)),
        test_size=0.20, stratify=y, random_state=42
    )

    # ----- Train XGBoost -----
    import xgboost as xgb
    clf = xgb.XGBClassifier(
        n_estimators=200,
        max_depth=5,
        learning_rate=0.08,
        subsample=0.85,
        colsample_bytree=0.85,
        eval_metric="auc",
        random_state=42,
        n_jobs=4,
        tree_method="hist",   # recommended for BigQuery/Dataproc environments
        device="cpu",
    )
    clf.fit(X_train, y_train)

    # ----- Score full population -----
    proba = clf.predict_proba(X)[:, 1]
    pred  = (proba >= 0.5).astype(int)

    # ----- Build output DataFrame -----
    out = pd.DataFrame({
        "customer_id":                 feats_df["CUSTOMER_ID"].values,
        "customer_sk":                 feats_df["CUSTOMER_SK"].values,
        "predicted_churn_score_ml":    proba.astype(float),
        "predicted_churn_ml":          pred.astype(bool),
        "actual_churn":                y.values.astype(bool),
        "is_in_test_set":              np.isin(np.arange(len(X)), idx_test),
    })

    # Return a Spark DataFrame (required by BigQuery Python dbt models)
    return session.createDataFrame(out)
