---
kind: architecture
slug: overview
date: 2026-08-31
verified: 2026-08-31
wiki: operating-system/wiki/product/modules/core.md
---

# Architecture overview

**Wiki:** `operating-system/wiki/product/modules/core.md` · **Plan:** `docs/plans/narrowstack-core-architecture-20260831.md`

---

## What narrowstack-core is

The **provisioning and runtime shell** for Narrowstack Core: IaC, compose profiles, deploy gates, in-repo semantics templates, and ACL machinery. It is the OSS candidate repo.

Proprietary pipelines, models, and metrics live in **per-tenant private semantics repos**, pinned at deploy via `manifest.semantics_ref`.

---

## System diagram

```
Coolify (Hetzner VPS)
    → provision stack from manifest
    → clone semantics at semantics_ref
    → green-check (allowlist + ACL + tie-out)
    → active-manifest.json on VM

narrowstack-core (OSS)          Private semantics (per tenant)
├── manifest/schema             ├── dlt pipelines
├── semantics/ templates        ├── dbt + MetricFlow
├── deploy/ gates               ├── allowlist/internal.yaml
├── compose/ profiles           └── deploy/manifest.yaml
└── acl/ framework
```

Optional control plane (customer opt-in): outbound phone-home → Admin Core for telemetry and signed ACL policy. Local kill-switch always wins.

---

## v1 product surface

| Surface | Scope |
|---|---|
| `ns-core` CLI (on VM) | status, deploy, rollback, grants, acl, backup, restore |
| Modeling API | list_metrics, get_manifest, mf_query |
| `narrowstack-core-app` | **Deprecated** — no chat GUI in v1 |

---

## Data flow

1. **Ingest** — dlt pipelines (enabled per manifest) → `raw_*` schemas
2. **Transform** — dbt staging → marts → dashboard layer (allowlisted subset)
3. **Semantic** — MetricFlow metrics with `meta.sensitivity_tier`
4. **Access** — three layers: warehouse grants, semantic allowlist, API principal tokens

---

## Isolation model (ADR-003)

One VM per customer. No shared warehouse. Cloud provisions substrate; Core consumes via manifest. Application/control planes may be multi-tenant; client data plane is not.

---

## Execution phases

| Phase | What | Status |
|---|---|---|
| **G — Govern** | Docs, PRD, feature specs, RFCs, Linear | In progress |
| **B — Build** | W0–W6 implementation waves | Blocked until G8 sign-off |

Waves are proposed placeholders — reorder or defer in Phase G without sunk build cost.

---

## Key docs in this repo

| Doc | Purpose |
|---|---|
| `docs/product/prd.md` | Product requirements |
| `docs/product/roadmap.md` | TASK-NNN build queue |
| `docs/features/*.md` | Per-capability specs |
| `docs/guides/*.md` | Operator runbooks (skeletons until Phase B) |
| `docs/architecture/` | Working copies of OS strategy specs |

Strategy canon remains in `operating-system/` wiki and working docs — one fact, one home; repo docs link back.
