"""generate_sessions_and_views.py — sessions + view events with realistic engagement."""

import json
import uuid
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from tqdm import tqdm


DEVICES = ["smart_tv", "ios", "android", "web", "roku", "chromecast"]
DEVICE_PROBS = [0.32, 0.22, 0.20, 0.15, 0.06, 0.05]

OSS = {
    "smart_tv": ["LG WebOS", "Samsung Tizen", "Android TV"],
    "ios": ["iOS"],
    "android": ["Android"],
    "web": ["macOS", "Windows", "Linux"],
    "roku": ["RokuOS"],
    "chromecast": ["Chromecast"],
}

NETWORKS = ["wifi", "cellular", "ethernet"]
NET_PROBS = [0.65, 0.20, 0.15]

QUALITIES = ["480p", "720p", "1080p", "4k"]
QUAL_PROBS_BY_TIER = {
    "basic":    [0.55, 0.30, 0.15, 0.0],
    "standard": [0.20, 0.40, 0.40, 0.0],
    "premium":  [0.10, 0.20, 0.50, 0.20],
    "family":   [0.10, 0.20, 0.50, 0.20],
}


def generate_sessions_and_views(out_dir, n_sessions, n_views, users_df, titles_df, seed=42):
    rng = np.random.default_rng(seed + 1)

    today = datetime(2025, 12, 31)
    earliest = datetime(2025, 9, 1)

    user_ids   = users_df["user_id"].to_numpy()
    activity   = users_df["_activity"].to_numpy()
    activity_w = activity / activity.sum()
    user_country = users_df["country"].to_numpy()
    user_plan    = users_df["plan_tier"].to_numpy()

    title_ids   = titles_df["title_id"].to_numpy()
    title_runtime = titles_df["runtime_minutes"].fillna(45).to_numpy()
    title_lang  = titles_df["primary_language"].to_numpy()

    print(f"  generating {n_sessions:,} sessions and {n_views:,} view events …")

    chosen_users = rng.choice(len(user_ids), size=n_sessions, p=activity_w)

    session_rows = []
    # Build sessions
    for s in tqdm(range(n_sessions), unit="sessions", ncols=80):
        uix = int(chosen_users[s])
        uid = int(user_ids[uix])
        country = str(user_country[uix])

        seconds_offset = int(rng.integers(0, int((today - earliest).total_seconds())))
        start_ts = earliest + timedelta(seconds=seconds_offset)
        duration_min = int(min(180, max(2, rng.gamma(2, 25))))
        end_ts = start_ts + timedelta(minutes=duration_min)

        device = str(rng.choice(DEVICES, p=DEVICE_PROBS))
        os_choice = str(rng.choice(OSS[device]))
        sid = uuid.uuid4().hex
        session_rows.append({
            "session_id":     sid,
            "user_id":        uid,
            "profile_id":     uuid.uuid4().hex[:16],
            "device_type":    device,
            "device_os":      os_choice,
            "session_start":  start_ts.isoformat(),
            "session_end":    end_ts.isoformat(),
            "network_type":   str(rng.choice(NETWORKS, p=NET_PROBS)),
            "country":        country,
        })

    sessions_df = pd.DataFrame(session_rows)
    sessions_df.to_csv(out_dir / "raw_sessions.csv", index=False)
    print(f"  ✓ raw_sessions.csv        {len(sessions_df):,}")

    # Build view events on top of sessions
    print(f"  generating view events …")
    fname = out_dir / "raw_view_events.jsonl"
    sessions_lookup = sessions_df.set_index("session_id")[
        ["user_id", "session_start", "session_end"]].to_dict("index")

    chosen_sessions = rng.choice(len(sessions_df), size=n_views)

    with open(fname, "w") as f:
        for i in tqdm(range(n_views), unit="evts", ncols=80):
            srow = sessions_df.iloc[int(chosen_sessions[i])]
            uid  = int(srow["user_id"])
            ssec = pd.Timestamp(srow["session_start"])
            esec = pd.Timestamp(srow["session_end"])
            duration_total = (esec - ssec).total_seconds()
            if duration_total <= 0: continue
            event_offset = int(rng.uniform(0, duration_total))
            ts = ssec + timedelta(seconds=event_offset)

            tix = int(rng.integers(0, len(title_ids)))
            tid = int(title_ids[tix])
            runtime_sec = int(title_runtime[tix]) * 60

            etype = str(rng.choice(["play","pause","resume","complete","abandon","skip"],
                                    p=[0.30, 0.20, 0.20, 0.10, 0.15, 0.05]))

            quality_probs = QUAL_PROBS_BY_TIER.get(str(user_plan[uid - 1]), QUAL_PROBS_BY_TIER["basic"])
            quality = str(rng.choice(QUALITIES, p=quality_probs))

            playback_pos = int(rng.uniform(0, max(1, runtime_sec)))
            event = {
                "view_event_id":  uuid.uuid4().hex,
                "session_id":     srow["session_id"],
                "user_id":        uid,
                "title_id":       tid,
                "event_type":     etype,
                "event_timestamp": ts.isoformat(),
                "playback_position_sec": playback_pos,
                "quality_level":  quality,
                "buffering_seconds": round(float(rng.exponential(0.3)), 2),
                "payload":        {
                    "device":        srow["device_type"],
                    "network":       str(rng.choice(NETWORKS, p=NET_PROBS)),
                },
            }
            f.write(json.dumps(event) + "\n")

    print(f"  ✓ raw_view_events.jsonl   {n_views:,}")
    return sessions_df
