# ACL framework (repo root)

Framework-level metric sensitivity and principal tier definitions for Core boilerplate.

| File | Purpose |
|---|---|
| `metric-sensitivity.yaml` | Sensitivity tier enum (`leadership`, `team`, `agent`) |

Tenant-specific principal definitions and metric allow-lists live in the **private semantics repo** manifest (`principals` block). Deploy gates invoke `deploy/acl-smoke.sh` and `deploy/acl-apply.sh`.

Template copy for semantics forks: `semantics/acl/metric-sensitivity.yaml`.
