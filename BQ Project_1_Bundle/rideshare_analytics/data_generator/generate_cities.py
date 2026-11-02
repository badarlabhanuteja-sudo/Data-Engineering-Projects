"""
generate_cities.py
Ten Indian cities with realistic coordinates, populations, and timezones.
"""

import pandas as pd

# (city_id, name, state, country, timezone, population, lat, lng)
CITIES = [
    (1,  "Mumbai",     "Maharashtra",     "IN", "Asia/Kolkata", 20411000, 19.0760, 72.8777),
    (2,  "Delhi",      "Delhi",           "IN", "Asia/Kolkata", 28514000, 28.7041, 77.1025),
    (3,  "Bengaluru",  "Karnataka",       "IN", "Asia/Kolkata", 12326000, 12.9716, 77.5946),
    (4,  "Chennai",    "Tamil Nadu",      "IN", "Asia/Kolkata", 10456000, 13.0827, 80.2707),
    (5,  "Kolkata",    "West Bengal",     "IN", "Asia/Kolkata", 14681000, 22.5726, 88.3639),
    (6,  "Hyderabad",  "Telangana",       "IN", "Asia/Kolkata", 10004000, 17.3850, 78.4867),
    (7,  "Pune",       "Maharashtra",     "IN", "Asia/Kolkata",  6630000, 18.5204, 73.8567),
    (8,  "Ahmedabad",  "Gujarat",         "IN", "Asia/Kolkata",  7681000, 23.0225, 72.5714),
    (9,  "Jaipur",     "Rajasthan",       "IN", "Asia/Kolkata",  3046000, 26.9124, 75.7873),
    (10, "Kochi",      "Kerala",          "IN", "Asia/Kolkata",  2120000,  9.9312, 76.2673),
]


def generate_cities(out_dir):
    rows = [{
        "city_id":      c[0],
        "city_name":    c[1],
        "state":        c[2],
        "country_code": c[3],
        "timezone":     c[4],
        "population":   c[5],
        "is_active":    True,
        # coords kept locally for downstream generators (not persisted)
        "_lat":         c[6],
        "_lng":         c[7],
    } for c in CITIES]
    df = pd.DataFrame(rows)
    df.drop(columns=["_lat", "_lng"]).to_csv(out_dir / "raw_cities.csv", index=False)
    print(f"  wrote {len(df)} cities → raw_cities.csv")
    return df
