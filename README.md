# narrowstack-core

Provisioning and runtime shell for Narrowstack Core — IaC, compose, deploy gates, semantics templates, and ACL machinery.

**Status:** Phase G complete (docs); Phase B W0 scaffold landed on `feat/core-phase-g`.

## What this repo is

| In scope | Out of scope |
|---|---|
| Manifest schema + generic examples | Tenant-specific manifests |
| Deploy/rollback scripts | Proprietary pipelines/metrics |
| `semantics/` OSS templates | Live NS payroll/bonus models |
| ACL framework | Admin plane receiver |
| `ns-core` CLI + modeling API stubs | `narrowstack-core-app` (deprecated) |

**Architecture:** [docs/plans/narrowstack-core-architecture-20260831.md](docs/plans/narrowstack-core-architecture-20260831.md)

## Quick start

```bash
npm ci
npm test
npm run lint:manifest
./deploy/green-check.sh manifest/examples/example-local-warehouse.yaml
./scripts/ns-core status
```

Secrets: copy `.env.tpl.example` → `.env.tpl` and run via `op run --env-file=.env.tpl -- …`

## Layout

```
manifest/schema.json          # warehouse.mode only — no topology/app_ref
manifest/examples/            # example-local-warehouse.yaml
compose/local-warehouse/      # full instance skeleton
compose/external-warehouse/   # attach skeleton (W6)
semantics/                    # OSS template machinery
deploy/                       # green-check, rollback, ACL gates
scripts/ns-core               # operator CLI stub
```

## Docs

| Doc | Path |
|---|---|
| PRD | [docs/product/prd.md](docs/product/prd.md) |
| Roadmap | [docs/product/roadmap.md](docs/product/roadmap.md) |
| Features | [docs/features/](docs/features/) |
| Guides | [docs/guides/](docs/guides/) |

## Linear

**Project:** Narrowstack Core (Stackflow) · Epics G, W0–W4 created; see [linear-backlog-draft.md](docs/product/linear-backlog-draft.md) for remainder.

## Cloud Agent

`.cursor/environment.json` runs `npm ci` on session start.
