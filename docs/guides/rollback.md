---
kind: guide
slug: rollback
date: 2026-08-31
status: skeleton
verified: 2026-08-31
feature: rollback-deploy
---

# Guide — Rollback

_Skeleton — filled during Phase B._

## When to rollback

- Green-check failure (automatic via `rollback.sh`)
- Bad semantics release after successful deploy
- Operator-initiated revert to prior `semantics_ref`

## Procedure

1. Identify prior pins from snapshot or `active-manifest.json` history
2. Run `rollback.sh [--no-auto-rollback override inverse]`
3. Re-run green-check against restored pins
4. Verify known metric query matches tie-out

## Acceptance criteria

- [ ] Prior semantics_ref restored
- [ ] Local warehouse: optional pg_dump restore completed
- [ ] External warehouse: scope documented — semantics tag revert only

## References

- [rollback-deploy.md](../features/rollback-deploy.md)
