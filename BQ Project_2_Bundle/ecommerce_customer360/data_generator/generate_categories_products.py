"""
generate_categories_products.py
Generates a small category taxonomy and a larger product catalogue.
"""

import pandas as pd
import numpy as np
from faker import Faker
from datetime import datetime, timedelta


CATEGORY_TAXONOMY = [
    # (category_id, name, parent, department)
    (1,  "Beverages",          None, "Grocery"),
    (2,  "Snacks",              None, "Grocery"),
    (3,  "Dairy",               None, "Grocery"),
    (4,  "Produce",             None, "Grocery"),
    (5,  "Bakery",              None, "Grocery"),
    (6,  "Meat & Seafood",      None, "Grocery"),
    (7,  "Frozen",              None, "Grocery"),
    (8,  "Pantry",              None, "Grocery"),
    (9,  "Household",           None, "Home"),
    (10, "Personal Care",       None, "Health"),
    (11, "Baby",                None, "Family"),
    (12, "Pet Supplies",        None, "Family"),
    (13, "Coffee & Tea",        1,    "Grocery"),
    (14, "Soft Drinks",         1,    "Grocery"),
    (15, "Juice & Water",       1,    "Grocery"),
    (16, "Chips",               2,    "Grocery"),
    (17, "Cookies",             2,    "Grocery"),
    (18, "Candy",               2,    "Grocery"),
    (19, "Milk",                3,    "Grocery"),
    (20, "Yogurt",              3,    "Grocery"),
    (21, "Cheese",              3,    "Grocery"),
    (22, "Fresh Fruit",         4,    "Grocery"),
    (23, "Fresh Vegetables",    4,    "Grocery"),
    (24, "Bread",               5,    "Grocery"),
    (25, "Cleaning Supplies",   9,    "Home"),
    (26, "Paper Products",      9,    "Home"),
    (27, "Skincare",            10,   "Health"),
    (28, "Vitamins",            10,   "Health"),
    (29, "Diapers",             11,   "Family"),
    (30, "Pet Food",            12,   "Family"),
]

BRANDS = [
    "Acme", "BlueLeaf", "Coastal", "DairyCrown", "Evergreen", "FieldFresh",
    "GoldenGrain", "Heritage", "IronOak", "Jubilee", "Kingfisher", "Lakeside",
    "MountainPure", "Northstar", "Orchard", "Pinewood", "Quartz", "Riverbed",
    "Sunbloom", "Trailmark", "Urbanleaf", "Velvet", "Wildflower", "Xenith",
    "Yellowstone", "Zenith"
]


def generate_categories(out_dir, seed=42):
    rows = [{
        "category_id": cid,
        "category_name": name,
        "parent_category_id": parent,
        "department": dept
    } for cid, name, parent, dept in CATEGORY_TAXONOMY]
    df = pd.DataFrame(rows)
    df.to_csv(out_dir / "raw_categories.csv", index=False)
    print(f"  wrote {len(df):,} categories → raw_categories.csv")
    return df


def generate_products(out_dir, n, categories_df, seed=42):
    rng = np.random.default_rng(seed)
    fake = Faker()
    Faker.seed(seed)

    # Only leaf categories (those that are parents to nothing else? we use the listed leaves)
    leaf_cat_ids = [13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30]

    rows = []
    today = datetime(2025, 12, 31).date()
    for pid in range(1, n + 1):
        cat_id = int(rng.choice(leaf_cat_ids))
        cost = round(float(rng.gamma(2.0, 1.8) + 0.5), 2)
        markup = float(rng.uniform(1.25, 2.5))
        price = round(cost * markup, 2)
        is_active = bool(rng.random() < 0.95)
        launch = today - timedelta(days=int(rng.integers(30, 1500)))
        created = launch
        # some products updated more recently
        updated = launch + timedelta(days=int(rng.integers(0, 365)))
        rows.append({
            "product_id": pid,
            "product_name": f"{fake.word().capitalize()} {fake.word().capitalize()} {pid}",
            "category_id": cat_id,
            "brand": str(rng.choice(BRANDS)),
            "supplier": fake.company(),
            "unit_price": price,
            "cost": cost,
            "is_active": is_active,
            "launch_date": launch.isoformat(),
            "created_at": datetime.combine(created, datetime.min.time()).isoformat(),
            "updated_at": datetime.combine(updated, datetime.min.time()).isoformat(),
        })

    df = pd.DataFrame(rows)
    df.to_csv(out_dir / "raw_products.csv", index=False)
    print(f"  wrote {len(df):,} products → raw_products.csv")
    return df
