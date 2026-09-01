# narrowstack-core

**Provisioning and runtime shell** for headless Core v1: instance manifest schema, deploy
gates, semantics templates, and ACL machinery. Core makes the stack **reproducible**;
proprietary pipelines and metrics live in per-tenant private semantics repos pinned via
`semantics_ref`.

Canonical architecture:
[`docs/plans/narrowstack-core-architecture-20260831.md`](docs/plans/narrowstack-core-architecture-20260831.md).
Phase **G (Govern)** docs land before Phase **B (Build)**.

Substrate: Coolify on Hetzner VPS. One VM per customer (ADR-003).

## Sibling repos

| Repo | Role |
|---|---|
| Private semantics repo per tenant | Data contract: dlt, dbt + MetricFlow, allowlist profiles, `deploy/manifest.yaml` |
| Narrowstack Cloud | VM provision, substrate, backup target |

Headless v1 product surface: modeling API + `ns-core` CLI on the VM.
`narrowstack-core-app` is **deprecated**; no `app_ref` in the instance manifest.

## Repository layout

```
manifest/     schema + generic examples (tenant manifests live in private repos)
semantics/    OSS template machinery
deploy/       green-check, rollback, allowlist/ACL gates, destroy, restore
compose/      local-warehouse and external-warehouse profiles
acl/          metric sensitivity framework
scripts/      lint-manifest.mjs, clone-semantics.sh
```

Deploy shape uses `warehouse.mode` (`local` | `external`) — not topology enums.

## Phase status

Governing docs are in `docs/`. Implementation waves (W0–W6) are **proposed** until G8
operator sign-off.

## Quick start

Requires Node.js >= 20.

```bash
npm ci                     # install dev dependencies (ajv, yaml)
npm run lint:manifest      # validate manifest/examples/*.yaml against the schema
npm test                   # schema tests + invalid-fixture rejection tests
```

Validate a single manifest:

```bash
npm run lint:manifest -- manifest/examples/example-local-warehouse.yaml
```

Run the deploy gate (scripts may be stubs until the matching build wave lands):

```bash
./deploy/green-check.sh manifest/examples/example-local-warehouse.yaml
```

## Secrets

Manifests reference **env var names** (e.g. `DLT_PG_PASSWORD`); values live in `.env`
files that are gitignored. Copy from `.env.example`:

```bash
cp .env.example .env
cp compose/local-warehouse/.env.example compose/local-warehouse/.env
./deploy/green-check.sh manifest/examples/example-local-warehouse.yaml
```

See [`manifest/README.md`](manifest/README.md) and `.env.example`.
