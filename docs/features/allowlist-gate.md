# Feature — Model-shipping allowlist (`allowlist-gate`)

_v0.1 · 2026-08-31 · mode: add · status: spec_
_Owner repo: narrowstack-core_

## Problem / job

**Technical buyer persona** — PRD §M3. Internal bonus and payroll logic must never ship to customer warehouses. Default-deny is the sharpest blocker in Core packaging.

## Proposal

Declarative allowlist profiles (`default`, `internal`) checked in CI and at deploy via `allowlist-gate.sh` / `check-allowlist.py`. Models, seeds, and dashboard tables are in scope. `sfdc_demo` permanently denied.

**Entry → action → outcome:** dbt build completes → allowlist script compares built artifacts to profile → unlisted name fails deploy with model name in stderr.

## Non-goals

1. Blocklist approach — absence means refusal
2. Models-only scope — seeds and dashboard tables included
3. Manual review as enforcement — pipeline must fail automatically
4. Customer-specific profiles in OSS tree — `internal` stays in private repo

## Invariant checklist

| Invariant | How honored |
|---|---|
| Zero allowlist violations to customers | Deploy and CI both enforce; named failure |
| No proprietary models in OSS | `default` profile only in core template |
| Rollback-first deploy | Allowlist is gate in green-check before active-manifest write |
| Production feature gate | No partial allowlist behind flags on main |

## Data model / API delta

- `semantics/allowlist/default.yaml` — OSS profile
- `semantics/scripts/check-allowlist.py` — enforcer
- `deploy/allowlist-gate.sh` — deploy wrapper
- Private repo: `allowlist/internal.yaml`

## Verification plan

1. Model in dbt output but not in profile → non-zero exit, stderr contains model name.
2. Seed file not listed → fails same as model.
3. `sfdc_demo` subtree present → fails even if accidentally listed.
4. CI on PR with new unlisted model → build fails before merge.
5. Listed model only → gate passes.

## Roadmap phase

W1 — TASK-008, TASK-009. See `docs/product/roadmap.md` §W1.

## Delta log

| Date | Change | Why |
|---|---|---|
| 2026-08-31 | Initial spec | Phase G4 |
