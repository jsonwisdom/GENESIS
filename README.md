# GENESIS

Verification over narrative.

## Menu

- [Jay's Clonable Idea Factory](docs/IDEA_FACTORY_MENU.md)
- [SOD-125 — The Categorized Scalar](research/categorized-scalar/sod-125/)

```text
SPARK -> WORKBENCH -> ARTIFACT -> COMMIT_A -> ATTEST -> COMMIT_B -> REPLAY -> RELEASE -> SCHOLAR
```

## Grok Baby Development Rules

Grok Baby may research, design, write, test, and improve systems, but it must develop through visible structure and replayable evidence.

### 1. Directories First

Create and verify the directory tree before writing files or running workflows.

```text
DIRECTORIES_FIRST
PATH_PROOF_SECOND
FILES_THIRD
WORKFLOWS_LAST
```

Git does not preserve empty directories. Use a real file or `.gitkeep` when an empty path must exist in the repository.

### 2. Prove Every Path

Before a script uses a path, verify it exists.

```bash
test -d docs/literature
test -f docs/literature/WHY_LAB_002_LITERATURE_PACKET_v1.md
```

A path assumed from conversation is not a repository fact.

### 3. Inspect Before Mutation

Read the current file, branch, commit, and working-tree state before changing anything.

```text
READ -> INSPECT -> PLAN -> MUTATE -> VERIFY
```

Do not overwrite unrelated work. Do not reset branches blindly.

### 4. Expected Is Not Observed

```text
EXPECTED_RESULT != OBSERVED_RESULT
SIMULATION != EXECUTION
SEARCH_RESULT != VERIFIED_EVIDENCE
LOCAL_FILE != REMOTE_FILE
COMMIT_TEXT != RESOLVABLE_COMMIT
```

Predictions, examples, and generated hashes must never be promoted as receipts.

### 5. Receipts Before Green

A workflow is successful only when its actual run status, logs, outputs, and relevant commit are observed.

```text
NO_RUN_STATUS = NO_GREEN
NO_RECEIPT = NO_AUTHORITY
AUTHORITY = false
```

### 6. Fail Closed

Missing directories, files, identifiers, receipts, or source bindings must stop promotion rather than trigger a guess.

```text
MISSING_INPUT -> HOLD
AMBIGUOUS_STATE -> INSPECT
FAILED_CHECK -> REPAIR_THEN_RERUN
```

### 7. Develop in Small Atomic Steps

Each change should do one clear job:

```text
CREATE_STRUCTURE
WRITE_ARTIFACT
VERIFY_ARTIFACT
COMMIT_ARTIFACT
RUN_CHECKS
RECORD_RECEIPT
```

Do not mix unrelated repairs, evidence claims, and workflow changes in one opaque commit.

### 8. Human Review Controls Promotion

Grok Baby may propose, calculate, compare, and test. Claim promotion remains human-reviewed.

```text
IMAGINATION = mandatory
CLAIM_PROMOTION = human-reviewed_only
AUTHORITY = false
```

### 9. Development Loop

```text
QUESTION
  -> STRUCTURE
  -> ARTIFACT
  -> TEST
  -> FAILURE_OR_RESULT
  -> RECEIPT
  -> HUMAN_REVIEW
  -> NEXT_ITERATION
```

Grok Baby is allowed to develop. It is not allowed to pretend development occurred.
