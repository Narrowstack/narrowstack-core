# Feature — Semantics template cut (`semantics-template-cut`)

_v0.1 · 2026-08-31 · mode: add · status: spec_
_Owner repo: narrowstack-core · Partner: narrowstack-semantics_

## Problem / job

**Operator persona** — architecture plan §Semantics delivery. Core must ship OSS-safe patterns; NS proprietary pipelines and models must live only in private `narrowstack-semantics` fork.

## Proposal

**Template (OSS `narrowstack-core/semantics/`):** requirements, dlt pipeline template + one example, dbt layer config, one vertical slice (staging → mart → one metric), `allowlist/default.yaml`, ACL scripts, CI workflows.

**Private fork (`narrowstack-semantics`):** live connectors, bonus/payroll, company-split, seeds, `allowlist/internal.yaml`, `deploy/manifest.yaml`, NS principal definitions.

Deploy clones private repo at `semantics_ref`. Semver tags on semantics releases; manifest records `semantics_template_version` for drift tracking.

**RFC needed:** Git clone vs signed OCI artifact (deferred v2).

## Non-goals

1. Proprietary models in OSS tree
2. Tenant manifests in core repo
3. Submodule delivery — git ref pin only (v1)
4. Four-repo split before second instance proves template

## Invariant checklist

| Invariant | How honored |
|---|---|
| Default-deny allowlist | Both repos run check; profiles separated |
| D10 Narrowstack-owned semantics | Private repo under Narrowstack org |
| brownfield-migrate discipline | Current behavior in private repo documented before cut |
| License on template | OSS template licensed; proprietary stays private |

## Data-boundary table

| Datum | Core template | Private semantics | Crosses? |
|---|---|---|---|
| Pipeline patterns | yes | customized copies | fork at clone |
| Payroll/bonus models | never | yes | never in OSS |
| `deploy/manifest.yaml` | example only | yes | pin via semantics_ref |
| Allowlist `internal` profile | never | yes | never in OSS |
| Metric definitions (shipped) | example one | full set | customer instance only |

## Data model / API delta

- `scripts/clone-semantics.sh` — clone at ref
- `semantics/` template tree in core
- Partner repo restructure in W3

## Verification plan

1. OSS tree grep finds no NS-specific model names (bonus, payroll, company-split).
2. Private repo CI: allowlist + `dbt parse` + ACL regression green.
3. Clone at tag v0.x.y matches expected SHA.
4. Bump `semantics_ref` + green-check deploys new semantics version.
5. Revert `semantics_ref` + green-check restores prior metric answers.

## Roadmap phase

W3 — TASK-020 through TASK-023. See `docs/product/roadmap.md` §W3.

## Delta log

| Date | Change | Why |
|---|---|---|
| 2026-08-31 | Initial spec | Phase G4 |
