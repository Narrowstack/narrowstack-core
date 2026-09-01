# Feature — Modeling API (`modeling-api`)

_v0.1 · 2026-08-31 · mode: add · status: spec_
_Owner repo: narrowstack-core_

## Problem / job

**Technical buyer + agent integrators** — PRD step 6 (headless). v1 product surface for metric access without chat GUI. Extends bounded-tool contract from ADR-001 to HTTP API.

## Proposal

Headless Modeling API on instance:

| Endpoint | Behavior |
|---|---|
| `list_metrics` | Returns permitted metrics for principal; redacts denied |
| `get_manifest` | MetricFlow manifest slice for permitted metrics |
| `mf_query` | Executes query; enforces principal token ACL |

Same contract consumed by internal Admin when customer opts in — not a second API.

## Non-goals

1. Chat or streaming responses in v1
2. Row-level data export — metrics only
3. MCP server in v1 (PRD after skeleton)
4. `narrowstack-core-app` proxy — API is native surface

## Invariant checklist

| Invariant | How honored |
|---|---|
| Three-layer ACL | API is layer 3; must match semantic + warehouse grants |
| ADR-001 bounded tools | API exposes same metric contract as agent tools |
| D8 headless v1 | Replaces core-app as product surface |
| No shared warehouse password | API uses principal-scoped tokens |

## Data model / API delta

- API service in compose stack
- Principal token table keyed by manifest `principals`
- OpenAPI or schema stub in `api/` (Phase B)

## Verification plan

1. Principal with limited metrics → `list_metrics` excludes denied names.
2. `mf_query` for permitted metric matches CLI `mf query` output.
3. Denied metric query returns 403 without value in response body.
4. `get_manifest` omits definitions for denied metrics.
5. ACL smoke in green-check includes API principal fixture.

## Roadmap phase

W5 — TASK-037, TASK-038. See `docs/product/roadmap.md` §W5.

## Delta log

| Date | Change | Why |
|---|---|---|
| 2026-08-31 | Initial spec | Phase G4 |
