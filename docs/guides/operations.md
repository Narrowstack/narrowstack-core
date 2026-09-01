---
kind: guide
slug: operations
date: 2026-08-31
status: skeleton
verified: 2026-08-31
feature: ns-core-cli, metric-acl
---

# Guide — Day-two operations

_Skeleton — filled during Phase B._

## ns-core CLI

| Command | Purpose |
|---|---|
| `status` | Active pins, warehouse mode, last green-check |
| `deploy` | Run green-check with manifest |
| `rollback` | Restore prior snapshot |
| `grants` | Telemetry grant state |
| `acl list` | Principal metric visibility |
| `backup` / `restore` | Backup lifecycle |

## ACL operations

- Local policy: tenant manifest `principals` + semantics ACL files
- Remote policy (optional): `acl-apply.sh` when control plane enabled
- Kill-switch: local override; destroys outbound credential

## Fleet upgrades

- Upgrades proposed, not pushed
- Same green-check as initial deploy on customer data
- Three versioned interfaces: tool, semantic, telemetry

## Acceptance criteria

- [ ] Non-builder can run status and read-only ACL list
- [ ] Kill-switch verified with network blocked (PRD step 9)
- [ ] Audit log exportable without support ticket

## References

- [ns-core-cli.md](../features/ns-core-cli.md)
- [metric-acl.md](../features/metric-acl.md)
- [telemetry-protocol.md](../architecture/telemetry-protocol.md)
