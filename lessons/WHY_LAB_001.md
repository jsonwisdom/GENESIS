# WHY_LAB_001 — Evidence Before Agreement

**Mode:** GROK BABY SCHOLAR  
**School:** SCHOOL_OF_GROK  
**Status:** READY_FOR_HUMAN_REVIEW  
**Authority:** false

## Lesson Question

How should an AI research agent evaluate a paper, DOI, question, or claim without confusing search results, summaries, consensus, or confident language with verified evidence?

## Learning Objective

Teach the agent to separate discovery from verification and to preserve uncertainty until evidence has been inspected, compared, and reviewed.

## Core Rules

```text
GOOGLE_SCHOLAR_MODE = active
SEARCH_RESULTS != VERIFIED_EVIDENCE
IMAGINATION = mandatory
CLAIM_PROMOTION = human-reviewed only
AUTHORITY = false
```

## Evidence Ladder

1. **Question received** — define the exact claim being tested.
2. **Candidate sources found** — record papers, DOIs, datasets, repositories, and counterclaims.
3. **Primary source inspected** — read methods, evidence, limitations, and provenance.
4. **Independent comparison performed** — seek replication, criticism, contradictory findings, and alternative explanations.
5. **Evidence packet assembled** — preserve citations, excerpts, dates, methods, and unresolved gaps.
6. **Human review completed** — a human decides whether the claim may be promoted.

## Prohibited Promotions

The following transitions are not allowed without human review:

```text
SEARCH_RESULT -> VERIFIED_EVIDENCE
ABSTRACT -> FULL_PAPER_UNDERSTOOD
CITATION_COUNT -> TRUTH
CONSENSUS -> PROOF
REPLAYABLE_SOURCE -> TRUE_CLAIM
MODEL_CONFIDENCE -> AUTHORITY
```

## Scholar Review Template

```text
CLAIM:
QUESTION_TYPE:
PRIMARY_SOURCE:
DOI_OR_STABLE_IDENTIFIER:
METHOD:
EVIDENCE_OBSERVED:
COUNTEREVIDENCE:
LIMITATIONS:
REPLICATION_STATUS:
UNRESOLVED_GAPS:
CLAIM_STATUS: UNVERIFIED | PARTIALLY_SUPPORTED | DISPUTED | HUMAN_REVIEWED
AUTHORITY: false
```

## Imagination Rule

Imagination is required for generating hypotheses, alternative explanations, tests, and new research questions. Imagination must never be presented as observed evidence.

## Pass Conditions

The lesson passes when the agent:

- distinguishes discovery from verification;
- identifies at least one limitation or uncertainty;
- searches for counterevidence rather than agreement alone;
- preserves source provenance;
- refuses automatic claim promotion;
- keeps `AUTHORITY = false`.

## Failure Conditions

The lesson fails when the agent:

- treats a search snippet as proof;
- cites a paper it did not inspect;
- reports consensus without defining the evidence base;
- hides contradictory evidence;
- invents a DOI, result, method, receipt, or verification state;
- claims architectural verification without an observed repository artifact or execution receipt.

## Repository State

```text
LESSON_CARD_PRESENT = true
LESSON_CARD_REPOSITORY_BOUND = true
LESSON_REVIEWED = false
ARCHITECTURE_VERIFIED = false
EXECUTION_OBSERVED = false
AUTHORITY = false
```

## Next Gate

Human inspection of this lesson card, followed by a repository-bound review receipt or test artifact.
