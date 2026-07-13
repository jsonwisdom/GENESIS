# WHY_LAB_002 — Hybrid Interface Tax and Phase Synchronization

**Mode:** GROK BABY SCHOLAR  
**Status:** PROTOCOL_LOCKED_EXECUTION_PENDING  
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

## Evidence Signal

The current evidence cluster suggests that cross-interface transitions can be asymmetric and cognitively costly, especially at migration points. However, no direct Chromebook-to-mobile pupillometry or EEG study has yet been bound to this artifact.

```text
PHASE_MISMATCH_REAL = directional_signal
ASYMMETRY = plausible
EVENT_LEVEL_WORKLOAD_SPIKE = plausible
DIRECT_CB_MOBILE_NEUROPHYSIOLOGY = absent
PHASE_WEIGHT_15 = heuristic_not_canonical
LITERATURE_CITATIONS_BOUND = false
CLAIM_STATUS = provisional
AUTHORITY = false
```

Claims involving Touch→Voice asymmetry, NASA-TLX, pupillary response, 40% productivity loss, or 2009 PIM studies remain unpromoted until exact citations, methods, sample sizes, and limitations are attached.

## Locked Exogenous Variables

| Variable | Locked value | Purpose |
|---|---:|---|
| `phase_prewarm` | `true` | Load Chromebook workspace two seconds before mobile handoff |
| `sticky_session_ttl` | `300s` | Preserve authentication context across devices |
| `T_commit_weight` | `0.4` | Retain baseline weighting |
| `auth_weight` | `0.6` | Retain baseline weighting |
| `base_phase_weight` | `15` | Preserve original heuristic for non-prewarm runs |
| `prewarm_phase_weight` | `5` | Predeclared experimental penalty for prewarm runs |

The prewarm penalty change is fixed before execution and may not be retrofitted after results are observed.

## N=30 Randomized Crossover Protocol

### Design

```text
DESIGN = within_subject_randomized_crossover
N = 30
CONDITIONS = mobile_only | chromebook_only | hybrid_no_prewarm | hybrid_prewarm
TASK_FAMILY = edit_test_debug_commit
SESSIONS_PER_PARTICIPANT = 4
COUNTERBALANCING = Latin_square
WASHOUT = 10_minutes
PRIMARY_ENDPOINT = event_level_handoff_cost
AUTHORITY = false
```

### Inclusion Controls

Participants must have routine familiarity with both smartphone and Chromebook-class interfaces. Record typing speed, Git familiarity, visual correction needs, and prior use of cloud development tools before randomization.

### Task Standardization

Each condition uses a defect of matched difficulty with:

```text
same_repository_shape = true
same_test_count = true
same_auth_provider = true
same_network_class = true
same_model_access = true
same_instruction_packet = true
```

Defects must be counterbalanced so no participant receives the same defect twice.

### Measurements

```text
T_COMMIT_RAW
AUTH_FAILS_RAW
MISMATCH_RAW
HANDOFF_START_TIMESTAMP
HANDOFF_END_TIMESTAMP
TIME_TO_REORIENTATION
INPUT_CORRECTIONS
FAILED_COMMANDS
CONTEXT_SWITCHES
REWORK_MINUTES
NASA_TLX_PRE
NASA_TLX_POST
PUPIL_BASELINE
PUPIL_PEAK_AT_HANDOFF
PUPIL_RECOVERY_TIME
TASK_SUCCESS
COMMIT_SHA
```

Pupillometry must be synchronized to handoff events. If eye tracking is unavailable or unreliable, preserve the missingness reason and do not substitute inferred values.

### Primary Comparison

```text
hybrid_prewarm vs hybrid_no_prewarm
```

Primary hypothesis:

```text
H1: phase_prewarm reduces event-level reorientation time and mismatch cost.
H0: phase_prewarm produces no measurable reduction.
```

Secondary comparisons:

```text
mobile_only vs chromebook_only
mobile_only vs hybrid_prewarm
chromebook_only vs hybrid_prewarm
```

### Analysis Plan

Use participant-level paired comparisons and a mixed-effects model:

```text
outcome ~ condition + task_order + baseline_skill + (1 | participant)
```

Report effect sizes and confidence intervals. Do not promote the heuristic phase weight from 15 to canonical status from significance alone. Calibration requires out-of-sample replication.

## Proposed Triplicate Engineering Trial

The following triples remain expectations only:

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
PARTICIPANT_ID:
CONDITION:
CONFIG:
T_COMMIT_RAW:
AUTH_FAILS_RAW:
MISMATCH_RAW:
PHASE_WEIGHT:
PREWARM_PENALTY:
E_COST_RECOMPUTED:
HANDOFF_START_TIMESTAMP:
HANDOFF_END_TIMESTAMP:
TIME_TO_REORIENTATION:
NASA_TLX_PRE:
NASA_TLX_POST:
PUPIL_BASELINE:
PUPIL_PEAK_AT_HANDOFF:
PUPIL_RECOVERY_TIME:
DEVICE_SEQUENCE:
AUTH_SESSION_OBSERVED:
ERROR_LOG_POINTER:
EXECUTION_COMMIT:
```

## Guardrails

```text
EXPECTED_TRIPLE != OBSERVED_TRIPLE
CALCULATED_SCENARIO != EXECUTION_RECEIPT
LITERATURE_PATTERN != DIRECT_VALIDATION
LOWER_E_COST != GENERAL_TCO_PROOF
ONE_TRIPLICATE != REPLICATION
STATISTICAL_SIGNIFICANCE != CANONICAL_WEIGHT
MODEL_WEIGHT != NATURAL_CONSTANT
AUTHORITY = false
```

## Sensitivity Sweep

After raw receipts exist, recompute with:

```text
phase_weight ∈ {5, 10, 15, 20}
```

The sweep must preserve raw event data and vary only the declared weight.

## Current State

```text
WHY_LAB_002_PRESENT = true
PHASE_PREWARM = true
N30_CROSSOVER_PROTOCOL = defined
MODEL_DEFINED = true
EXPECTED_TRIPLES_RECORDED = true
LITERATURE_CITATIONS_BOUND = false
RAW_D_E_F_RECEIPTS = absent
PARTICIPANT_EXECUTION = absent
EXECUTION = pending
CLAIM_PROMOTION = human-reviewed_only
AUTHORITY = false
```

## Next Gate

Attach exact literature citations and execute either the D/E/F engineering triplicate or the N=30 crossover protocol. No weight calibration or architecture promotion occurs before raw event-level receipts are committed.
