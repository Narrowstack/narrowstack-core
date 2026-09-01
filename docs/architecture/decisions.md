---
kind: architecture
slug: decisions
date: 2026-08-31
verified: 2026-08-31
wiki: operating-system/wiki/decisions/adr/
---

# Architecture decisions index

**Wiki:** `operating-system/wiki/decisions/adr/` (canonical ADRs)

Accepted decisions governing `narrowstack-core`. Full ADR text lives in the operating-system wiki; this index is the repo working copy.

---

## ADR-001 — Core agent runtime

**Status:** Proposed · **Wiki:** `operating-system/wiki/decisions/adr/adr-001-core-agent-runtime.md`

Keep **Hermes Agent** for v0 behind a **bounded-tool facade**. GUI (when it existed) depended on Core's tool contract, not Hermes-shaped events. v1 headless surface extends the same contract via modeling API.

**Revisit:** First paying instance, Hermes API break, Anthropic host block, or 2026-11-17.

---

## ADR-003 — Tenancy and isolation

**Status:** Accepted · **Wiki:** `operating-system/wiki/decisions/adr/adr-003-tenancy-and-isolation.md`

Application and control planes are multi-tenant; **client data plane is single-tenant — one VM per customer**.

**Build prerequisites (not yet built):** per-tenant authorization, tenant-scoped RLS, audit trail. Impersonation is permissioned, PIN-gated, audited.

**Packaging consequence:** Core does not make one warehouse safe for many customers; it makes one warehouse reproducible many times. Shared multi-tenant warehouse is out of scope.

---

## Architecture plan decisions (D1–D14)

From `docs/plans/narrowstack-core-architecture-20260831.md`:

| # | Resolution |
|---|---|
| D1 | `semantics/` in core + `semantics_ref` for private implementations |
| D2 | Prove local warehouse first; external attach in W6 |
| D3 | Managed Postgres for instance #1; self-host #2 in W5 |
| D4 | `internal` allowlist profile for NS; skeleton uses `default` |
| D5 | Manifest git ref; no submodule |
| D6 | Three-layer ACL in boilerplate from W1 |
| D7 | Coolify on Hetzner VPS substrate |
| D8 | Deprecate `narrowstack-core-app` for v1 headless Core |
| D9 | No topology enum — `warehouse.mode` only |
| D10 | Default tenant semantics repos Narrowstack-owned |
| D11 | Rollback-first deploy — snapshot + auto-rollback in W1 |
| D12 | Legacy client probe — spec in G4; research in B/W6 |
| D13 | Govern before build — G8 before `build-loop` |
| D14 | Waves W0–W6 proposed until G8 |

---

## Pending RFCs (Phase G5)

| Topic | Question | Gate |
|---|---|---|
| Semantics delivery | Git clone vs signed OCI bundle | Before W3 build |
| Metric ACL + remote policy | Three-layer model; phone-home ACL push | Before W1 build |
| Semantics repo ownership | Narrowstack-owned vs customer-owned | Before W3 build |
| Headless surface | Deprecate core-app; modeling API as v1 | G1 PRD non-goals |
| OS-338 split | Dogfood dlt vs Airbyte client-delivery demo | G7 Linear |

RFCs live in `operating-system/docs/rfc/` when published.
