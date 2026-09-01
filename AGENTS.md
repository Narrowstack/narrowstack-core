# AGENTS.md — narrowstack-core

Repo-safe agent entrypoint. Company-wide rules: Narrowstack org GitHub, Linear-only tracking, no personal infrastructure in commits.

## Repo purpose

IaC shell for headless Core v1 — manifest schema, deploy gates, semantics templates, ACL framework. Private tenant semantics live in separate repos pinned by `semantics_ref`.

## Before substantive work

1. Read [README.md](./README.md) and [docs/product/prd.md](./docs/product/prd.md).
2. Confirm Linear issue for non-trivial work (OS team).
3. Work on `feat|fix|chore/<slug>` branch — never `main`.
4. Phase B blocked until Phase G8 operator sign-off.

## Linear

**Project:** Narrowstack Core (Stackflow) — retarget in G7.

**Cloud agent:** `@cursor <task> [repo=Narrowstack/narrowstack-core] [branch=feat/OS-###-slug]`

**PR titles:** `OS-###: feat: <summary>` when issue exists.

## Key conventions

- **Manifest:** `warehouse.mode` only — no topology enum, no `app_ref`.
- **Secrets:** `op://` references only; never literals in manifest or commits.
- **Commits:** `tucker@narrowstack.com`.

## Doc homes

| Type | Path |
|---|---|
| Architecture plan | `docs/plans/` |
| Feature specs | `docs/features/` |
| Working architecture | `docs/architecture/` |
| RFCs (debate) | `operating-system/docs/rfc/` |

## Skills map (Phase G → B)

| Phase | Skills |
|---|---|
| G | visual-plan, app-prd, architecture-decision, docs-gardener, app-feature |
| B | build-loop, gauntlet-loop, brownfield-migrate, remote-deploy, review-security |

## Non-goals for agents

- Do not implement before G8 unless operator opens Phase B.
- Do not commit tenant manifests or proprietary model names to core.
- Do not restore `narrowstack-core-app` without explicit RFC acceptance.
