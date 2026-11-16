---
kind: architecture
slug: core-runtime-decisions
date: 2026-09-22
verified: 2026-09-22
status: proposed
refs:
  - docs/architecture/decisions.md
  - docs/architecture/chat-with-modeled-data.md
  - docs/product/research/oss-agent-harness-chat-data-20260922/build-vs-buy-chat-with-modeled-data.md
  - docs/product/research/oss-agent-harness-chat-data-20260922/build-vs-buy-chat-surface-acl.md
---

# Core runtime — decisions and open questions

**Summary:** This file keeps four things apart:

- **Operator direction** Tucker gave on 2026-09-22.
- **Proposals** from this synthesis. None is adopted until stamped.
- **Open questions**, deduplicated across the Cursor pack and this pass.
- **Canon edits** these docs imply. They're held until the proposals are stamped.

Narrowstack records decisions in Linear. Each stamped item gets mirrored to its Linear issue, and the dated line goes into the document it governs. This session had no Linear integration, so nothing is mirrored yet.

## Operator direction (Tucker, 2026-09-22)

Given in this working session. Quoted or closely paraphrased; these are not agent decisions.

| # | Direction | Where it bites |
|---|---|---|
| O1 | "I just need the Core context for this": the user edge, model surface, and docs/RAG surfaces are stubs, **not part of the initial execution path**. | [edge-stubs.md](./edge-stubs.md); compose file has Core services only |
| O2 | The API/CLI/MCP "needs to have ACLs to enforce RLS against the system: the front door and bouncer." | [access-control.md](./access-control.md); CORE-API-01, CORE-ACC-05, CORE-ACC-06 |
| O3 | Instance setup includes an optional step to set access up. If not set up, the API defaults to open, "strongly advised against in the setup and docs, but still possible." | CORE-ACC-01, CORE-ACC-02, CORE-ACC-07 |
| O4 | Keep this aspect of Core very lean. Core runs no identity provider; it validates credentials. | CORE-ACC-04, CORE-ACC-11 |
| O5 | White-label of the chat surface: deferred, "probably, but not now." | STUB-EDGE-06; build-vs-buy reassessment trigger |
| O6 | Chat-surface v1 access requirements: row-level metric scoping, per-group model/tool access, per-group doc/KB access, SCIM provisioning. | STUB-EDGE-02 to STUB-EDGE-05 |
| O7 | ≤50 chat users per tenant over 12–24 months. | STUB-EDGE-06 |
| O8 | Goal: a fresh, clean deployment of this architecture on Narrowstack's Coolify, then our own pipelines and schemas, then further functionality. | [deployment-coolify.md](./deployment-coolify.md); the implementation plan |
| O9 | Confirm Open WebUI as the chat surface through build-vs-buy. | [build-vs-buy-chat-surface-acl.md](../../product/research/oss-agent-harness-chat-data-20260922/build-vs-buy-chat-surface-acl.md) (verdict pending stamp) |

## Proposed by this synthesis (awaiting stamp)

Each is reversible unless marked **one-way**. "Stamp" means Tucker says yes, and the decision line lands in the doc it governs.

| # | Proposal | Why | Reversibility |
|---|---|---|---|
| P1 | REST and MCP served by **one process** with one enforcement library | One place to get access control right; REST and MCP can't drift | Cheap to split later |
| P2 | CLI metric reads go **through the API**; no direct query path | The bouncer has no side door (INV-1) | Cheap |
| P3 | Green-check runs inside a **long-lived runner**, not a one-shot init container | Coolify ignores `profiles:` unreliably and one-shot services need the Coolify-only `exclude_from_hc` key, which breaks standard `docker compose config` | Cheap |
| P4 | **Blue/green generation schemas** (`marts__gN`); rollback = pointer flip. Alternative: in-place rebuild + `pg_dump` restore (canon today) | Rollback in seconds; the API never sees half-built marts. Cost: about 2× mart storage | Medium: changes dbt schema naming in the semantics template |
| P5 | Row scope enforced by **API filter injection** now; **Postgres RLS backstop** later | Lean first; RLS needs dbt post-hooks because full-refresh drops tables and their policies | Cheap to add the backstop |
| P6 | Chat edge and model plane run as **separate Coolify resources**, not in Core's compose | Keeps Core lean and the edge swappable (INV-12); Coolify one-click templates exist for both | Cheap |
| P7 | **Retire `AGENT_PG_PASSWORD`**: agents authenticate to the API and never hold a database credential | INV-2. PRD step 1 still holds, because the agent's token is its distinct credential | Schema change: `secrets_refs.agent_pg_password` |
| P8 | Runner clones the semantics repo with a **read-only deploy key** from a runtime env var (alternative: GitHub App installation token) | Coolify's deploy keys only cover Coolify's own clone | Cheap |
| P9 | `pgvector/pgvector:0.8.6-pg16` from day one; `vector` extension created only when the knowledge plane activates | Avoids an image swap later; same Postgres major | Cheap |
| P10 | Access config in the **manifest**: an `access` block and `principals[].row_scope` | A second instance must reproduce its grants from the config commit (PRD step 1) | **One-way-ish**: manifest wire format (schema change) |
| P11 | **No host ports**; the API is the only public surface | INV-10 | Cheap |
| P12 | Evolve `compose/local-warehouse/` in place. Cursor's `compose/{modeling-api,litellm,chat-ui}/` split is not adopted | One compose per `warehouse.mode` (D9); Coolify takes one compose file per resource | Cheap |
| P13 | The headless example agent (`examples/headless-agent/`) runs **off the VM** as an integrator client and eval | Variant C is the API; an idle agent container adds nothing | Cheap |
| P14 | Open-mode semantics: allowlist and warehouse roles stay on; principal ACL and row scope off; loud signals on every surface | Honors O3 without letting open mode exceed what ships | Cheap |
| P15 | Coolify scheduled database backups as the platform backup; restore scripted (`ns-core restore`) | Coolify's restore UI doesn't cover databases inside a compose resource | Cheap |
| P16 | New top-level build contexts `runner/` and `api/` (Phase B) | Extends the canonical repo layout; needed for Coolify builds | Cheap |

## Open questions

Deduplicated. **Blocking** = blocks the first clean Coolify deploy.

| # | Question | Raised in | Owner | Blocking |
|---|---|---|---|---|
| Q1 | Does G8 sign-off, which opens Phase B, cover a **Core-only first slice** so the Coolify deploy can proceed ahead of the remaining Phase G items? | `docs/process/wave-review-gate.md`; D13/D14 | Tucker | **Yes** |
| Q2 | Manifest lives in the semantics repo but pins the semantics ref. Proposed resolution: env `NS_SEMANTICS_REF` is the deploy input, and gate stage 3 requires `manifest.semantics_ref` to equal it. Confirm. | This pass | Tucker | Yes |
| Q3 | P4: blue/green schemas or in-place rebuild + `pg_dump`? | This pass | Tucker | Yes (shapes the runner and template) |
| Q4 | Provider modes M0–M3 are referenced by the manifest schema, PRD step 7, and the kill-switch "M0 chat exception", but defined nowhere in this repo. Link or port the provider spec. | Canon sweep | Tucker | No (PRD step 7 is later) |
| Q5 | Should open mode require an explicit acknowledgement (for example `access.mode: open` written out) instead of "no `access` block"? Direction O3 says default open when unset; this only asks whether to add friction. | This pass | Tucker | No |
| Q6 | Semantics credential: deploy key (P8) or GitHub App installation token? | Coolify research | Tucker | Yes (pick one) |
| Q7 | Will Coolify's magic `SERVICE_PASSWORD_*` / `SERVICE_URL_*` values generate for a **git-sourced** compose resource? Confirmed only for one-click templates. Manual fallback works either way. | Coolify research | Verify on first deploy | No |
| Q8 | Does Coolify inject **every** resource variable into **every** container? If so, the API would see loader and source secrets (CORE-SEC-03). Fallback: split secrets per service with Coolify's per-service env, or move source secrets to the runner only through a mounted file. | This pass | Verify on first deploy | Yes, if it fails |
| Q9 | First bootstrap duration vs Coolify's deploy timeout (runner `start_period` is 30 minutes). Large first loads may need a staged first generation. | This pass | Verify on first deploy | Maybe |
| Q10 | MCP Python SDK: pin 1.x or adopt 2.x? (2.0.0 shipped 2026-07-28 with breaking changes.) | Gateway/data research | Build-time | No |
| Q11 | Manifest lint in the runner: ship Node for `lint-manifest.mjs`, or port it to Python? | This pass | Build-time | No |
| Q12 | Chat edge pick: Open WebUI or LibreChat (build-vs-buy re-run 2026-09-22). | Cursor pack; O9 | Tucker | No (edge is a stub) |
| Q13 | LiteLLM: are any enterprise-directory features needed (SSO for its admin UI, tag budgets)? The MIT core covers keys, budgets, and spend. | Slot discovery; research | Tucker | No |
| Q14 | Knowledge plane: allowlist equivalent for documents, and embedding path (local model or via LiteLLM). | Slot discovery; canon sweep | Tucker | No |
| Q15 | Scheduler upgrade path: when to move from cron + green-check to Prefect or Kestra. | Cursor pack | Tucker | No |
| Q16 | ADR-001 still says Hermes is the v0 agent runtime; the research treats Hermes as an operator-only sidecar. Restamp before its 2026-11-17 revisit? | Cursor pack; decisions.md | Tucker | No |
| Q17 | Variant B (Onyx or RAGFlow document plane) timing, and whether Onyx CE is enough or EE is required. | Cursor pack | Tucker | No |
| Q18 | Postgres RLS backstop (CORE-ACC-12): which build slice? | This pass | Tucker | No |

## Canon edits implied (apply only after the related proposal is stamped)

| File | Edit | Depends on |
|---|---|---|
| `docs/product/prd.md` | MoSCoW: "MCP native server" moves from Could into the Core surface; note the stubbed edge/model/knowledge planes | O2 (given); confirm wording |
| `docs/features/modeling-api.md` | Remove "MCP server in v1" from non-goals; add `/mcp`, `whoami`, `status`, row scope, audit | O2, P1 |
| `docs/features/metric-acl.md` | Reconcile "all three layers required" with open mode (layer 3 optional; layers 1–2 always on); add row scope | O3, P5, P14 |
| `manifest/schema.json` + `docs/features/instance-manifest.md` | Add `access` block and `principals[].row_scope`; retire `secrets_refs.agent_pg_password` | P7, P10 |
| `docs/features/ns-core-cli.md` | Add `bootstrap`, `refresh`, `generations`, `access`, `query` | P2, P3 |
| `docs/features/local-warehouse-deploy.md` | Point at the evolved compose; add runner/api services and the Coolify resource shape | P3, P12 |
| `README.md` + `docs/plans/narrowstack-core-architecture-20260831.md` | Repo layout: `runner/`, `api/`, `examples/headless-agent/` | P13, P16 |
| `docs/product/roadmap.md` | Re-sequence waves for a Coolify-first Core slice | The implementation plan |
| `docs/architecture/decisions.md` | ADR-001 Hermes wording | Q16 |

## Research-quality notes

- `report.md` and `deep-research.md` in the research pack are byte-identical. Cite one; don't count them as independent sources.
- The Hermes star count (~248k) is flagged as anomalous in three files but still sits in the ranked table in `executive-summary.md`. Don't repeat it without the caveat.
- `claims.jsonl` marks all 10 claims "supported" and doesn't carry the Hermes caveat as a scored claim.
- Local filesystem paths leaked into `run_manifest.json`, `last30days-community.md`, and `chat-data-plane/lean-core-librechat.visual-check.json` in the Cursor commit. They're redacted on this branch, but they remain in the history of the already-pushed `feat/chat-data-architecture` branch. They're paths, not secrets, so the fix-forward covers the tree. Whether to rewrite that branch's history is Tucker's call.
