---
kind: guide
slug: warehouse
date: 2026-08-31
status: skeleton
verified: 2026-08-31
feature: instance-manifest, local-warehouse-deploy
---

# Guide — Warehouse modes

_Skeleton — filled during Phase B._

## Modes

| `warehouse.mode` | Use case | Compose path |
|---|---|---|
| `local` | Full instance — Postgres on VM | `compose/local-warehouse/` |
| `external` | Semantic layer attach — customer DSN | `compose/external-warehouse/` |

## Manifest fields

```yaml
warehouse:
  mode: local | external
  provider: postgres
  service: postgres          # local only
  volume: pgdata             # local only
  external_dsn_ref: op://... # external only
  backup: { ... }            # required when local
```

## Engine posture (v1)

| Engine | Status |
|---|---|
| Postgres self-hosted | Default |
| Managed Postgres (Supabase etc.) | Valid external via DSN |
| Snowflake / ClickHouse | Deferred W6+ |

## Acceptance criteria

- [ ] Local mode provisions Postgres volume with backup config
- [ ] External mode connects without local Postgres service
- [ ] No shared multi-tenant warehouse (ADR-003)

## References

- [instance-manifest.md](../features/instance-manifest.md)
- Architecture plan § Warehouse contract
