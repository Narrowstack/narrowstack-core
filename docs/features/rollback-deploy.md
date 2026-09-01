# Feature — Rollback-first deploy (`rollback-deploy`)

_v0.1 · 2026-08-31 · mode: add · status: spec_
_Owner repo: narrowstack-core_

## Problem / job

**Operator persona** — PRD §M5. Deploy gates can fail on customer data. Operators need automatic recovery to last known-good pins without a separate restore ceremony.

## Proposal

`pre-deploy-snapshot.sh` records `core_ref`, `semantics_ref`, manifest hash, optional pg_dump ref. `green-check.sh` runs full gate sequence; on any failure invokes `rollback.sh` unless `--no-auto-rollback`. Rollback restores pins and re-runs green-check or DB restore. `active-manifest.json` written only on success.

**Entry → action → outcome:** Operator triggers deploy → snapshot taken → gates run → success writes active manifest OR failure auto-rollback → operator sees stage + model name.

## Non-goals

1. Separate rollback mechanism from restore — rollback is the restore path (D11)
2. Push upgrades without green-check on customer data
3. Silent partial deploy — no active-manifest write on gate failure
4. Manual-only rollback as default — auto-rollback is default

## Invariant checklist

| Invariant | How honored |
|---|---|
| ADR-003 data isolation | Snapshot scoped to single tenant VM |
| Buyer-checkable claim (PRD step 10) | destroy + restore demonstrated end-to-end |
| Fleet upgrades | Same green-check definition for upgrade and fresh deploy |
| Three versioned interfaces | Snapshot records independent pin versions |

## Data model / API delta

- `deploy/pre-deploy-snapshot.sh`
- `deploy/rollback.sh`
- `deploy/green-check.sh` — orchestrator with failure hook
- `deploy/active-manifest.json` — on-VM only
- `deploy/destroy.sh`, `deploy/restore.sh` — lifecycle peers

## Verification plan

1. Simulated allowlist failure mid-green-check → rollback restores prior `semantics_ref`.
2. Snapshot JSON contains core_ref, semantics_ref, manifest hash after pre-deploy.
3. `--no-auto-rollback` leaves failed state for operator inspection.
4. Successful deploy writes `active-manifest.json` matching manifest inputs.
5. destroy → restore → metric query returns pre-destroy tie-out number.

## Roadmap phase

W1 — TASK-011, TASK-012; W2 — TASK-016, TASK-017. See `docs/product/roadmap.md`.

## Delta log

| Date | Change | Why |
|---|---|---|
| 2026-08-31 | Initial spec | Phase G4 |
