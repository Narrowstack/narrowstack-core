---
kind: review
slug: govern-docs-review
date: 2026-08-31
branch: feat/core-phase-g
plan: docs/plans/narrowstack-core-architecture-20260831.md
---

# Phase G documentation review — second pass

Compared deliverables against canonical architecture plan (2026-08-31). Scope: accuracy, DRY, no T1/T2 topology in manifests, headless v1 canon.

## Verdict

| Step | File | Result | Notes |
|---|---|---|---|
| G0 | `docs/plans/narrowstack-core-architecture-20260831.md` | **pass** | Aligns with plan: `warehouse.mode`, `semantics_ref`, Coolify/Hetzner, three-layer ACL, rollback-first, no `app_ref` |
| G0 | `docs/plans/narrowstack-core-iac-spec-20260831.md` | **pass** (fixed) | Frontmatter `superseded`; added body banner pointing to G0 — historical T1/T2/`app_ref` content retained below fold |
| G1 | `docs/product/prd.md` | **pass** | Headless v1, MoSCoW, walking skeleton correct |
| G1 | `docs/product/roadmap.md` | **pass** | TASK-NNN, proposed until G8; `warehouse.mode` examples |
| G2 | `docs/product/research/core-architecture-critique-20260831/review.md` | **pass** (fixed) | Replaced deploy-topology "T2" shorthand with "semantic layer attach" (telemetry T0–T3 unchanged) |
| G3 | `docs/architecture/overview.md` | **pass** | |
| G3 | `docs/architecture/packaging.md` | **pass** | Green-check sequence matches plan; links wiki for strategy |
| G3 | `docs/architecture/telemetry-protocol.md` | **pass** | T0–T3 are telemetry grant tiers, not deploy topology |
| G3 | `docs/architecture/charter-summary.md` | **pass** | |
| G3 | `docs/architecture/decisions.md` | **pass** | D1–D14 index present |
| G4 | `docs/features/instance-manifest.md` | **pass** | |
| G4 | `docs/features/allowlist-gate.md` | **pass** | |
| G4 | `docs/features/rollback-deploy.md` | **pass** | |
| G4 | `docs/features/metric-acl.md` | **pass** | Three layers documented |
| G4 | `docs/features/local-warehouse-deploy.md` | **pass** | |
| G4 | `docs/features/ns-core-cli.md` | **pass** | |
| G4 | `docs/features/semantics-template-cut.md` | **pass** | |
| G4 | `docs/features/modeling-api.md` | **pass** | |
| G4 | `docs/features/legacy-client-fit.md` | **pass** | Spec-only, deferred research |
| G6 | `README.md` | **pass** (fixed) | Was stale: T1/T2 compose, `narrowstack-core-app` active, `t1-dogfood` paths, wrong plan link |
| G6 | `AGENTS.md` | **pass** | |
| G6 | `docs/guides/deploy.md` | **pass** | Skeleton; rollback-first sequence |
| G6 | `docs/guides/rollback.md` | **pass** | |
| G6 | `docs/guides/warehouse.md` | **pass** | `warehouse.mode` table |
| G6 | `docs/guides/operations.md` | **pass** | |

## Errors found and fixed

1. **README.md** — Referenced superseded IaC spec, T1/T2 compose paths, active `narrowstack-core-app`, and `t1-dogfood` / `t1-full` examples. Updated to headless v1 canon, `local-warehouse` / `external-warehouse`, `example-local-warehouse.yaml`, architecture plan link.
2. **narrowstack-core-iac-spec-20260831.md** — Superseded status only in frontmatter; added prominent body banner to prevent accidental implementation from obsolete T1/T2/`app_ref` content.
3. **core-architecture-critique review.md** — Two deploy-topology "T2" references replaced with "semantic layer attach" prose.

## DRY check

- Green-check sequence: canonical in `packaging.md` + `rollback-deploy.md`; guides link to feature specs — acceptable layering.
- `decisions.md` indexes D1–D14 from architecture plan — pointer, not duplicate prose.
- No further dedup required this pass.

## Out of scope

- G5 RFCs (`operating-system/docs/rfc/`) — separate repo
- G7 Linear population — `docs/product/linear-backlog-draft.md` reviewed informally; no edits
- Phase B implementation files on branch (manifest schema, compose) — not Phase G deliverables
