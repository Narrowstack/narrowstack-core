# Instance manifest

Per-tenant configuration commit validated by `manifest/schema.json`.

## Deploy shape

Use `warehouse.mode` only — **no topology enum**, **no `app_ref`**.

| Mode | Meaning | Compose |
|---|---|---|
| `local` | Full instance — Postgres on VM | `compose/local-warehouse/` |
| `external` | Semantic layer attach | `compose/external-warehouse/` |

## Required fields

`tenant_id`, `warehouse`, `semantics_ref`, `enabled_pipelines`, `allowlist_profile`, `principals`, `provider_mode`, `telemetry_grants`

When `warehouse.mode: local`: also `vm_size_class`, `backup`.

## Examples

- `examples/example-local-warehouse.yaml` — generic full instance
- `examples/example-external-warehouse.yaml` — generic attach

Tenant manifests live in **private semantics repo** at `deploy/manifest.yaml`.

## Validate

```bash
npm run lint:manifest
node scripts/lint-manifest.mjs path/to/manifest.yaml
```

## Secrets

Manifest fields (`secrets_refs`, `backup.target_env`, `warehouse.external_dsn_env`) hold
env var names only. Values belong in gitignored `.env` files — see `.env.example`.
