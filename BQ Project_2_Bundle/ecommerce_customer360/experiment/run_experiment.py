import os
import sys
import uuid
from pathlib import Path
from datetime import datetime, timezone
import numpy as np
import pandas as pd
from dotenv import load_dotenv
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    precision_score, recall_score, f1_score,
    roc_auc_score, average_precision_score, brier_score_loss
)
import xgboost as xgb
from google.cloud import bigquery

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

GCP_PROJECT = "ecommerce-customer360"
NUM_RUNS    = int(os.environ.get("EXPERIMENT_NUM_RUNS",    "20"))
BASE_SEED   = int(os.environ.get("EXPERIMENT_RANDOM_SEED", "42"))

BQ_CLIENT = bigquery.Client(project="ecommerce-customer360", credentials=google.oauth2.service_account.Credentials.from_service_account_file(os.environ["GOOGLE_APPLICATION_CREDENTIALS"]))

def fetch_features() -> pd.DataFrame:
    sql = f"""
        SELECT customer_id, label,
          tier_ordinal, is_email_subscriber_int, is_country_in, is_paid_acquisition,
          total_orders, gross_revenue, avg_order_value,
          customer_tenure_days, days_since_last_order,
          orders_with_promo, total_discount_received,
          promo_fraction, repeat_orders_count, repeat_fraction,
          web_sessions, web_page_views, web_product_views, web_cart_adds,
          web_checkouts_started, web_purchases_completed,
          cart_to_view_ratio, checkout_completion_rate,
          emails_sent, emails_opened, emails_clicked,
          email_open_rate, email_click_rate, is_unsubscribed_int
        FROM `{GCP_PROJECT}.marts.mart_churn_features`
    """
    return BQ_CLIENT.query(sql).to_dataframe()

def baseline_rfm(df_train, df_test):
    q = df_train["days_since_last_order"].quantile([0.2, 0.4, 0.6, 0.8]).values
    def predict(row):
        d = row["days_since_last_order"]
        if d <= q[0]:   return 5, 0.10
        elif d <= q[1]: return 4, 0.30
        elif d <= q[2]: return 3, 0.50
        elif d <= q[3]: return 2, 0.70
        else:           return 1, 0.90
    rs = df_test.apply(predict, axis=1, result_type="expand")
    rs.columns = ["r_score", "score"]
    return (rs["score"] >= 0.6).astype(int).values, rs["score"].values

def intervention_ml(df_train, df_test, seed):
    feature_cols = [
        "tier_ordinal", "is_email_subscriber_int", "is_country_in", "is_paid_acquisition",
        "total_orders", "gross_revenue", "avg_order_value",
        "customer_tenure_days", "days_since_last_order",
        "orders_with_promo", "total_discount_received",
        "promo_fraction", "repeat_orders_count", "repeat_fraction",
        "web_sessions", "web_page_views", "web_product_views", "web_cart_adds",
        "web_checkouts_started", "web_purchases_completed",
        "cart_to_view_ratio", "checkout_completion_rate",
        "emails_sent", "emails_opened", "emails_clicked",
        "email_open_rate", "email_click_rate", "is_unsubscribed_int",
    ]
    X_train = df_train[feature_cols].fillna(0).astype(float)
    y_train = df_train["label"].astype(int)
    X_test  = df_test[feature_cols].fillna(0).astype(float)
    clf = xgb.XGBClassifier(
        n_estimators=200, max_depth=5, learning_rate=0.08,
        subsample=0.85, colsample_bytree=0.85,
        eval_metric="auc", random_state=seed, n_jobs=4,
    )
    clf.fit(X_train, y_train)
    proba = clf.predict_proba(X_test)[:, 1]
    return (proba >= 0.5).astype(int), proba

def evaluate(y_true, y_pred, y_score):
    return {
        "precision":  precision_score(y_true, y_pred, zero_division=0),
        "recall":     recall_score(y_true, y_pred, zero_division=0),
        "f1":         f1_score(y_true, y_pred, zero_division=0),
        "roc_auc":    roc_auc_score(y_true, y_score) if len(np.unique(y_true)) > 1 else float("nan"),
        "pr_auc":     average_precision_score(y_true, y_score) if len(np.unique(y_true)) > 1 else float("nan"),
        "brier":      brier_score_loss(y_true, y_score),
        "precision_top_1000": precision_at_k(y_true, y_score, 1000),
        "precision_top_5000": precision_at_k(y_true, y_score, 5000),
    }

def precision_at_k(y_true, y_score, k):
    if len(y_true) == 0:
        return float("nan")
    k = min(k, len(y_true))
    idx = np.argsort(-y_score)[:k]
    return float(y_true.iloc[idx].sum()) / k if hasattr(y_true, "iloc") else \
           float(np.array(y_true)[idx].sum()) / k

def main():
    print(f"=== experiment ===  num_runs={NUM_RUNS}  base_seed={BASE_SEED}\n")
    print(f"BigQuery project: {GCP_PROJECT}\n")
    print("loading features from marts.mart_churn_features …")
    df = fetch_features()
    df.columns = [c.lower() for c in df.columns]
    print(f"  → {len(df):,} rows, churn rate = {df['label'].mean():.3f}")
    if df["label"].nunique() < 2:
        print("ERROR: feature table has only one class; cannot run experiment.")
        sys.exit(1)

    all_metrics = []
    all_runs = []

    for run_idx in range(NUM_RUNS):
        seed     = BASE_SEED + run_idx
        run_uuid = uuid.uuid4().hex
        print(f"\nrun {run_idx + 1}/{NUM_RUNS}  seed={seed}  uuid={run_uuid[:8]}")
        df_train, df_test = train_test_split(
            df, test_size=0.20, stratify=df["label"], random_state=seed
        )
        y_test = df_test["label"].astype(int)

        t0 = datetime.now(timezone.utc)
        b_pred, b_score = baseline_rfm(df_train, df_test)
        t1 = datetime.now(timezone.utc)
        b_metrics = evaluate(y_test, b_pred, b_score)
        for name, val in b_metrics.items():
            all_metrics.append({"metric_id": int(uuid.uuid4().int % 2147483647), "run_uuid": run_uuid, "condition": "BASELINE_RFM", "metric_name": name, "metric_value": float(val), "captured_at": datetime.now(timezone.utc).isoformat()})
        all_runs.append({"run_id": int(uuid.uuid4().int % 2147483647), "run_uuid": run_uuid, "condition": "BASELINE_RFM", "run_index": run_idx, "started_at": t0.isoformat(), "completed_at": t1.isoformat(), "duration_seconds": (t1-t0).total_seconds(), "rows_in": len(df_train), "rows_out": len(df_test)})
        print(f"  baseline   F1={b_metrics['f1']:.3f}  ROC-AUC={b_metrics['roc_auc']:.3f}")

        t0 = datetime.now(timezone.utc)
        i_pred, i_score = intervention_ml(df_train, df_test, seed)
        t1 = datetime.now(timezone.utc)
        i_metrics = evaluate(y_test, i_pred, i_score)
        for name, val in i_metrics.items():
            all_metrics.append({"metric_id": int(uuid.uuid4().int % 2147483647), "run_uuid": run_uuid, "condition": "INTERVENTION_ML", "metric_name": name, "metric_value": float(val), "captured_at": datetime.now(timezone.utc).isoformat()})
        all_runs.append({"run_id": int(uuid.uuid4().int % 2147483647), "run_uuid": run_uuid, "condition": "INTERVENTION_ML", "run_index": run_idx, "started_at": t0.isoformat(), "completed_at": t1.isoformat(), "duration_seconds": (t1-t0).total_seconds(), "rows_in": len(df_train), "rows_out": len(df_test)})
        print(f"  ml         F1={i_metrics['f1']:.3f}  ROC-AUC={i_metrics['roc_auc']:.3f}")

    print("\nInserting all results to BigQuery...")
    BQ_CLIENT.load_table_from_json(all_metrics, f"{GCP_PROJECT}.meta.experiment_metrics").result()
    BQ_CLIENT.load_table_from_json(all_runs, f"{GCP_PROJECT}.meta.experiment_runs").result()
    print("Inserted successfully!")
    print("\n=== experiment complete ===")

if __name__ == "__main__":
    main()
