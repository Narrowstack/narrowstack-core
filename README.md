# narrowstack-core

Provisioning and runtime shell for Narrowstack Core — IaC, compose, deploy gates, semantics templates, and ACL machinery.

**Status:** Phase G (Govern) — documentation and specs; Phase B (Build) gated on G8 sign-off.

## What this repo is

| In scope | Out of scope |
|---|---|
| Manifest schema + generic examples | Tenant-specific manifests |
| Deploy/rollback scripts | Proprietary pipelines/metrics |
| `semantics/` OSS templates | Live NS payroll/bonus models |
| ACL framework | Admin plane receiver |
| `ns-core` CLI + modeling API stubs | `narrowstack-core-app` (deprecated) |

**Architecture:** [docs/plans/narrowstack-core-architecture-20260831.md](docs/plans/narrowstack-core-architecture-20260831.md)

## Quick links

| Doc | Path |
|---|---|
| PRD | [docs/product/prd.md](docs/product/prd.md) |
| Roadmap | [docs/product/roadmap.md](docs/product/roadmap.md) |
| Overview | [docs/architecture/overview.md](docs/architecture/overview.md) |
| Features | [docs/features/](docs/features/) |
| Guides | [docs/guides/](docs/guides/) |

## Linear

**Project:** Narrowstack Core (Stackflow) — retarget in G7 to dogfood IaC track.

**Cloud agent:** `@cursor <task> [repo=Narrowstack/narrowstack-core] [branch=feat/OS-###-slug]`

**Wiki:** NS-2 charter — `operating-system/wiki/product/charters/ns-2-core.md`

## Development

Phase B (after G8):

```bash
npm ci
npm test
node scripts/lint-manifest.mjs manifest/examples/example-local-warehouse.yaml
```

Cloud Agent: `.cursor/environment.json` runs `npm ci` on start.

## License

TBD — OSS candidate for boilerplate; proprietary semantics stay in private tenant repos.
