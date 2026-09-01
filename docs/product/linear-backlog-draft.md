---
kind: backlog-draft
slug: narrowstack-core-linear
date: 2026-08-31
status: synced
verified: 2026-09-01
note: Canonical Linear state after G7 review. See docs/reviews/govern-linear-review-20260831.md.
---

# Linear backlog — narrowstack-core (synced)

**Project:** Narrowstack Core (Stackflow) · **Team:** NarrowstackOS · **Review:** `docs/reviews/govern-linear-review-20260831.md`

Titles are outcome-shaped. Phase/wave (G0–G8, W0–W6) lives in descriptions only.

## Milestones

| Milestone | Phase / wave | Linked epics & issues | URL |
|---|---|---|---|
| Architecture governing stack | G (dry run) | OS-395 | https://linear.app/narrowstack/project/narrowstack-core-stackflow-a014edc1978f/milestone/architecture-governing-stack-41cfa014 |
| Core instance for Narrowstack | W0–W5 (dogfood) | OS-396–401, OS-403–409, OS-411 | https://linear.app/narrowstack/project/narrowstack-core-stackflow-a014edc1978f/milestone/core-instance-for-narrowstack-5a1c315f |
| External warehouse and legacy fit | W6 (deferred) | OS-402, OS-410 | https://linear.app/narrowstack/project/narrowstack-core-stackflow-a014edc1978f/milestone/external-warehouse-and-legacy-fit-a69d1154 |
| Customer stack migration | Post-W4 (TBD) | — (related: [NRWSTK-1261](https://linear.app/narrowstack/issue/NRWSTK-1261)) | https://linear.app/narrowstack/project/narrowstack-core-stackflow-a014edc1978f/milestone/customer-stack-migration-8faca931 |

## Govern epic

| ID | Title | Status | URL |
|---|---|---|---|
| OS-395 | Architecture governing stack (dry run) | In Progress | https://linear.app/narrowstack/issue/OS-395 |

## Build epics + children

| Epic | Child issues | Status |
|---|---|---|
| [OS-396](https://linear.app/narrowstack/issue/OS-396) Repo scaffold and manifest schema | [OS-403](https://linear.app/narrowstack/issue/OS-403) Instance manifest schema + examples | Backlog |
| [OS-397](https://linear.app/narrowstack/issue/OS-397) Allowlist, ACL, and rollback deploy | [OS-404](https://linear.app/narrowstack/issue/OS-404) Allowlist · [OS-405](https://linear.app/narrowstack/issue/OS-405) ACL · [OS-406](https://linear.app/narrowstack/issue/OS-406) Rollback | Backlog |
| [OS-398](https://linear.app/narrowstack/issue/OS-398) Local-warehouse compose and green-check | [OS-407](https://linear.app/narrowstack/issue/OS-407) Compose on Coolify (+ ns-core CLI stubs) | Backlog |
| [OS-399](https://linear.app/narrowstack/issue/OS-399) Semantics refactor and private tenant manifest | [OS-411](https://linear.app/narrowstack/issue/OS-411) Telemetry phone-home | Backlog |
| [OS-400](https://linear.app/narrowstack/issue/OS-400) NS tenant instance (PRD skeleton) | [OS-408](https://linear.app/narrowstack/issue/OS-408) NS tenant instance | Backlog |
| [OS-401](https://linear.app/narrowstack/issue/OS-401) Full pipelines and modeling API | [OS-409](https://linear.app/narrowstack/issue/OS-409) Modeling API first slice | Backlog |
| [OS-402](https://linear.app/narrowstack/issue/OS-402) External warehouse and legacy client fit | [OS-410](https://linear.app/narrowstack/issue/OS-410) Legacy client sufficiency | Later |

## Retired duplicates (do not use)

| ID | Superseded by | Status |
|---|---|---|
| OS-414 | OS-395 | Duplicate |
| OS-412 | OS-396 | Canceled |
| OS-413 | OS-397 | Duplicate |
| OS-415 | OS-398 | Canceled |
| OS-416 | OS-400 | Duplicate |
| OS-417 | OS-406 | Duplicate |
| OS-418 | OS-404 | Canceled |

## OS-338 reconcile

Comment posted on [OS-338](https://linear.app/narrowstack/issue/OS-338) (2026-09-01):

- Dogfood path → [OS-400](https://linear.app/narrowstack/issue/OS-400) / [OS-408](https://linear.app/narrowstack/issue/OS-408)
- Airbyte demo remains client-delivery track — does not drive `narrowstack-core` IaC
- [NRWSTK-945](https://linear.app/narrowstack/issue/NRWSTK-945) deprecated → [OS-409](https://linear.app/narrowstack/issue/OS-409)

## Gaps to create (operator)

| Issue | Parent | When |
|---|---|---|
| Semantics template cut | OS-396 | After G4 spec committed |
| External-warehouse compose | OS-402 | Before W6 build |
| G8 operator sign-off | — | Before Phase B opens |
| Client-delivery demo (Airbyte) sibling | engagements | If OS-338 kept |

## Cross-project dependencies

- **W2 blocked by:** NRWSTK-901–909 (Cloud hcloud)
- **NRWSTK-945:** cancel/reparent to deprecated `narrowstack-core-app`
- **NRWSTK-595+ subtree:** label Legacy client delivery — not dogfood Core
