---
kind: plan
slug: pr-split-map-20260831
date: 2026-08-31
status: executed
---

# PR split map — feat/core-phase-g → reviewable PRs

**Source:** `feat/core-phase-g` @ `df515f0` (atomic Phase G + W0 bootstrap)  
**Base:** `main` @ `f57fca0` (IaC spec seed; `main` created on origin 2026-09-01)

## Strategy

1. Cherry-pick Phase G doc commits (exclude `4fbdc48`, `e463008` mixed scaffold fixes).
2. Extract wave/process review docs from `4fbdc48` onto govern branch.
3. File-level split of `4fbdc48` + `e463008` implementation across stacked epic branches.

## Branches

| Branch | Linear | Commits / scope |
|---|---|---|
| `feat/OS-395-architecture-governing-stack` | OS-395 | G0–G7 docs, reviews, backlog, milestones, wave gate |
| `feat/OS-396-repo-scaffold-manifest` | OS-396 / OS-403 | manifest, npm test, CI workflow |
| `feat/OS-397-allowlist-acl-rollback` | OS-397 / OS-404–406 | deploy ACL/allowlist/rollback, semantics allowlist stubs |
| `feat/OS-398-local-warehouse-green-check` | OS-398 / OS-407 | compose, green-check, ns-core stub |
| `feat/OS-399-semantics-handoff` | OS-399 | handoff doc, semantics template tree |

**Deferred:** OS-400 / OS-408 (NS tenant instance) — no separable stub slice in bootstrap; stays in backlog.

**Telemetry (OS-411):** documented in G4 feature specs; no bootstrap code split.

## Bootstrap commit split (`4fbdc48`)

Monolithic commit; epics above partition paths. Post-bootstrap doc fixes in `e463008` folded into epic file checkouts from `feat/core-phase-g` tip.

## Merge order

1. OS-395 (G8 sign-off before build merges)
2. OS-396 → OS-397 → OS-398 → OS-399

`feat/core-phase-g` preserved unchanged for reference.
