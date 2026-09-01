---
kind: review
slug: govern-linear-review
date: 2026-08-31
branch: feat/core-phase-g
plan: docs/plans/narrowstack-core-architecture-20260831.md
project: Narrowstack Core (Stackflow)
project_id: 4c861a22-4a45-4129-a383-262e285422b4
---

# Phase G7 Linear backlog review

Reviewed Linear population against `narrowstack-core` architecture spec (2026-08-31). Scope: title hygiene (no G/W labels in titles), parent/child hierarchy, description accuracy (`warehouse.mode`, no topology, deprecate core-app), duplicate cleanup, OS-338 split.

## Verdict

**Canonical set:** OS-395–OS-411 (17 issues). **Duplicates retired:** OS-412–OS-418 (7 issues). **OS-338 split comment:** present (2026-09-01).

Phase/wave identifiers remain in descriptions only. Titles are outcome-shaped.

## Canonical hierarchy

| Parent | Child | URL |
|---|---|---|
| **OS-395** Architecture governing stack (dry run) | — | https://linear.app/narrowstack/issue/OS-395 |
| **OS-396** Repo scaffold and manifest schema | OS-403 Instance manifest schema + examples | https://linear.app/narrowstack/issue/OS-396 |
| **OS-397** Allowlist, ACL, and rollback deploy | OS-404 Model-shipping allowlist | https://linear.app/narrowstack/issue/OS-397 |
| | OS-405 Three-layer metric ACL | https://linear.app/narrowstack/issue/OS-405 |
| | OS-406 Rollback-first deploy pipeline | https://linear.app/narrowstack/issue/OS-406 |
| **OS-398** Local-warehouse compose and green-check | OS-407 Local-warehouse compose on Coolify | https://linear.app/narrowstack/issue/OS-398 |
| **OS-399** Semantics refactor and private tenant manifest | OS-411 Telemetry phone-home (Admin plane) | https://linear.app/narrowstack/issue/OS-399 |
| **OS-400** NS tenant instance (PRD skeleton) | OS-408 NS tenant instance (PRD skeleton) | https://linear.app/narrowstack/issue/OS-400 |
| **OS-401** Full pipelines and modeling API | OS-409 Modeling API first slice | https://linear.app/narrowstack/issue/OS-401 |
| **OS-402** External warehouse and legacy client fit | OS-410 Legacy client sufficiency assessment | https://linear.app/narrowstack/issue/OS-402 |

## Renames applied

| ID | Before | After |
|---|---|---|
| OS-395 | G — Govern (dry run) | Architecture governing stack (dry run) |
| OS-396 | W0 — Repo scaffold | Repo scaffold and manifest schema |
| OS-397 | W1 — Allowlist + ACL + rollback | Allowlist, ACL, and rollback deploy |
| OS-398 | W2 — Local-warehouse compose + green-check | Local-warehouse compose and green-check |
| OS-399 | W3 — Semantics refactor + private tenant manifest | Semantics refactor and private tenant manifest |
| OS-400 | W4 — NS instance (PRD skeleton) | NS tenant instance (PRD skeleton) |
| OS-401 | W5 — Full pipelines + modeling API | Full pipelines and modeling API |
| OS-402 | W6 — External warehouse + legacy client fit [deferred] | External warehouse and legacy client fit |
| OS-406 | Core — rollback-first deploy pipeline | Rollback-first deploy pipeline |
| OS-407 | Core — local-warehouse compose on Coolify | Local-warehouse compose on Coolify |
| OS-408 | Core — NS tenant instance (PRD skeleton) | NS tenant instance (PRD skeleton) |
| OS-409 | Core — modeling API first slice | Modeling API first slice |
| OS-410 | Core — legacy client sufficiency assessment | Legacy client sufficiency assessment |

## Duplicates retired

Second MCP batch (2026-09-01) duplicated the first. Canonical issues kept; duplicates canceled or marked Duplicate.

| Duplicate | Canonical | Status |
|---|---|---|
| OS-414 Epic: G — Govern | OS-395 | Duplicate |
| OS-412 Epic: W0 — Repo scaffold | OS-396 | Canceled |
| OS-413 Epic: W1 — Allowlist + ACL + rollback | OS-397 | Duplicate |
| OS-415 Epic: W2 — Local-warehouse compose | OS-398 | Canceled |
| OS-416 Epic: W4 — NS instance | OS-400 | Duplicate |
| OS-417 Core — rollback-first deploy | OS-406 | Duplicate |
| OS-418 Core — model-shipping allowlist | OS-404 | Canceled |

## Description fixes

| ID | Fix |
|---|---|
| OS-403 | Added `warehouse.mode` only (D9), no `app_ref` (D8), `op://` secrets |
| OS-404–OS-411 | Replaced `**Epic:** Wn — …` with `**Parent:** OS-### — <outcome title>` |
| OS-407 | Added headless-only / no core-app; `warehouse.mode: local` |
| OS-408 | Tenant manifest in semantics repo; no topology enum |
| OS-409 | NRWSTK-945 deprecation + no `app_ref` |
| OS-410 | `warehouse.mode` in gap matrix; Airbyte out of core scope |

## OS-338 split

Comment on [OS-338](https://linear.app/narrowstack/issue/OS-338) (2026-09-01) documents:

- **Track A (dogfood):** OS-400 / OS-408 — dlt → dbt → MetricFlow → modeling API
- **Track B (client-delivery):** OS-338 Airbyte → Metabase demo — separate engagements track
- NRWSTK-945 deprecation → OS-409; Stackflow connector backlog → legacy client delivery label

**Operator decision still open:** cancel OS-338 dogfood acceptance or open sibling "Client-delivery demo (Airbyte)" under engagements.

## Remaining gaps

| Gap | Recommendation |
|---|---|
| W0 child for semantics template cut | Add under OS-396 when G4 spec lands (`docs/features/semantics-template-cut.md`) |
| W6 external-warehouse compose | Add child under OS-402 (`compose/external-warehouse/`) — currently only legacy research (OS-410) |
| NRWSTK-945 core webapp | Cancel or reparent in Narrowstack Cloud project; OS-401/OS-409 reference replacement |
| NRWSTK-595+ Stackflow connector backlog | Label "Legacy client delivery" or move to child project — not dogfood Core |
| OS-338 | Operator: cancel, rewrite acceptance, or split to engagements sibling |
| G8 sign-off | No dedicated issue; track via OS-395 completion or add before Phase B opens |
| Telemetry project | OS-411 notes separate Admin-plane project may be warranted at Phase B |

## Related issues (out of project scope)

| ID | Notes |
|---|---|
| [OS-338](https://linear.app/narrowstack/issue/OS-338) | Product — Tucker 90-Day; split comment added |
| NRWSTK-901–909 | Cloud hcloud — blocks OS-398/OS-407 |
| NRWSTK-945 | Deprecated core webapp — replace with OS-409 |
| NRWSTK-1261 | Core Bridge Spike — W6+ cross-cutting |
