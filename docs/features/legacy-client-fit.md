# Feature — Legacy client fit (`legacy-client-fit`)

_v0.1 · 2026-08-31 · mode: add · status: spec · **build deferred W6**
_Owner repo: narrowstack-core_

## Problem / job

Narrowstack operates **seven bespoke data implementations** across live customer sites — predominantly Airbyte + dbt + Postgres (Snowflake/ClickHouse exceptions). These are not the dogfood Core stack. Before migration conversations, we need evidence whether Core + semantics architecture would meet each site's needs.

## Proposal

**Spec now; research in Phase B / W6** after W4 gate passes.

| Phase | Activity | Outcome |
|---|---|---|
| Inventory | Per-customer: ingestion, warehouse, transform, semantic exposure, access | `docs/product/research/legacy-client-inventory-YYYYMMDD.md` |
| Gap matrix | Map against manifest capabilities | Gaps ranked blocker / workaround / out-of-scope |
| Fit probe | 1–2 sites modeled as manifest + semantics fork | Sufficiency without touching production |
| Verdict | Per customer: migrate / coexist / retain bespoke | Feeds commercial roadmap |

No auto-migration assumed. Track as deferred Linear epic linked to NS-2 Core.

## Non-goals

1. Migration execution in v1
2. Airbyte connectors in narrowstack-core repo
3. Conflating client-delivery stack with dogfood Core (OS-338 split)
4. Full fleet conversion commitment

## Invariant checklist

| Invariant | How honored |
|---|---|
| Govern before build | Research spec in G4; execution W6 only |
| Two systems called Core | Glossary distinction maintained in inventory |
| ADR-003 | Assessment notes per-VM isolation fit, not shared warehouse |
| Production feature gate | No partial migration tooling on main |

## Data model / API delta

None in Phase G. Research artifacts only under `docs/product/research/`.

## Verification plan

1. Inventory documents all seven sites with five dimensions each.
2. Gap matrix covers warehouse mode, pipelines, ACL, volume for every site.
3. At least one fit probe produces draft manifest + semantics fork outline.
4. Each site receives explicit verdict with rationale.
5. Linear epic created and linked to NS-2 Core project.

## Roadmap phase

W6 — TASK-043 through TASK-045. See `docs/product/roadmap.md` §W6.

## Delta log

| Date | Change | Why |
|---|---|---|
| 2026-08-31 | Initial spec (research only) | Phase G4 / D12 |
