# narrowstack-core

**Provisioning + runtime shell** for Narrowstack instances: the instance manifest
schema, deploy / destroy / restore scripts, the green-deploy gate (allowlist +
tie-out + smoke), and T1/T2 compose templates. Core makes the stack
**reproducible**; it does not fork the data contract.

This repository is the Cloud/Core IaC interface. See the implementation spec at
[`docs/plans/narrowstack-core-iac-spec-20260831.md`](docs/plans/narrowstack-core-iac-spec-20260831.md).

## Sibling repos

| Repo | Role |
|---|---|
| `narrowstack-semantics` | Data contract SSOT: dlt pipelines, dbt + MetricFlow, `allowlist.yaml` |
| `narrowstack-core-app` | Next.js chat GUI; consumes the semantic manifest as a build artifact |
| Narrowstack Cloud | VM provision + substrate + backup target (separate repos) |

Core references semantics and the app by **git ref pins** carried in the instance
manifest — never by copying their code.

## Repository layout

```
manifest/     instance manifest JSON Schema + examples + field reference
scripts/      lint-manifest.mjs (validator CLI), clone-semantics.sh
deploy/       green-check / allowlist-gate / smoke-query / destroy / restore
compose/      T1 (full VM) and T2 (external attach) docker-compose templates
test/         schema tests + invalid manifest fixtures
.github/      CI (manifest lint + tests + shellcheck) and allowlist trigger
```

## Wave 0 status

This is the Wave 0 bootstrap (repo structure, manifest schema, example
manifests, CI lint). Deploy scripts and compose services are **skeletons** with
clearly-marked `TODO (Wx)` steps; the manifest schema and its validator are
fully functional. See the migration waves table in the spec.

## Quick start

Requires Node.js >= 20.

```bash
npm ci                     # install dev dependencies (ajv, yaml)
npm run lint:manifest      # validate every manifest/examples/*.yaml against the schema
npm test                   # schema tests + invalid-fixture rejection tests
```

Validate a single manifest:

```bash
npm run lint:manifest -- manifest/examples/t1-dogfood.yaml
```

Run the (skeleton) deploy gate for an instance:

```bash
./deploy/green-check.sh manifest/examples/t1-dogfood.yaml
```

## Secrets

Committed env templates and manifests carry **`op://` references only**, never
literal secret values (house secrets bright-line). Resolve at provision time:

```bash
op run --env-file=compose/t1-full/.env.tpl -- ./deploy/green-check.sh manifest/examples/t1-dogfood.yaml
```

See [`manifest/README.md`](manifest/README.md) and `.env.tpl.example`.
