# Feature — Instance manifest (`instance-manifest`)

_v0.1 · 2026-08-31 · mode: add · status: spec_
_Owner repo: narrowstack-core_

## Problem / job

**Operator persona** — PRD §M1, §M2. Deploy must be fully described by a single config commit. Without a validated manifest schema, every instance is a snowflake.

## Proposal

JSON Schema + YAML instance manifest per tenant. Core ships schema and generic example only; tenant manifests live in private semantics repos (`deploy/manifest.yaml`).

**Minimum fields:** `tenant_id`, `warehouse`, `semantics_ref`, `enabled_pipelines`, `allowlist_profile`, `principals`, `provider_mode`, `telemetry_grants`; `backup` required when `warehouse.mode: local`; `control_plane` optional.

**Entry → action → outcome:** Operator authors manifest → `lint-manifest.mjs` validates → `green-check.sh` consumes manifest → deploy is reproducible and reviewable from one file.

## Non-goals

1. Topology enum — use `warehouse.mode` only (D9)
2. Tenant-specific manifests in core repo
3. Submodule pin for semantics — git ref only (D5)
4. Secrets in manifest — env var names only (values in `.env`)

## Invariant checklist

| Invariant | How honored |
|---|---|
| ADR-003 one VM per customer | `tenant_id` identifies one data plane; no shared-warehouse mode |
| Govern before build | Spec-only in Phase G; schema lands in W0 |
| No snowflake servers | Undeclared values cause lint/deploy failure |
| Confidentiality | No hostnames, personal paths, or plaintext secrets in committed examples |

## Data model / API delta

- `manifest/schema.json` — JSON Schema draft
- `manifest/examples/example-local-warehouse.yaml` — generic demo tenant
- `scripts/lint-manifest.mjs` — CI validation
- On-VM `active-manifest.json` — runtime SSOT (not in git)

## Verification plan

1. Example manifest validates against schema with zero errors.
2. Manifest missing required field `semantics_ref` fails lint with field name.
3. `warehouse.mode: external` without `external_dsn_env` fails validation.
4. `warehouse.mode: local` without `backup` fails validation.
5. Schema rejects unknown topology enum field if proposed.

## Roadmap phase

W0 — TASK-002, TASK-003. See `docs/product/roadmap.md` §W0.

## Delta log

| Date | Change | Why |
|---|---|---|
| 2026-08-31 | Initial spec | Phase G4 |
