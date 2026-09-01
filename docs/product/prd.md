---
kind: prd
slug: narrowstack-core
date: 2026-08-31
status: draft
verified: 2026-08-31
wiki: operating-system/working/core-prd.md
linear: Narrowstack Core (Stackflow)
---

# PRD — Narrowstack Core (headless v1)

**Summary:** Core is the packaged data stack and semantic layer: dlt into Postgres, dbt to marts, MetricFlow, bounded agent tooling. v1 product surface is **headless** — modeling API + `ns-core` CLI on the VM. `narrowstack-core-app` (chat GUI) is **deprecated** for v1; no `app_ref` in the instance manifest. The job is reproducibility: a second instance provisioned from a config commit, because every commercial claim assumes one and none has ever existed.

**Wiki canon:** [core-prd](https://github.com/Narrowstack/operating-system/blob/main/working/core-prd.md) · **Architecture:** [narrowstack-core-architecture-20260831](../plans/narrowstack-core-architecture-20260831.md)

## Problem

Small businesses accrete tools for years and never accrete a data layer. An agent pointed at siloed source systems is a demo. Core makes one semantic definition reproducible per customer VM (ADR-003).

**Time budget:** UNSET — deployable hours per week unmeasured. If capacity is low, cut from full instance (`warehouse.mode: local`) to semantic-layer attach (`warehouse.mode: external`), which is smaller and already sold once.

## Solution — walking skeleton

**One tenant, one source, one metric, one question, one grant, one revocation.**

Deploy shape uses `warehouse.mode` (`local` | `external`), not topology enums. Conceptual names ("full instance", "semantic layer attach") are documentation only.

| # | Step | Proves | Pass check |
|---|---|---|---|
| 1 | Config commit provisions a second Core VM on Cloud, `warehouse.mode: local` | IaC contract, ADR-003 isolation, per-role credentials | Deploy idempotent; loader, transform, query engine, and agent each hold distinct credentials |
| 2 | One real source loads through dlt into `raw_<source>` | Ingestion travels | `_dlt_loads` shows completed load |
| 3 | dbt builds staging → one mart with **one durable entity key**; one MetricFlow metric resolves foreign entity against that key | Transform + semantic layers travel without NS baggage | `dbt parse` manifest has no company-split dependency; metric entity resolves to surrogate key |
| 4 | Metric tied out against source | Trust claim | Validator passes; tie-out recorded |
| 5 | Allowlist check runs | Nothing internal shipped | Deploy fails on deliberately unlisted model |
| 6 | Non-builder asks entity-scoped question via **modeling API or CLI** and gets the number with query shown | Headless surface + entity key reachable | Answer matches step 4 tie-out exactly |
| 7 | Provider mode M0 → M1 via config change | Polymorphism | Same question, same number, different vendor account |
| 8 | Telemetry: T0 only at rest; T1 sample shown; T1 granted then revoked | Consent-first, audit log | Packet capture matches grant state |
| 9 | Kill-switch with network to Narrowstack blocked | Severance is real | Pipelines, dbt, `mf query` succeed afterwards |
| 10 | Destroy, then restore from backup | D-1 closes | Restored instance answers step 6 with step 4 number |

Steps 5, 9, and 10 are the loud-fail claims a buyer can verify.

**Second tenant:** one of Narrowstack's three company entities (not a customer). First paying customer becomes instance three.

## Done means

- Second instance from config commit, zero manual steps (baseline: none exists).
- Config commit → tied-out metric via headless surface in under one working day.
- Tie-out coverage 100% of **shipped** metrics (allowlist shrinks denominator).
- Allowlist violations on customer instances: **zero, permanently**.
- Provisioned by someone who did not build Core, from written procedure.
- Destroy → restore verified by known question / known number.

## MoSCoW

| Must | Should | Could | Won't (v1 skeleton) |
|---|---|---|---|
| Instance manifest + schema | External warehouse compose (W6) | MCP native server | `narrowstack-core-app` chat GUI |
| Allowlist default-deny gate | Fleet upgrade doc | Customer audit-log export | Topology enum in schema |
| Three-layer metric ACL | Legacy client fit probe | Provider M2/M3 | Multi-tenant warehouse |
| Rollback-first deploy | Modeling API full slice | Incremental loading | Per-customer git orgs at MVP |
| Headless CLI + API stubs → functional | | | Airbyte client-delivery in core repo |
| Semantics template in core + private fork | | | Full entity layer for every noun |

## Non-goals

- `narrowstack-core-app` — deprecated for v1 headless Core.
- BI/dashboard product; warehouse product; do-everything assistant.
- Per-customer fork; data migration; multi-tenant warehouse (ADR-003).
- Open-source release before posture chosen.
- Implementation before Phase G8 sign-off.

## Specs (repo + wiki)

| Topic | Repo | Wiki |
|---|---|---|
| Packaging / IaC | [packaging.md](../architecture/packaging.md) | core-packaging-spec |
| Telemetry | [telemetry-protocol.md](../architecture/telemetry-protocol.md) | core-telemetry-protocol |
| Decisions | [decisions.md](../architecture/decisions.md) | ADR-001, ADR-003 |
| Features | [docs/features/](../features/) | — |

## Open questions

| Question | Owner | What answers it |
|---|---|---|
| Self-host Postgres vs managed (NS instance #1) | Tucker + Tyler | Restore drill on Cloud VM |
| Open source vs source-available | Tucker + Tyler | Business-model call |
| OS-338 split (Airbyte demo vs dlt dogfood) | Tucker | G7 Linear reconcile |
| Consent rate per telemetry category | Tucker | Five pre-registered interviews |
