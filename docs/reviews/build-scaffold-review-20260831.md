---
kind: review
slug: build-scaffold-review
date: 2026-08-31
branch: feat/core-phase-g
bootstrap_ref: origin/cursor/w0-bootstrap-and-dev-env-a108
plan: docs/plans/narrowstack-core-architecture-20260831.md
wave: W0
---

# Phase B scaffold review — second pass (W0)

Compared `feat/core-phase-g` against bootstrap branch `origin/cursor/w0-bootstrap-and-dev-env-a108` and architecture spec v3. Scope: manifest schema, compose paths, deploy stubs, semantics/acl templates, ns-core CLI, wave review docs.

## Verdict

**W0 scaffold passes** — bootstrap v1 assumptions reconciled to `warehouse.mode`-only manifest (D9). Remaining work is intentional W1–W6 stubs.

## Bootstrap reconcile

| Bootstrap (v1) | Current (v3) | Status |
|---|---|---|
| `topology: T1 \| T2` required | Removed; `warehouse.mode` only | **fixed** |
| `app_ref` required | Removed (D8 headless) | **fixed** |
| `compose/t1-full/` | `compose/local-warehouse/` | **fixed** |
| `compose/t2-semantic/` | `compose/external-warehouse/` | **fixed** |
| `manifest/examples/t1-dogfood.yaml` | `example-local-warehouse.yaml` | **fixed** |
| `manifest/examples/t2-attach.yaml` | `example-external-warehouse.yaml` | **fixed** |
| `allowlist_profile: internal-dogfood \| customer-default` | `default \| internal` | **fixed** |
| No `principals` block | Required ACL principals array | **added** |
| No `pre-deploy-snapshot.sh` / `rollback.sh` | Rollback-first deploy stubs | **added** |
| No `semantics/` tree | OSS template machinery | **added** |
| No `acl/` framework | `acl/metric-sensitivity.yaml` + README | **added** |
| No `ns-core` CLI | `scripts/ns-core` stub | **added** |
| No wave review gate | `docs/process/wave-review-gate.md` + templates | **added** |

## Checklist (spec § Repo structure)

| Item | Path | Result |
|---|---|---|
| Manifest schema — `warehouse.mode` only | `manifest/schema.json` | **pass** |
| No topology / `app_ref` | schema `additionalProperties: false` | **pass** |
| Local warehouse compose | `compose/local-warehouse/` | **pass** (W2 skeleton) |
| External warehouse compose | `compose/external-warehouse/` | **pass** (W6 skeleton) |
| Generic local example | `manifest/examples/example-local-warehouse.yaml` | **pass** |
| Generic external example | `manifest/examples/example-external-warehouse.yaml` | **pass** |
| pre-deploy-snapshot | `deploy/pre-deploy-snapshot.sh` | **pass** |
| rollback | `deploy/rollback.sh` | **pass** (W2 restore pending) |
| green-check orchestration | `deploy/green-check.sh` | **pass** |
| allowlist gate stub | `deploy/allowlist-gate.sh` | **pass** |
| ACL smoke stub | `deploy/acl-smoke.sh` | **pass** |
| ACL apply stub | `deploy/acl-apply.sh` | **pass** |
| destroy / restore stubs | `deploy/destroy.sh`, `deploy/restore.sh` | **pass** |
| ACL framework | `acl/` | **pass** |
| Semantics templates | `semantics/` | **pass** |
| ns-core CLI stub | `scripts/ns-core` | **pass** |
| Wave review gate | `docs/process/wave-review-gate.md` | **pass** |
| Wave review templates | `docs/reviews/wave-0-govern-review.md`, `wave-build-review-template.md` | **pass** |
| CI | `.github/workflows/ci.yml` | **pass** |

## Errors found and fixed (this pass)

1. **`.env.example`** — Still referenced `compose/t1-full/` and `t1-dogfood.yaml`. Updated to `local-warehouse` + `example-local-warehouse.yaml`.
2. **`deploy/smoke-query.sh`** — Referenced deprecated `narrowstack-core-app`. Updated to modeling API `mf_query` (W5).
3. **`deploy/allowlist-gate.sh`** — Echo used obsolete `customer-default` profile name; aligned to `default`.
4. **Topology rejection test** — Added `test/fixtures/invalid-topology-field.yaml` + test asserting `topology` key fails schema.
5. **`acl/README.md`** — Added framework pointer doc.
6. **`docs/reviews/wave-build-review-template.md`** — Added build-wave review template; linked from wave-review-gate.

## Validation results

```text
npm ci          — pass (0 vulnerabilities)
npm test        — 6/6 pass (includes topology-field rejection)
npm run lint:manifest — 2/2 examples pass
./deploy/green-check.sh manifest/examples/example-local-warehouse.yaml — pass
./scripts/ns-core --help — pass (all subcommands listed)
```

## Intentional stubs (not blockers for W0)

| Component | Wave | Notes |
|---|---|---|
| Semantics clone + dbt run | W2 | green-check steps 4–5 |
| Allowlist verifier wired | W1 | `check-allowlist.py` exists in semantics/ template |
| ACL principal fixtures | W1/W4 | `smoke_test.py` stub |
| Rollback restore + re-green-check | W2 | `rollback.sh` dry-run only |
| destroy/restore live wiring | W2/W3 | compose + backup target |
| Modeling API + mf query | W5 | `smoke-query.sh` stub |
| External warehouse services | W6 | placeholder compose only |

## Sign-off

| Role | Verdict | Date |
|---|---|---|
| Review agent | **Authorize W1** — scaffold accurate; proceed allowlist + ACL wiring | 2026-08-31 |

**Commits:** `4fbdc48` (bootstrap reconcile), this review pass commit.

**Gate doc:** [wave-review-gate.md](../process/wave-review-gate.md)
