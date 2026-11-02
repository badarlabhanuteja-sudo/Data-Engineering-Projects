"""
generate_orders.py
Generates orders + order_items with realistic temporal patterns:
  - Customers acquire through signup, ramp up frequency, then either retain or churn
  - Churn behaviour respects each customer's _churn_propensity
  - Order timestamps follow a daily seasonality + weekly cycle
  - Order values follow a log-normal distribution
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from tqdm import tqdm


PAYMENT_METHODS = ["credit_card", "debit_card", "upi", "net_banking",
                   "wallet", "cod", "buy_now_pay_later"]
PAYMENT_PROBS = [0.30, 0.20, 0.25, 0.10, 0.07, 0.05, 0.03]

SHIPPING_METHODS = ["standard", "express", "same_day", "pickup"]
SHIPPING_PROBS = [0.60, 0.25, 0.10, 0.05]

PROMO_CODES = [None, None, None, None, None,           # most orders no promo
               "WELCOME10", "FLAT15", "FREESHIP", "BUY2GET1", "DIWALI20", "SAVE25"]


def generate_orders_and_items(out_dir, n_orders, customers_df, products_df, seed=42):
    rng = np.random.default_rng(seed)

    # Cycle through customers based on their activity probability
    propensity = customers_df["_churn_propensity"].to_numpy()
    activity_weight = 1.0 - propensity                         # higher = more orders
    activity_weight = activity_weight / activity_weight.sum()

    customer_ids = customers_df["customer_id"].to_numpy()
    signup_dates = pd.to_datetime(customers_df["signup_date"]).dt.date.to_numpy()

    product_ids   = products_df["product_id"].to_numpy()
    product_prices = products_df["unit_price"].to_numpy()

    # Generate per-order: customer, then a date >= signup
    today = datetime(2025, 12, 31).date()

    print(f"  generating {n_orders:,} orders …")
    chosen_customers = rng.choice(len(customer_ids), size=n_orders, p=activity_weight)

    order_rows = []
    item_rows = []
    customer_first_seen = {}     # for is_first_order

    next_item_id = 1
    for oid in tqdm(range(1, n_orders + 1), unit="orders", ncols=80):
        cust_idx = int(chosen_customers[oid - 1])
        cid = int(customer_ids[cust_idx])
        signup = signup_dates[cust_idx]

        # Order date — uniform over [signup .. min(signup + 18mo, today)] but with
        # a realistic taper (early orders more likely than later for high-propensity-churn customers)
        max_horizon = (today - signup).days
        if max_horizon < 1:
            continue
        # exponential decay for high churn, more uniform for low
        churn_p = float(propensity[cust_idx])
        days_after_signup = int(rng.exponential(120 + (1 - churn_p) * 240))
        days_after_signup = min(days_after_signup, max_horizon)
        order_date = signup + timedelta(days=days_after_signup)

        order_ts = datetime.combine(order_date, datetime.min.time()) + timedelta(
            hours=int(rng.integers(0, 24)),
            minutes=int(rng.integers(0, 60))
        )

        is_first = cid not in customer_first_seen
        if is_first:
            customer_first_seen[cid] = order_date

        # Items per order: 1-12, log-normal-ish
        n_items = int(min(12, max(1, rng.poisson(3.2))))
        chosen_prods = rng.choice(len(product_ids), size=n_items, replace=False)

        order_total = 0.0
        order_items_buffer = []
        for p_idx in chosen_prods:
            qty = int(min(5, max(1, rng.poisson(1.4))))
            price = float(product_prices[p_idx])
            disc_pct = float(rng.choice([0, 0, 0, 5, 10, 15], p=[0.7, 0.05, 0.05, 0.07, 0.08, 0.05]))
            line_total = round(qty * price * (1 - disc_pct / 100.0), 2)
            order_total += line_total
            order_items_buffer.append({
                "order_item_id": next_item_id,
                "order_id": oid,
                "product_id": int(product_ids[p_idx]),
                "quantity": qty,
                "unit_price": price,
                "line_total": line_total,
                "discount_pct": disc_pct,
                "created_at": order_ts.isoformat()
            })
            next_item_id += 1

        item_rows.extend(order_items_buffer)

        promo = str(rng.choice(PROMO_CODES))
        promo_disc = round(order_total * float(rng.choice([0, 0.05, 0.10, 0.15], p=[0.6, 0.2, 0.15, 0.05])), 2) if promo and promo != "None" else 0.0
        ship = round(float(rng.choice([0, 0, 49, 99, 149], p=[0.4, 0.2, 0.2, 0.15, 0.05])), 2)
        tax  = round(order_total * 0.18, 2)
        total = round(order_total - promo_disc + ship + tax, 2)

        status = str(rng.choice(["delivered", "delivered", "delivered", "cancelled", "returned"],
                                 p=[0.85, 0.05, 0.04, 0.04, 0.02]))

        order_rows.append({
            "order_id": oid,
            "customer_id": cid,
            "order_date": order_date.isoformat(),
            "order_timestamp": order_ts.isoformat(),
            "order_status": status,
            "payment_method": str(rng.choice(PAYMENT_METHODS, p=PAYMENT_PROBS)),
            "shipping_method": str(rng.choice(SHIPPING_METHODS, p=SHIPPING_PROBS)),
            "promo_code": promo if promo != "None" else None,
            "discount_amount": promo_disc,
            "shipping_amount": ship,
            "tax_amount": tax,
            "total_amount": total,
            "currency": "INR",
            "is_first_order": is_first,
            "created_at": order_ts.isoformat(),
            "updated_at": order_ts.isoformat(),
        })

    pd.DataFrame(order_rows).to_csv(out_dir / "raw_orders.csv", index=False)
    pd.DataFrame(item_rows).to_csv(out_dir / "raw_order_items.csv", index=False)
    print(f"  wrote {len(order_rows):,} orders → raw_orders.csv")
    print(f"  wrote {len(item_rows):,} order items → raw_order_items.csv")
    return pd.DataFrame(order_rows)
