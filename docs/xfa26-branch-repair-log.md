# XFA26 Branch Repair Log

## Purpose

This document records the preservation-first repair of PR #1 from a mixed Gray Baby/XFA26 branch into an XFA26-only branch rooted in current `main`.

This file is a governance log. It must distinguish planned actions from observed actions and must never promote an unexecuted step.

```text
SYSTEM_STATE = HOLD
REPAIR_STATUS = PLANNED_NOT_EXECUTED
AUTHORITY = FALSE
```

## Pre-Repair State

```text
PR_NUMBER = 1
PR_BRANCH = xfa26-genesis-root
MIXED_HEAD = UNOBSERVED_AT_LOG_CREATION
MAIN_HEAD = UNOBSERVED_AT_LOG_CREATION
BRANCH_STATUS = DIVERGED
AHEAD_BY = 18
BEHIND_BY = 7
PACKAGE_BOUNDARY_MATCHES_DIFF = FALSE
CANON_PRESERVED = FALSE
REPAIR_BASE_EQUALS_CURRENT_MAIN = FALSE
```

## Required Preservation Artifacts

Before any destructive rewrite or force-with-lease update:

```text
BACKUP_TAG = PENDING
BACKUP_TAG_REMOTE_EXISTS = FALSE
CANON_BRANCH = gray-baby-canon-preservation
CANON_PRESERVATION_BRANCH_EXISTS = FALSE
```

The preservation branch and remote backup tag must both resolve to the exact mixed head.

## Deterministic Repair Sequence

### 1. Observe Current Heads

Record:

```text
MIXED_HEAD = <sha>
MAIN_HEAD = <sha>
OBSERVED_AT = <utc timestamp>
```

### 2. Preserve Mixed State

Create and push:

```text
BACKUP_TAG = xfa26-mixed-backup-<utc timestamp>
CANON_BRANCH = gray-baby-canon-preservation
```

Record resulting remote references and SHAs.

### 3. Create Repair Branch from Current Main

```text
REPAIR_BRANCH = xfa26-boundary-repair
REPAIR_BASE_SHA = <main sha>
REPAIR_BASE_EQUALS_CURRENT_MAIN = TRUE|FALSE
```

### 4. Carry Only Allowed XFA26 Files

Allowed initial carry-over:

- `docs/xfa26-merge-gate.md`
- `docs/xfa26-branch-repair-log.md`
- `x-files-alien-files-26/package/cid.txt`
- `x-files-alien-files-26/receipts/zora-coin.json`
- `x-files-alien-files-26/scripts/verify-package.sh`
- `x-files-alien-files-26/scripts/verify-eas-onchain.sh`

No Gray Baby canon files, ensemble media, unrelated Merkle artifacts, or narrative-provenance files may enter the repair branch.

### 5. Add Exact XFA26 Package Wave

Required package set:

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

### 6. Verify Scope Before Branch Replacement

Record:

```text
CANON_FILES_IN_XFA_DIFF = <count>
PACKAGE_FILES_COMPLETE = TRUE|FALSE
PACKAGE_BOUNDARY_MATCHES_DIFF = TRUE|FALSE
```

Any nonzero canon-file count is fail-closed.

### 7. Replace PR Branch with Lease Protection

Expected operation:

```text
git push origin HEAD:xfa26-genesis-root --force-with-lease=xfa26-genesis-root:<mixed-head>
```

Record:

```text
LEASE_EXPECTED_OLD_HEAD = <sha>
LEASE_RESULT = PASS|FAIL
NEW_PR_HEAD = <sha>
```

A failed lease must stop the repair.

### 8. Re-run Verification and CI

After the final tree is frozen:

```text
FIRST_VERIFY_LOG = PRESENT|ABSENT
CURRENT_HEAD_CI = PASSED|FAILED|UNOBSERVED
ONCHAIN_REPLAY_FOR_CURRENT_HEAD = RECORDED|DEFERRED|UNOBSERVED
```

## Mandatory Stop Conditions

```text
CANON_PRESERVATION_BRANCH_EXISTS = TRUE
BACKUP_TAG_REMOTE_EXISTS = TRUE
REPAIR_BASE_EQUALS_CURRENT_MAIN = TRUE
CANON_FILES_IN_XFA_DIFF = 0
PACKAGE_FILES_COMPLETE = TRUE
```

If any condition is false:

```text
REPAIR_STATUS = FAIL_CLOSED
PR_MERGE_ELIGIBILITY = FALSE
AUTHORITY = FALSE
```

## Completion Record

Populate only after observed execution:

```text
MIXED_HEAD =
MAIN_HEAD =
BACKUP_TAG =
BACKUP_TAG_SHA =
CANON_BRANCH =
CANON_BRANCH_SHA =
REPAIR_BRANCH =
REPAIR_BASE_SHA =
REPAIR_COMMIT_SHA =
NEW_PR_HEAD =
FIRST_VERIFY_LOG_SHA256 =
CI_RUN_ID =
ONCHAIN_REPLAY_RECEIPT =
REPAIR_STATUS = PLANNED_NOT_EXECUTED
PR_MERGE_ELIGIBILITY = FALSE
AUTHORITY = FALSE
```

Repository history preservation and package-boundary repair are separate proofs. Neither implies authority.