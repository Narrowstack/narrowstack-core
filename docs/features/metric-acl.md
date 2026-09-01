# Feature — Three-layer metric ACL (`metric-acl`)

_v0.1 · 2026-08-31 · mode: add · status: spec_
_Owner repo: narrowstack-core_

## Problem / job

**Technical buyer persona** — PRD §M4. Metric sensitivity must hold at warehouse, semantic, and API layers. A bounded tool contract over a shared warehouse password is security theater.

## Proposal

Three enforcement layers, all required in green-check:

| Layer | Mechanism |
|---|---|
| Warehouse | Per-role Postgres users; row/column grants |
| Semantic | `meta.sensitivity_tier` + profile allowlist; MetricFlow filter |
| API | Principal token → allowed metric names; `list_metrics` redacts |

Manifest `principals` block defines id, tier, metric patterns. Remote ACL via phone-home requires consent grant; `deploy/acl-apply.sh` in core; local kill-switch overrides.

**RFC needed:** Metric ACL + remote policy push (Phase G5).

## Non-goals

1. Single shared warehouse credential across components
2. API-only ACL without warehouse grants
3. Permanent principal allowlist — revocable tokens only
4. Remote policy without customer consent grant

## Invariant checklist

| Invariant | How honored |
|---|---|
| ADR-003 tenancy prerequisites | Per-tenant principal namespace keyed by `tenant_id` |
| Telemetry kill-switch | Local ACL overrides any remote push |
| Headless v1 surface | API layer is primary access path for agents |
| Per-role credentials | dlt, dbt, MetricFlow, reader, agent each distinct |

## Data model / API delta

- `acl/metric-sensitivity.yaml` — tier definitions
- `semantics/acl/metric-sensitivity.yaml` — model metadata contract
- Manifest `principals[]` — `{ id, tier, metrics: ["*"] | patterns }`
- `deploy/acl-smoke.sh` — green-check gate
- `deploy/acl-apply.sh` — apply local or signed remote policy

## Verification plan

1. Principal `team-pulse` with `revenue_*` only → `list_metrics` excludes non-matching names.
2. `mf_query` on denied metric → authorization error, no value leakage.
3. Warehouse role for agent cannot `SELECT` columns outside grant.
4. ACL smoke in green-check fails when principal sees forbidden metric.
5. Remote policy apply with kill-switch engaged → local policy unchanged.

## Roadmap phase

W1 — TASK-010; W3 — TASK-024. See `docs/product/roadmap.md`.

## Delta log

| Date | Change | Why |
|---|---|---|
| 2026-08-31 | Initial spec | Phase G4 |
