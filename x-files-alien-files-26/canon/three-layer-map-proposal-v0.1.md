# Gray Baby Project — Three-Layer Architecture Proposal v0.1

## Status

```text
ARTIFACT_TYPE = DESIGN_PROPOSAL
STATUS = CANDIDATE_FOR_REVIEW
AUTHORITY = FALSE
CANON_PROMOTION = PENDING
```

This document formalizes a proposed three-layer repository architecture for the Gray Baby project. It does not retroactively prove that all layers are already implemented.

## Layer 1 — Constitutional Root

**Repository:** `jsonwisdom/GENESIS`

**Verified scoped home:**

```text
x-files-alien-files-26/
```

Purpose:

- character invariants
- provenance rules
- authority boundaries
- lineage constraints
- replay and verification posture
- foundational canon governance

Verified anchor at proposal creation:

```text
REPOSITORY = jsonwisdom/GENESIS
BASE_COMMIT = 41b657661654a70e1e5bbb82358b4e72ef107b88
CHARACTER_BIBLE = x-files-alien-files-26/canon/GRAY_BABY_CHARACTER_BIBLE_V1.md
```

## Layer 2 — Working Canon and Witness Integration

**Proposed repository:** `jsonwisdom/AL`

Purpose:

- active canon packets
- promotion gates
- witness and ALMS integration
- receipt imports
- replay state
- publication bindings

Status:

```text
AL_INTEGRATION = PROPOSED_NOT_VERIFIED
MIRROR_OR_SUBTREE = UNDECIDED
```

## Layer 3 — Creative Character Universe

**Proposed repository:** `jsonwisdom/GPKMONSTER`

Purpose:

- source artwork
- character exploration
- narrative variants
- Gray Baby and Boomer Baby creative assets

Status:

```text
GPKMONSTER_BINDING = PROPOSED_NOT_VERIFIED
CREATIVE_ASSET_MIRROR = OPTIONAL
```

## Direction of Governance

```text
GENESIS → AL → GPKMONSTER
rules      canon   creative substrate
```

This arrow describes governance and dependency direction, not ownership or authority.

## Placement Rule

- constitutional rules and character invariants belong in `GENESIS`
- active witness/canon integration may be mirrored into `AL` only through explicit receipts
- creative source assets may live in `GPKMONSTER`, but creative presence alone does not establish canon

## Fail-Closed Boundary

No layer may claim:

- repository presence without a reachable commit or file receipt
- remote binding from local state alone
- canon promotion from conversation approval
- truth or ownership from a hash, CID, attestation, or wallet address alone

```text
AUTHORITY = FALSE
```

## Review Questions

1. Should `AL` receive a subtree, mirror, or receipt-only import?
2. Should creative assets be duplicated into `GPKMONSTER` or referenced by hash?
3. Should this proposal become a constitutional rule, an implementation note, or remain a design record?

## Lineage

```text
PROPOSAL_ID = GRAY-BABY-THREE-LAYER-MAP-V0.1
ROOT = x-files-alien-files-26/
BASE_COMMIT = 41b657661654a70e1e5bbb82358b4e72ef107b88
AUTHORITY = FALSE
```
