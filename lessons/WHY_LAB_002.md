# WHY_LAB_002 — Hybrid Interface Tax and Phase Synchronization

**Mode:** GROK BABY SCHOLAR  
**Status:** READY_FOR_EXECUTION  
**Authority:** false

## Research Question

Does a hybrid mobile-plus-Chromebook workflow outperform either device alone when phase synchronization and authentication handoff costs are controlled?

## Observed Inputs

```text
HYBRID_E_COST = 106
HYBRID_PRIOR_BASELINE = 87.4
HYBRID_DIVERGENCE = +18.6
CB_RAW_THROUGHPUT_MS = 67
CB_PHASE_STABILITY = 7
T_COMMIT = 94
auth_fails = 14
T_COMMIT_WEIGHT = 0.4
auth_weight = 0.6
phase_weight = 15
AUTHORITY = false
```

## Cost Function

```text
E_cost = (T_commit × 0.4) + (auth_fails × 0.6) + (|mismatch| × phase_weight)
```

For the current hybrid run:

```text
T_commit component = 94 × 0.4 = 37.6
auth component = 14 × 0.6 = 8.4
```

## Derived Sensitivity Check

```text
mismatch = 2
E_cost = 37.6 + 8.4 + (2 × 15) = 76.0

mismatch = 1
E_cost = 37.6 + 8.4 + (1 × 15) = 61.0
```

These are calculated scenarios, not observed trial outcomes.

## Interim Interpretation

Phase synchronization is the dominant modeled drag. Raw Chromebook throughput does not determine workflow efficiency when cognitive re-orientation and cross-device handoff penalties dominate.

```text
DEVICE_THROUGHPUT != WORKFLOW_EFFICIENCY
HANDOFF_LATENCY = modeled_bottleneck
PHASE_SYNC_EFFECT = hypothesis_supported_by_current_model
CLAIM_STATUS = provisional
AUTHORITY = false
```

## Locked Exogenous Variables for Next Run

| Variable | Locked value | Purpose |
|---|---:|---|
| `phase_prewarm` | `true` | Load Chromebook workspace two seconds before mobile handoff |
| `sticky_session_ttl` | `300s` | Preserve authentication context across devices |
| `T_commit_weight` | `0.4` | Retain baseline weighting |
| `auth_weight` | `0.6` | Retain baseline weighting |

When prewarm is enabled, the proposed phase penalty changes from 15 to 5 per mismatch point. This penalty change must be declared before execution and must not be retrofitted after observing results.

## Proposed Triplicate Trial

The following triples are expectations only:

```text
Trial D — Prewarm only
EXPECTED = (T_commit=88, auth_fails=13, mismatch=1)
OBSERVED = pending

Trial E — Sticky TTL only
EXPECTED = (T_commit=95, auth_fails=5, mismatch=4)
OBSERVED = pending

Trial F — Combined
EXPECTED = (T_commit=85, auth_fails=3, mismatch=1)
OBSERVED = pending
```

## Required Raw Receipt

```text
TRIAL_ID:
CONFIG:
T_COMMIT_RAW:
AUTH_FAILS_RAW:
MISMATCH_RAW:
PHASE_WEIGHT:
PREWARM_PENALTY:
E_COST_RECOMPUTED:
START_TIMESTAMP:
END_TIMESTAMP:
DEVICE_SEQUENCE:
AUTH_SESSION_OBSERVED:
ERROR_LOG_POINTER:
EXECUTION_COMMIT:
```

## Guardrails

```text
EXPECTED_TRIPLE != OBSERVED_TRIPLE
CALCULATED_SCENARIO != EXECUTION_RECEIPT
LOWER_E_COST != GENERAL_TCO_PROOF
ONE_TRIPLICATE != REPLICATION
MODEL_WEIGHT != NATURAL_CONSTANT
AUTHORITY = false
```

## Optional Sensitivity Sweep

After raw D/E/F receipts exist, recompute results for:

```text
phase_weight ∈ {10, 15, 20}
```

The sensitivity sweep must preserve the original raw triples and vary only the declared weight.

## Current State

```text
WHY_LAB_002_PRESENT = true
MODEL_DEFINED = true
EXPECTED_TRIPLES_RECORDED = true
RAW_D_E_F_RECEIPTS = absent
EXECUTION = pending
CLAIM_PROMOTION = human-reviewed_only
AUTHORITY = false
```

## Next Gate

Execute Trials D, E, and F under the locked configurations and commit the raw triples before interpretation or claim promotion.
