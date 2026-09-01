# Instance manifest — field reference

An instance manifest is the per-tenant configuration commit that drives
`deploy/green-check.sh`, `deploy/destroy.sh`, and `deploy/restore.sh`. It is the
honest first IaC interface: everything a `narrowstack-core` instance needs is
declared here, and secrets are carried only as `op://` references.

- Schema: [`schema.json`](./schema.json) (JSON Schema draft 2020-12)
- Examples: [`examples/t1-dogfood.yaml`](./examples/t1-dogfood.yaml),
  [`examples/t2-attach.yaml`](./examples/t2-attach.yaml)
- Validate: `npm run lint:manifest -- manifest/examples/t1-dogfood.yaml`
  (no args validates every example).

## Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `tenant_id` | string (slug) | yes | Stable slug: `^[a-z0-9]([a-z0-9-]*[a-z0-9])?$` |
| `topology` | `T1` \| `T2` | yes | Full VM vs external attach |
| `vm_size_class` | string | T1 | Cloud sizing token |
| `warehouse` | object | yes | See below |
| `semantics_ref` | string | yes | Git ref of `narrowstack-semantics` |
| `app_ref` | string | yes | Git ref of `narrowstack-core-app` |
| `enabled_pipelines` | string[] | yes | Subset of dlt sources |
| `allowlist_profile` | `internal-dogfood` \| `customer-default` | yes | Enforced at deploy gate |
| `provider_mode` | `M0`–`M3` | yes | Per provider spec |
| `telemetry_grants` | string[] | yes | Default `[]` (T0) |
| `backup` | object | T1 | `target_ref` (`op://`) + `retention_days` |
| `volume_ceiling_gb` | number | no | Documented full-refresh limit |
| `secrets_refs` | map<string, `op://`> | no | Logical name → 1Password item path |

### `warehouse`

| Field | Type | When | Notes |
|---|---|---|---|
| `mode` | `local` \| `external` | always | T1 ⇒ `local`; T2 ⇒ `external` |
| `service` | string | `mode=local` | Compose service name for local Postgres |
| `volume` | string | `mode=local` (optional) | Named docker volume backing Postgres |
| `external_dsn_ref` | `op://` | `mode=external` | Reference to external Postgres DSN |

## Conditional rules enforced by the schema

- `topology: T1` requires `vm_size_class`, a `backup` block, and
  `warehouse.mode: local`.
- `topology: T2` requires `warehouse.mode: external` (and thus
  `warehouse.external_dsn_ref`).
- Every `op://` reference (`external_dsn_ref`, `backup.target_ref`, and all
  `secrets_refs` values) must match `op://<vault>/<item>[/<field>...]`. Literal
  secret values are rejected — this is the committed enforcement of the house
  secrets bright-line.

## Secrets

Manifests never contain secret values. They carry `op://` references, which are
resolved at provision time via `op run`. See `.env.tpl.example` and
`compose/t1-full/.env.tpl`.
