---
kind: guide
slug: deploy
date: 2026-08-31
status: skeleton
verified: 2026-08-31
feature: rollback-deploy, local-warehouse-deploy
---

# Guide — Deploy

_Skeleton — filled during Phase B when scripts exist._

## Prerequisites

- [ ] Valid tenant manifest (private semantics repo or example)
- [ ] `.env` configured from `.env.example`
- [ ] Cloud VM provisioned (Coolify / Hetzner)
- [ ] Semantics repo access at pinned `semantics_ref`

## Procedure

1. Run `pre-deploy-snapshot.sh` — record pins and manifest hash
2. Run `green-check.sh <manifest-path>`
3. Verify `active-manifest.json` on VM

## Acceptance criteria

- [ ] All green-check gates pass (allowlist, ACL smoke, tie-out, mf query)
- [ ] Idempotent re-run produces no drift
- [ ] Failure triggers auto-rollback unless `--no-auto-rollback`

## References

- [rollback-deploy.md](../features/rollback-deploy.md)
- [local-warehouse-deploy.md](../features/local-warehouse-deploy.md)
- [packaging.md](../architecture/packaging.md)
