---
kind: architecture
slug: core-runtime
date: 2026-09-22
verified: 2026-09-22
status: proposed
refs:
  - docs/product/prd.md
  - docs/plans/narrowstack-core-architecture-20260831.md
  - docs/architecture/chat-with-modeled-data.md
  - compose/local-warehouse/docker-compose.yml
---

# Core runtime — architecture guides

**Summary:** One Core per customer VM is the shared spine of Variant A (a chat edge in front of Core) and Variant C (headless: API, MCP, and CLI only). It has three parts:

- **Warehouse:** Postgres.
- **Pipeline runner:** dlt, then dbt, then MetricFlow, on cron, with green-check gating every publish.
- **Modeling API:** REST and MCP. It is the **front door and bouncer**: every metric read, CLI included, passes through its access checks and row scoping.

The first execution path is **Core only**. The chat edge, model plane, and knowledge plane are written as stubs so Core honors their contracts, but they're built later. Everything here is **proposed** and documentation only; nothing is implemented.

The compose file for this architecture is [`compose/local-warehouse/`](../../../compose/local-warehouse/README.md).

## Scope

| Surface | What it is | Status |
|---|---|---|
| Warehouse (`postgres`) | Postgres 16 + pgvector image; raw, staging, and marts schemas per generation | **Initial execution path** |
| Pipeline runner (`runner`) | Green-check on deploy, scheduled refresh, `ns-core` CLI host | **Initial execution path** |
| Modeling API + MCP (`api`) | `/v1` REST + `/mcp`; access modes, metric ACL, row scope, audit | **Initial execution path** |
| Headless edge (Variant C) | Integrators and operators on the API, MCP, or CLI; off-VM example agent | **Initial execution path** (served by Core itself) |
| Chat edge (Variant A) | Open WebUI (build-vs-buy verdict pending stamp) as its own Coolify resource | Stub |
| Model plane | LiteLLM as its own Coolify resource | Stub |
| Knowledge plane | `kb_search` / `kb_cite` over pgvector | Stub |

## Reading order

1. [system-architecture.md](./system-architecture.md): planes, components, boundaries, and the invariants every other doc cites.
2. [access-control.md](./access-control.md): the front door and bouncer (access modes, open mode, tokens, row scope, audit).
3. [runtime-flows.md](./runtime-flows.md): sequence diagrams for deploy, refresh, query, denial, access setup, rollback, and restore.
4. [interface-contracts.md](./interface-contracts.md): REST, MCP, CLI, state files, env contract, manifest changes.
5. [deployment-coolify.md](./deployment-coolify.md): how it lands on Coolify, which credentials each service gets, what to verify on first deploy.
6. [edge-stubs.md](./edge-stubs.md): chat edge, model plane, knowledge plane; what must be true before each is switched on.
7. [requirements.md](./requirements.md): the requirement registry (`CORE-*`, `STUB-*`).
8. [decisions-and-open-questions.md](./decisions-and-open-questions.md): operator direction, proposals awaiting stamp, open questions, implied canon edits.

## Terms used here

| Term | Meaning |
|---|---|
| **Core** | The per-customer data stack and its API: warehouse, runner, Modeling API. One instance per tenant VM (single-tenant data plane, ADR-003). |
| **Variant A** | Packaging with a customer chat UI in front of Core. The edge is a stub. |
| **Variant C** | Headless packaging: integrators and operators use the API, MCP, or CLI. On the initial path. |
| **Front door and bouncer** | The Modeling API, MCP, and CLI: the only way to read metrics, and the place access is enforced. |
| **Principal** | A named caller from the manifest's `principals[]`: id, tier, metric patterns, and (proposed) row scope. |
| **Access mode** | How the API authenticates callers: `open` (when access isn't set up), `token` (Core-issued tokens), `oidc` (IdP tokens; stub). |
| **Open mode** | Access not set up. Callers aren't authenticated and row scope is off. Possible, but strongly advised against. |
| **Row scope** | A per-principal row restriction (for example region = EMEA) added to every query. What Tucker calls RLS. |
| **Allowlist** | The default-deny list of models, seeds, and tables allowed to ship to an instance. |
| **Green-check** | The deploy gate sequence. Success publishes a generation and writes `active-manifest.json`; failure keeps the last-good one. |
| **Generation** | One gated build of the semantic layer (pins, dbt artifacts, published schemas), numbered N. |
| **Tenant / semantics repo / manifest** | One customer instance; its private repo of pipelines, models, and metrics; and its config file (`deploy/manifest.yaml`) in that repo. |
| **Stub** | A surface specified now and built later, off the initial execution path. |
| **G8 / Phase B** | G8 is the operator sign-off that opens Phase B, the build phase (`docs/process/wave-review-gate.md`). |
| **INV-n / CORE-XXX-NN / P-n / Q-n** | Invariant (system-architecture.md), requirement (requirements.md), proposal and open question (decisions-and-open-questions.md). |

## Status and gates

- These are Phase G (govern) artifacts. Canon holds all implementation, including a real Coolify deploy, until G8 sign-off (D13, D14). Whether G8 can cover a Core-only first slice is open question Q1.
- Proposals (P1–P16) are not adopted until Tucker stamps them. Canon edits they imply are listed, not applied.
- Linear is the system of record for work and decisions. This doc set holds architecture and requirements, not status.

## Provenance

This set synthesizes and supersedes the Cursor prototype. The sources stay in the tree as provenance:

| Artifact | Role now |
|---|---|
| [`../chat-with-modeled-data.md`](../chat-with-modeled-data.md) | Cursor prototype (variants A/B/C, options matrix). **Superseded** by this directory. |
| [`../chat-data-plane/`](../chat-data-plane/README.md) | Archify diagram of the lean Variant A prototype (LibreChat-era). Provenance. |
| [`../../product/research/oss-agent-harness-chat-data-20260922/`](../../product/research/oss-agent-harness-chat-data-20260922/executive-summary.md) | Harness research, build-vs-buy, slot discovery. Evidence. |
| [`build-vs-buy-chat-surface-acl.md`](../../product/research/oss-agent-harness-chat-data-20260922/build-vs-buy-chat-surface-acl.md) | Chat-surface re-run on per-user ACL (2026-09-22). Recommends Open WebUI; awaiting stamp. |
