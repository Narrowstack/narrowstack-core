---
kind: handoff
slug: semantics-w3
date: 2026-08-31
status: draft
verified: 2026-08-31
wave: W3
---

# Handoff — narrowstack-semantics W3 refactor

**Scope:** Proprietary cut from `narrowstack-semantics` monolith into OSS template + private tenant repo. **This repo cannot fully refactor narrowstack-semantics in Phase B** — this doc is the operator/agent handoff for W3 execution in the partner repo.

## OSS template (narrowstack-core/semantics/)

Already scaffolded in Phase B W0:

- `requirements.txt`, dlt templates, dbt_project skeleton
- `allowlist/default.yaml`, `check-allowlist.py`, ACL stubs
- One example vertical slice pattern only

## Private repo cut list (narrowstack-semantics)

Move **out** of template / keep **in** private repo:

| Keep private | Rationale |
|---|---|
| Live connectors (harvest, stripe, hubspot, …) | Proprietary + tenant-specific |
| bonus/payroll, company-split models | Allowlist blocker |
| `allowlist/internal.yaml` | NS-specific profile |
| `deploy/manifest.yaml` | Tenant config — never in core |
| NS principal definitions | ACL namespace |
| Full dashboard layer | Internal metrics |

## W3 acceptance

- [ ] Private repo CI: allowlist + dbt parse + ACL regression
- [ ] `deploy/manifest.yaml` validates against core `manifest/schema.json`
- [ ] `semantics_ref` pin deploys via green-check clone
- [ ] No proprietary model names in narrowstack-core tree

## Skills

`brownfield-migrate` · feature spec: [semantics-template-cut.md](../features/semantics-template-cut.md)

## RFC

[RFC-004](https://github.com/Narrowstack/operating-system/blob/main/docs/rfc/rfc-004-semantics-delivery.md) — git clone at deploy (v1)
