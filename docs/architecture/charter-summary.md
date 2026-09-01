---
kind: architecture
slug: charter-summary
date: 2026-08-31
verified: 2026-08-31
wiki: operating-system/wiki/product/charters/ns-2-core.md
---

# Charter summary — NS-2 Narrowstack Core

**Wiki:** `operating-system/wiki/product/charters/ns-2-core.md` (full charter)

**Linear:** [Narrowstack Core (Stackflow)](https://linear.app/narrowstack/project/narrowstack-core-stackflow-a014edc1978f) · **Charter:** NS-2

---

## One-liner

Packaged data stack and semantic layer — dlt → Postgres → dbt → MetricFlow — reproducible per customer on isolated VMs, with consent-first telemetry and IaC deploy.

---

## State today

**Live on Narrowstack's own data** — dlt sources → Postgres → dbt marts → MetricFlow → skills library. v1 product surface shifts to **headless** (modeling API + `ns-core` CLI); chat GUI (`narrowstack-core-app`) deprecated.

**Gap:** No second instance has ever been provisioned from config commit. This repo (`narrowstack-core`) is the path to close that gap.

---

## Goals

- Worked semantic model reusable as onboarding template (OSS patterns in core; proprietary in private fork)
- Polymorphic AI provider (M0–M3); built-in agent bounded, not do-everything
- Phone-home protocol an ownership buyer would sign
- Deployable by IaC onto Cloud in one command, per-customer VM (ADR-003)

---

## Anti-goals

- Not BI, not a warehouse product, not a dashboard layer (StackMap owns rendering)
- Not a do-everything assistant — escalation is a feature
- No per-customer forks — customizations are configuration or they don't ship
- No shared multi-tenant warehouse

---

## Components owned vs consumed

| Owned by Core | Consumed |
|---|---|
| Semantic model templates · agent provider abstraction · phone-home client · deploy packaging | Cloud substrate (VM, Coolify) · design system |

Joint ownership with Cloud: deploy packaging interface (Core stack, Cloud substrate).

---

## Conventions

- Work in `Narrowstack/narrowstack-core` + Linear (retarget project in G7)
- Contracts first — breaking interfaces is a versioned event, not a push
- Architecture decisions → ADR in operating-system wiki; working copies in `docs/architecture/decisions.md`

---

## Open charter questions (unchanged)

| Question | Status |
|---|---|
| Open-source vs source-available posture | Unresolved — correct public wording when decided |
| Warehouse hosting for NS own instance | Restore drill decides |
| OS-338 Airbyte demo vs dlt dogfood | Reconcile in G7 Linear sync |
| GUI brand alignment | Deferred with core-app deprecation |

---

## Kill criterion (suggested)

Every modeled stack needs majority-custom work after N attempts, or OSS/commercial split cannot cohere.
