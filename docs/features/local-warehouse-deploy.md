# Feature — Local-warehouse deploy (`local-warehouse-deploy`)

_v0.1 · 2026-08-31 · mode: add · status: spec_
_Owner repo: narrowstack-core_

## Problem / job

**Operator persona** — PRD walking skeleton steps 1–5. Full Core instance (`warehouse.mode: local`) must run on Coolify-provisioned VM with Postgres on named volume.

## Proposal

`compose/local-warehouse/docker-compose.yml` deploys Postgres + ingestion + transform + semantic layer + API services. Green-check orchestrates clone semantics → pipelines → dbt → gates → smoke query. Cloud provisions substrate; core consumes manifest.

**Entry → action → outcome:** Cloud delivers VM → operator runs green-check with manifest → full stack healthy with tied-out metric.

## Non-goals

1. External warehouse in this compose path — see `compose/external-warehouse/`
2. Shared multi-tenant Postgres
3. Incremental loading in v1 — document `volume_ceiling_gb` instead
4. Snowflake/ClickHouse in default compose

## Invariant checklist

| Invariant | How honored |
|---|---|
| ADR-003 | One VM, one warehouse volume per tenant |
| D7 Coolify on Hetzner | Compose labels compatible with Cloud provisioner |
| Secrets via op | `.env.tpl` + `op://`; no baked credentials |
| Allowlist + ACL gates | green-check includes both before success |

## Data model / API delta

- `compose/local-warehouse/docker-compose.yml`
- `compose/local-warehouse/.env.tpl`
- `deploy/green-check.sh` integration
- Manifest `warehouse.backup` required for local mode

## Verification plan

1. `docker compose config` validates without errors.
2. Green-check on example manifest reaches smoke `mf query` success.
3. Postgres data persists across compose restart (named volume).
4. Per-role credentials connect only to permitted schemas/tables.
5. `destroy.sh` stops services; `restore.sh` returns known metric answer.

## Roadmap phase

W2 — TASK-014 through TASK-019. See `docs/product/roadmap.md` §W2.

## Delta log

| Date | Change | Why |
|---|---|---|
| 2026-08-31 | Initial spec | Phase G4 |
