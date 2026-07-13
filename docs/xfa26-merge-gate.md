# XFA26 Merge Gate

## Purpose

This document defines the governance conditions for merging PR #1: **XFA26 — Generational Court Fees Package**.

GitHub mechanical mergeability is not equivalent to governance merge eligibility.

```text
GITHUB_MERGEABLE = MECHANICAL_SIGNAL_ONLY
GOVERNANCE_MERGE_ELIGIBLE = SUBSTANTIVE_GATE
AUTHORITY = FALSE
```

## Declared Package Boundary

PR #1 is restricted to the XFA26 Generational Court Fees package and its direct verification artifacts.

Allowed scope:

- `package/XFA26_Generational_Court_Fees.zip`
- `package/checksums.sha256`
- `manifest.json`
- `media/01_boomers_quarter.png`
- `media/02_genx_dimes.png`
- `media/03_millennials_nickel.png`
- `media/04_genz_penny.png`
- `media/05_genalpha_pepe.png`
- `metadata/collection.json`
- `receipts/first-verify.log`
- package-specific CI workflows
- package-specific EAS replay receipts, when recorded

Excluded scope:

- Gray Baby canon files
- ensemble media
- unrelated Merkle sets
- unrelated narrative provenance
- unrelated receipts or workflows

## Required Merge Conditions

Every condition below must be satisfied before merge eligibility may become true.

```text
PACKAGE_BOUNDARY_DECLARED = TRUE
PACKAGE_BOUNDARY_MATCHES_DIFF = TRUE
PR_BODY_HEAD_MATCH = TRUE
CURRENT_HEAD_CI = PASSED
FIRST_VERIFY_LOG = PRESENT
ONCHAIN_REPLAY_FOR_CURRENT_HEAD = RECORDED_OR_EXPLICITLY_DEFERRED
BRANCH_DIVERGENCE = RESOLVED
REVIEW_STATUS = APPROVED
PR_MERGE_ELIGIBILITY = TRUE
AUTHORITY = FALSE
```

## Evidence Requirements

### Package Boundary

The final diff must contain only allowed XFA26 artifacts and direct verification infrastructure.

### Final-Tree Verification

Verification must run against the final commit after all package files, manifests, and checksums are frozen.

The receipt must include:

- source commit SHA
- verification-script SHA-256
- package SHA-256
- media and metadata checksum results
- CID retrieval status
- local EAS-bind status
- exit status
- `AUTHORITY=false`

### CI

CI success must be attached to the current PR head. Results from an earlier head are not admissible for promotion.

### Onchain Replay

The onchain replay must either:

1. produce a receipt tied to the current head, or
2. be explicitly deferred in the PR body with the remaining boundary stated.

A local field match is not equivalent to an onchain replay.

```text
LOCAL_FIELDS_MATCHED != ONCHAIN_REPLAY_VERIFIED
```

### Divergence

The branch must be rebased onto or otherwise reconciled with the current `main` branch. Verification and CI must be rerun after reconciliation.

### Review

At least one explicit human review must approve the final tree after all required receipts are present.

## Fail-Closed Rules

Any mismatch returns the PR to HOLD.

```text
MISSING_ARTIFACT => HOLD
CHECKSUM_MISMATCH => FAIL_CLOSED
STALE_PR_HEAD => HOLD
CI_NOT_CURRENT => HOLD
UNRESOLVED_DIVERGENCE => HOLD
UNAPPROVED_REVIEW => HOLD
UNDECLARED_SCOPE_EXPANSION => FAIL_CLOSED
```

## Current Posture

```text
SYSTEM_STATE = HOLD
PR_MERGE_ELIGIBILITY = FALSE
AUTHORITY = FALSE
```

Repository merge proves reviewed repository state. It does not prove factual truth, wallet control, institutional authority, copyright ownership, market legitimacy, or permanence of external storage.
