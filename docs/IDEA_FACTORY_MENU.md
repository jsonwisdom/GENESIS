# Jay's Clonable Idea Factory — Menu

A public, repeatable path for turning a raw idea into a durable, replayable research object.

## Start Here

### 1. Spark
Capture the raw idea without pretending it is complete.

**Output:**
- working title
- one-sentence question
- research ID
- initial status: `SPARK`

### 2. Workbench
Develop the idea into a structured source document.

**Output:**
- Markdown source
- scope and boundaries
- open questions
- candidate evidence
- status: `WORKBENCH`

### 3. Artifact
Render the first fixed version.

**Output:**
- PDF or other canonical file
- version number
- exact SHA-256
- status: `PREPUBLICATION_WORKING_DRAFT`

### 4. Commit A
Commit the artifact and its preliminary manifest.

**Output:**
- artifact path
- artifact hash
- source path
- Git commit containing the exact bytes

### 5. Attest
Create an EAS attestation that points to Commit A and the artifact hash.

**Output:**
- schema UID
- attestation UID
- transaction hash
- network and chain ID

### 6. Commit B
Record the attestation receipt in the repository.

**Output:**
- Commit A
- EAS UID
- transaction hash
- pending replay state

### 7. Replay
Independently verify the repository bytes and public chain record.

**Required observations:**
- transaction success
- block number
- block timestamp
- schema UID
- attester
- recipient
- artifact hash
- Commit A
- EAS UID

### 8. Release
Package the artifact for external discovery.

**Output:**
- GitHub release
- citation metadata
- archive deposit
- DOI when minted

### 9. Scholar
Move into scientific review, revision, citation, and critique.

**Output:**
- literature review
- quantitative claims
- experiments or tests
- peer or external review
- revised versions

## Clone the Factory

Copy the method, not the claim.

Every clone must receive its own:

```text
RESEARCH_ID
SOURCE
ARTIFACT
ARTIFACT_SHA256
COMMIT_A
ATTESTATION_UID
COMMIT_B
REPLAY_RECEIPT
```

## Quick Actions

| Action | Signal |
|---|---|
| Start a new idea | `NEW SPARK` |
| Promote to workbench | `OPEN WORKBENCH` |
| Build first artifact | `RENDER V0.1.0` |
| Prepare Commit A | `COMMIT_A READY` |
| Prepare EAS fields | `ATTESTATION READY` |
| Record receipt | `COMMIT_B READY` |
| Run replay audit | `REPLAY CHECK` |
| Prepare release | `START RELEASE` |
| Prepare Zenodo metadata | `ZENODO REFINEMENT` |
| Prepare arXiv package | `ARXIV PACKAGE` |

## Factory Rules

```text
NO GOOD IDEA DIES IN CHAT
NO RECEIPT = NO PROMOTION
HASH BEFORE HYPE
OBSERVATION BEFORE GREEN
PROVENANCE != SCIENTIFIC VALIDITY
COPY THE METHOD, NOT THE CLAIM
AUTHORITY = FALSE
FAKE_GREEN = FALSE
```

## First Production Sample

- Research ID: `SOD-125`
- Title: `The Categorized Scalar`
- Version: `v0.1.0`
- Path: `research/categorized-scalar/sod-125/`

SOD-125 is the first working example of the factory pipeline.
