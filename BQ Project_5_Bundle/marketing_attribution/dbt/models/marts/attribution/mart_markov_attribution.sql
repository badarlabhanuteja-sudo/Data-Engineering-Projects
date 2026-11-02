-- mart_markov_attribution.sql
-- Markov-chain attribution model (pure SQL — no Dataproc / GCS required)
-- Converted from mart_markov_attribution.py
-- Implements removal-effect Markov attribution (Anderl et al., 2016; Shao & Li, 2011)

{{ config(
    materialized = 'table',
    tags         = ['attribution', 'markov']
) }}

-- ── 1. Raw paths ────────────────────────────────────────────────────────────
WITH paths AS (
    SELECT
        conversion_id,
        channel,
        touch_position,
        path_length,
        revenue
    FROM {{ ref('int_conversion_paths') }}
),

-- ── 2. Per-conversion path summary ─────────────────────────────────────────
conversion_summary AS (
    SELECT
        COUNT(DISTINCT conversion_id) AS total_conversions,
        SUM(revenue / NULLIF(path_length, 0)) AS total_revenue
    FROM paths
),

-- ── 3. Build transition counts (START → ch → ... → CONVERSION) ─────────────
-- Self-join consecutive touchpoints within each conversion
transitions_raw AS (
    -- channel → next channel
    SELECT
        a.channel AS from_state,
        b.channel AS to_state
    FROM paths a
    JOIN paths b
      ON a.conversion_id = b.conversion_id
     AND b.touch_position = a.touch_position + 1

    UNION ALL

    -- START → first channel
    SELECT
        'START'   AS from_state,
        channel   AS to_state
    FROM paths
    WHERE touch_position = 1

    UNION ALL

    -- last channel → CONVERSION
    SELECT
        a.channel  AS from_state,
        'CONVERSION' AS to_state
    FROM paths a
    WHERE NOT EXISTS (
        SELECT 1 FROM paths b
        WHERE b.conversion_id = a.conversion_id
          AND b.touch_position = a.touch_position + 1
    )
),

-- ── 4. Aggregate transition counts ─────────────────────────────────────────
transition_counts AS (
    SELECT
        from_state,
        to_state,
        COUNT(*) AS cnt
    FROM transitions_raw
    GROUP BY from_state, to_state
),

-- Row totals per from_state (for normalisation)
row_totals AS (
    SELECT from_state, SUM(cnt) AS total
    FROM transition_counts
    GROUP BY from_state
),

-- Transition probabilities P(from → to)
transition_probs AS (
    SELECT
        tc.from_state,
        tc.to_state,
        tc.cnt / rt.total AS prob
    FROM transition_counts tc
    JOIN row_totals rt USING (from_state)
),

-- ── 5. Distinct channels ────────────────────────────────────────────────────
channels AS (
    SELECT DISTINCT channel
    FROM paths
),

-- ── 6. Baseline conversion probability via 50-step power iteration ──────────
-- We approximate P(START → CONVERSION) by iterating the transition matrix.
-- BigQuery doesn't have loops, so we unroll 10 hops (sufficient for most path lengths).
-- Each CTE step = one matrix-vector multiplication.

iter0 AS (
    -- Initial state vector: probability 1.0 on START
    SELECT from_state AS state, prob AS weight
    FROM transition_probs
    WHERE from_state = 'START'
),
iter1  AS (SELECT tp.to_state AS state, SUM(i.weight * tp.prob) AS weight FROM iter0  i JOIN transition_probs tp ON tp.from_state = i.state GROUP BY tp.to_state),
iter2  AS (SELECT tp.to_state AS state, SUM(i.weight * tp.prob) AS weight FROM iter1  i JOIN transition_probs tp ON tp.from_state = i.state GROUP BY tp.to_state),
iter3  AS (SELECT tp.to_state AS state, SUM(i.weight * tp.prob) AS weight FROM iter2  i JOIN transition_probs tp ON tp.from_state = i.state GROUP BY tp.to_state),
iter4  AS (SELECT tp.to_state AS state, SUM(i.weight * tp.prob) AS weight FROM iter3  i JOIN transition_probs tp ON tp.from_state = i.state GROUP BY tp.to_state),
iter5  AS (SELECT tp.to_state AS state, SUM(i.weight * tp.prob) AS weight FROM iter4  i JOIN transition_probs tp ON tp.from_state = i.state GROUP BY tp.to_state),
iter6  AS (SELECT tp.to_state AS state, SUM(i.weight * tp.prob) AS weight FROM iter5  i JOIN transition_probs tp ON tp.from_state = i.state GROUP BY tp.to_state),
iter7  AS (SELECT tp.to_state AS state, SUM(i.weight * tp.prob) AS weight FROM iter6  i JOIN transition_probs tp ON tp.from_state = i.state GROUP BY tp.to_state),
iter8  AS (SELECT tp.to_state AS state, SUM(i.weight * tp.prob) AS weight FROM iter7  i JOIN transition_probs tp ON tp.from_state = i.state GROUP BY tp.to_state),
iter9  AS (SELECT tp.to_state AS state, SUM(i.weight * tp.prob) AS weight FROM iter8  i JOIN transition_probs tp ON tp.from_state = i.state GROUP BY tp.to_state),
iter10 AS (SELECT tp.to_state AS state, SUM(i.weight * tp.prob) AS weight FROM iter9  i JOIN transition_probs tp ON tp.from_state = i.state GROUP BY tp.to_state),

baseline AS (
    SELECT COALESCE(SUM(weight), 0) AS baseline_prob
    FROM iter10
    WHERE state = 'CONVERSION'
),

-- ── 7. Removal-effect per channel ──────────────────────────────────────────
-- For each channel C, zero out its column and row, re-normalise, re-iterate.

removed_probs AS (
    SELECT
        ch.channel AS removed_channel,
        -- Re-normalise transition matrix with channel removed
        tp.from_state,
        tp.to_state,
        CASE
            WHEN tp.from_state = ch.channel OR tp.to_state = ch.channel THEN 0
            ELSE tp.prob
        END AS prob_raw
    FROM channels ch
    CROSS JOIN transition_probs tp
),

-- Re-normalise rows after removal
removed_row_totals AS (
    SELECT removed_channel, from_state, SUM(prob_raw) AS row_total
    FROM removed_probs
    GROUP BY removed_channel, from_state
),

removed_probs_norm AS (
    SELECT
        rp.removed_channel,
        rp.from_state,
        rp.to_state,
        CASE
            WHEN COALESCE(rt.row_total, 0) = 0 THEN 0
            ELSE rp.prob_raw / rt.row_total
        END AS prob
    FROM removed_probs rp
    LEFT JOIN removed_row_totals rt
           ON rt.removed_channel = rp.removed_channel
          AND rt.from_state      = rp.from_state
),

-- Power iteration for each removed-channel graph (10 hops)
r0  AS (SELECT removed_channel, to_state AS state, prob AS weight FROM removed_probs_norm WHERE from_state = 'START'),
r1  AS (SELECT r.removed_channel, tp.to_state AS state, SUM(r.weight * tp.prob) AS weight FROM r0  r JOIN removed_probs_norm tp ON tp.removed_channel = r.removed_channel AND tp.from_state = r.state GROUP BY r.removed_channel, tp.to_state),
r2  AS (SELECT r.removed_channel, tp.to_state AS state, SUM(r.weight * tp.prob) AS weight FROM r1  r JOIN removed_probs_norm tp ON tp.removed_channel = r.removed_channel AND tp.from_state = r.state GROUP BY r.removed_channel, tp.to_state),
r3  AS (SELECT r.removed_channel, tp.to_state AS state, SUM(r.weight * tp.prob) AS weight FROM r2  r JOIN removed_probs_norm tp ON tp.removed_channel = r.removed_channel AND tp.from_state = r.state GROUP BY r.removed_channel, tp.to_state),
r4  AS (SELECT r.removed_channel, tp.to_state AS state, SUM(r.weight * tp.prob) AS weight FROM r3  r JOIN removed_probs_norm tp ON tp.removed_channel = r.removed_channel AND tp.from_state = r.state GROUP BY r.removed_channel, tp.to_state),
r5  AS (SELECT r.removed_channel, tp.to_state AS state, SUM(r.weight * tp.prob) AS weight FROM r4  r JOIN removed_probs_norm tp ON tp.removed_channel = r.removed_channel AND tp.from_state = r.state GROUP BY r.removed_channel, tp.to_state),
r6  AS (SELECT r.removed_channel, tp.to_state AS state, SUM(r.weight * tp.prob) AS weight FROM r5  r JOIN removed_probs_norm tp ON tp.removed_channel = r.removed_channel AND tp.from_state = r.state GROUP BY r.removed_channel, tp.to_state),
r7  AS (SELECT r.removed_channel, tp.to_state AS state, SUM(r.weight * tp.prob) AS weight FROM r6  r JOIN removed_probs_norm tp ON tp.removed_channel = r.removed_channel AND tp.from_state = r.state GROUP BY r.removed_channel, tp.to_state),
r8  AS (SELECT r.removed_channel, tp.to_state AS state, SUM(r.weight * tp.prob) AS weight FROM r7  r JOIN removed_probs_norm tp ON tp.removed_channel = r.removed_channel AND tp.from_state = r.state GROUP BY r.removed_channel, tp.to_state),
r9  AS (SELECT r.removed_channel, tp.to_state AS state, SUM(r.weight * tp.prob) AS weight FROM r8  r JOIN removed_probs_norm tp ON tp.removed_channel = r.removed_channel AND tp.from_state = r.state GROUP BY r.removed_channel, tp.to_state),
r10 AS (SELECT r.removed_channel, tp.to_state AS state, SUM(r.weight * tp.prob) AS weight FROM r9  r JOIN removed_probs_norm tp ON tp.removed_channel = r.removed_channel AND tp.from_state = r.state GROUP BY r.removed_channel, tp.to_state),

removed_conv_prob AS (
    SELECT removed_channel, COALESCE(SUM(weight), 0) AS prob_without
    FROM r10
    WHERE state = 'CONVERSION'
    GROUP BY removed_channel
),

-- ── 8. Raw contribution = baseline − prob_without ───────────────────────────
raw_contributions AS (
    SELECT
        rcp.removed_channel                                    AS channel,
        GREATEST(0, b.baseline_prob - rcp.prob_without)       AS contribution
    FROM removed_conv_prob rcp
    CROSS JOIN baseline b
),

total_contribution AS (
    SELECT SUM(contribution) AS total FROM raw_contributions
),

-- ── 9. Normalise & compute attributed revenue ───────────────────────────────
normalised AS (
    SELECT
        rc.channel,
        CASE
            WHEN tc.total = 0 THEN 1.0 / (SELECT COUNT(*) FROM channels)
            ELSE rc.contribution / tc.total
        END AS attributed_share
    FROM raw_contributions rc
    CROSS JOIN total_contribution tc
)

-- ── 10. Final output ────────────────────────────────────────────────────────
SELECT
    'markov'                                                   AS model,
    n.channel,
    cs.total_conversions                                       AS attributed_conversions,
    ROUND(n.attributed_share * cs.total_revenue, 2)           AS attributed_revenue,
    n.attributed_share
FROM normalised n
CROSS JOIN conversion_summary cs
ORDER BY attributed_revenue DESC
