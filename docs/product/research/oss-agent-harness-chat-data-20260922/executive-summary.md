# Executive summary — OSS agent/chat harnesses for Core

**Date:** 2026-09-22  
**Inputs:** deep-research sibling (`report.md`) + last30days community run (`last30days-community.md`)  
**Product intent:** chat-with-modeled-data beside headless Core (semantics + ACL stay in Core; no `app_ref` chat GUI in v1).

## Verdict

**Adopt a thin chat/agent shell that calls Core tools (MCP/OpenAPI). Do not adopt a second warehouse/ACL platform as source of truth.**

Default: **LibreChat** (MIT, agents/MCP, multi-provider, multi-user auth). Alternate shell: **Open WebUI** if SSO/SCIM/RBAC outweigh custom-license diligence. Headless skeleton: **LangGraph / LlamaIndex / Haystack** tools over modeling API. Adjuncts only: **Onyx** (org-doc connectors) and/or **RAGFlow** (hard PDFs) - never replace MetricFlow allowlist ACL.

**Hermes (NousResearch/hermes-agent)** is the right *pattern* reference (BYO model, skills, MCP, sandboxes) and the wrong *customer product* (personal agent, weak org SSO/ACL/RAG fabric).

## Top candidates ranked by Core fit

Stars from `gh api` 2026-09-22. Weight = self-host ops (L=light … H=heavy). RAG = persistent KB / connectors / ACL-aware retrieval depth.

| Rank | Name | License | Weight | RAG/KB | Providers | Enterprise | Security posture | Stars / activity | Core fit |
|---:|---|---|---|---|---|---|---|---|---|
| 1 | **LibreChat** | MIT | M | Light (file RAG API) | Excellent (multi-provider + custom) | Multi-user, SAML/OIDC | Self-host, secrets in compose | ~45k, very active | **Best UI harness** - MCP → Core |
| 2 | **LangGraph + thin API** | MIT (libs) | L | Build-your-own | Excellent | You build auth | You own boundaries | N/A | **Best headless** walking skeleton |
| 3 | **LlamaIndex** | MIT | L–M | Strong loaders/indexes | Excellent | Thin | Self-host | N/A (libs) | Docs adjunct + custom metric tools |
| 4 | **Haystack** | Apache-2.0 | L–M | Strong pipelines | Excellent | Thin / enterprise overlay | Self-host | N/A (libs) | Same as frameworks |
| 5 | **Open WebUI** | Custom (OWUI) | M | Solid hybrid RAG + KB | Excellent (Ollama + OpenAI-compat) | SSO/OIDC/LDAP/SCIM/RBAC (CE claims) | Self-host; brand/white-label → EE | ~153k, very active | Strong shell; **license diligence** |
| 6 | **Onyx** (ex-Danswer) | MIT CE + EE carve-out | M–H | **Best** connectors + perm sync (EE) | Excellent | SSO/RBAC/audit (EE-heavy) | Air-gap capable; EE for doc ACL | ~32k, active | **Adjunct org search only** - dual-ACL risk if SoT |
| 7 | **AnythingLLM** | MIT | L | Workspace doc RAG | Good | Basic multi-user | Desktop/Docker simple | ~66k, active | Prototype only |
| 8 | **RAGFlow** | Apache-2.0 | M–H | **Best** layout-aware docs | Good | Limited | Self-host | ~91k, active | PDF/wiki **sidecar** via API |
| 9 | **Hermes Agent** | MIT | L | Weak (memory/skills ≠ enterprise KB) | Excellent | Weak multi-user | Self-host; dashboard auth options | ~248k* anomalous | **Reference pattern**, not customer UI |
| 10 | **Dify** | Apache-2.0 + multi-tenant bar | H | Workflow + knowledge | Excellent | SSO/multi-workspace → Enterprise | Self-host CE; SaaS license risk | ~157k, active | **Avoid default** for Core packaging |
| 11 | **LobeChat / LobeHub** | Custom/NOASSERTION | M | Light | Excellent + MCP skills | Team/agent ops | Self-host | ~83k (lobehub) | Watch; license + scope unclear for Core |
| 12 | **OpenHands / Continue** | MIT / Apache-2.0 | M | N/A (code agents) | Good | Dev-team | Dev sandboxes | ~89k / ~36k | **Wrong product** (coding, not metrics chat) |
| — | MaxKB | GPL-3.0 | M | Agent + KB (CN-heavy) | Good | Enterprise agent platform claims | Self-host | ~23k | Watch; GPL + market fit |
| — | Dust | MIT | M | Connectors (product skew cloud) | Good | Org agents | Mixed | ~1.5k | Low self-host gravity |

\* Hermes star/issue counts look unreliable for health diligence (young repo, extreme numbers) - score architecture, not stars.

## What's hot / shifting (last ~30 days)

- **Hermes-class personal agents** in the spotlight (Nous site + HN ~Sep 1; TikTok "Nanobot"-style personal agent clips).
- **Chat-UI comparison content** consolidates Open WebUI vs LibreChat vs AnythingLLM; Onyx marketing pushes "leave upload RAG for connectors + permission inheritance."
- **License walls called out loudly** - Open WebUI branding/EE; Dify multi-tenant/workspace commercial authorization.
- **Composition over monolith** - RAGFlow/Dify behind Open WebUI via OpenAI-compatible APIs; MCP as the plug language.
- **GitHub heat ≠ Core fit** - OpenHands/Dify dominate stars; they solve coding agents / visual app builders, not MetricFlow chat.

## Explicit comparison vs Hermes

| | Hermes Agent | Core-needed surface |
|---|---|---|
| Shape | Personal self-improving agent + messaging gateways | Multi-user chat over governed metrics/sources |
| Models | Strong BYO / OpenAI-compat | Same - keep |
| Skills/MCP | First-class learning loop + tools | Keep pattern; wire tools to Core ACL |
| RAG/KB | Session memory / FTS, not connector fabric | Need modeled marts + optional org docs |
| Auth/ACL | Dashboard basic/OIDC; not org doc ACL | SSO + Core metric ACL + audit |
| Ops | Light VPS/Docker | Fit ADR-003 VM; don't fork data plane |
| Verdict | **Reference / operator sidecar** | **LibreChat (or OWUI) + Core MCP** |

## Path

`docs/product/research/oss-agent-harness-chat-data-20260922/`

| Artifact | Role |
|---|---|
| `executive-summary.md` | This page |
| `shortlist.md` | Rubric tiers |
| `report.md` / `deep-research.md` | Full deep-research |
| `last30days-community.md` | Community signal synthesis |
| `build-vs-buy-recommendation.md` | Build/buy/self-host one-page verdict |
| `build-vs-buy-chat-with-modeled-data.md` | Full build-vs-buy scorecard |
| `slot-discovery-20260922.md` | Scheduler / LiteLLM / vector-KB gap fill |
| `evidence.jsonl` / `sources.jsonl` / `claims.jsonl` | Citation store |

**Architecture prototype (2026-09-22):** [`docs/architecture/chat-with-modeled-data.md`](../../../architecture/chat-with-modeled-data.md) — Mermaid variants + Archify lean A.

## Gaps / questions

**For deep-research sibling (or next pass)**

1. Confirm Onyx CE vs EE matrix for permission sync / SCIM (what ships without paid EE).
2. LibreChat RAG API vs MCP tool-calling latency/identity passthrough patterns on a single Coolify VM.
3. Open WebUI license text: internal multi-user with branding intact - red lines for NS packaging/resale.
4. Hermes metrics hygiene (stars/issues) - human verify before any popularity claim in buyer docs.
5. DataFoundry / semantic SQL workbenches: consume MetricFlow vs fork semantics?

**For build-vs-buy** — landed 2026-09-22:

- [`build-vs-buy-recommendation.md`](./build-vs-buy-recommendation.md) — one-page verdict  
- [`build-vs-buy-chat-with-modeled-data.md`](./build-vs-buy-chat-with-modeled-data.md) — full scorecard  

Open operator calls (SSO weight, org-doc SKU, OWUI license, Hermes internal) listed in those files.
