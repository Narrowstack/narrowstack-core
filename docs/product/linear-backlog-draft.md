---
kind: backlog-draft
slug: narrowstack-core-linear
date: 2026-08-31
status: synced
verified: 2026-09-01
note: Canonical Linear issues OS-395–411. Duplicates OS-412–418 canceled 2026-09-01. Epic titles use outcome names only; phase context lives in descriptions and parent links.
---

# Linear backlog — narrowstack-core

**Project:** [Narrowstack Core (Stackflow)](https://linear.app/narrowstack/project/narrowstack-core-stackflow-a014edc1978f)

## Epics

| ID | Title | URL |
|---|---|---|
| OS-395 | Architecture governing stack (dry run) | https://linear.app/narrowstack/issue/OS-395 |
| OS-396 | Repo scaffold and manifest schema | https://linear.app/narrowstack/issue/OS-396 |
| OS-397 | Allowlist, ACL, and rollback deploy | https://linear.app/narrowstack/issue/OS-397 |
| OS-398 | Local warehouse compose and green-check | https://linear.app/narrowstack/issue/OS-398 |
| OS-399 | Semantics refactor and private tenant manifest | https://linear.app/narrowstack/issue/OS-399 |
| OS-400 | NS tenant instance (PRD skeleton) | https://linear.app/narrowstack/issue/OS-400 |
| OS-401 | Full pipelines and modeling API | https://linear.app/narrowstack/issue/OS-401 |
| OS-402 | External warehouse and legacy client fit | https://linear.app/narrowstack/issue/OS-402 |

## Child issues

| ID | Title | Parent | URL |
|---|---|---|---|
| OS-403 | Instance manifest schema and examples | OS-396 | https://linear.app/narrowstack/issue/OS-403 |
| OS-404 | Model-shipping allowlist (default-deny) | OS-397 | https://linear.app/narrowstack/issue/OS-404 |
| OS-405 | Three-layer metric ACL framework | OS-397 | https://linear.app/narrowstack/issue/OS-405 |
| OS-406 | Rollback-first deploy pipeline | OS-397 | https://linear.app/narrowstack/issue/OS-406 |
| OS-407 | Local-warehouse compose on Coolify | OS-398 | https://linear.app/narrowstack/issue/OS-407 |
| OS-408 | NS tenant instance (PRD skeleton) | OS-400 | https://linear.app/narrowstack/issue/OS-408 |
| OS-409 | Modeling API first slice | OS-401 | https://linear.app/narrowstack/issue/OS-409 |
| OS-410 | Legacy client sufficiency assessment | OS-402 | https://linear.app/narrowstack/issue/OS-410 |
| OS-411 | Telemetry — phone-home protocol (Admin plane) | OS-399 | https://linear.app/narrowstack/issue/OS-411 |

## Cross-links

- **OS-338** — dogfood path (OS-400/OS-408) split from Airbyte client-delivery demo
- **OS-398/OS-407** — blocked by NRWSTK-901–909 (Cloud hcloud refactor)
- **NRWSTK-945** — deprecated; headless modeling API (OS-401/OS-409) replaces core webapp

## Canceled duplicates

Duplicate creates from a second G7 pass; canceled 2026-09-01:

| ID | Duplicate of |
|---|---|
| OS-412 | OS-396 |
| OS-413 | OS-397 |
| OS-414 | OS-395 |
| OS-415 | OS-398 |
| OS-416 | OS-400 |
| OS-417 | OS-406 |
| OS-418 | OS-404 |
