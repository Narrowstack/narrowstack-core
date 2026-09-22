# OSS Agent / Chat Harnesses for Chat-with-Modeled-Data (Narrowstack Core)

**Date:** 2026-09-22  
**Mode:** deep (citation-verified)  
**Repo context:** Narrowstack Core — IaC shell for headless Core v1 (manifest, deploy gates, semantics templates, ACL). Chat GUI (`narrowstack-core-app`) is deprecated for v1; any harness sits *alongside* Core to chat with modeled sources, not replace the semantic layer.

---

## Executive Summary

The correct Hermes reference is **Nous Research `hermes-agent`** (MIT): a personal/self-improving agent runtime with multi-provider models, skills, MCP, sandbox backends, and messaging gateways — not an enterprise RAG/SSO platform [1][2]. It is a useful *architecture analogy* (thin harness + tools + BYO model) and a weak *product* fit for multi-user org chat over a governed warehouse.

Across 30 primary sources, the self-hosted landscape splits into three layers: finished RAG/chat platforms with connectors, chat UIs with light RAG, and code-first frameworks you assemble [5]. For Narrowstack Core, the binding constraint is **chat against a modeled, ACL-gated semantic layer** (MetricFlow/marts/allowlist), not Slack/Drive enterprise search. Platforms that re-own ingestion and ACL (Onyx EE, AgentSwarms lakehouse) compete with Core rather than complement it. Chat UIs that expose agents/MCP and SSO (LibreChat, Open WebUI) complement Core if tools call Core’s modeling API. Specialized RAG engines (RAGFlow) and SQL/semantic workbenches (DataFoundry) are optional adjuncts for unstructured docs or warehouse Q&A respectively [9][10][25].

**Primary recommendation:** treat the product as a **thin harness + Core tools**, not a second data platform. **Adopt LibreChat** (or Open WebUI if community-edition SSO/SCIM outweighs license friction) as the chat/agent shell; **expose Core as MCP/OpenAPI tools** that enforce Core ACL; **add Onyx only** if customers need org-document RAG with connector sync as a *second* knowledge plane; **build thin** LangGraph/Haystack/LlamaIndex agents when the walking skeleton is “one question against one metric” without a heavy UI [11][15][20][23][24].

**Confidence:** Medium-high on taxonomy and license/enterprise gates (primary docs + cross-comparisons); medium on ops footprint numbers (vendor marketing mixed with independent blogs); low on Hermes star/issue metrics as a health signal (anomalously high for project age).

---

## Introduction

### Research Question

Which open-source, self-hostable, relatively lightweight AI agent/chat harnesses best support enterprise-grade auth/ops, real knowledgebase/RAG connectors (not paste-PDF only), model-provider freedom, and “chat with your data” when wired beside Narrowstack Core’s semantics + ACL framework?

### Why It Matters

Core’s PRD defines success as headless reproducibility: config commit → tied-out metric via modeling API/CLI, with allowlist and three-layer metric ACL. Restoring a full chat GUI in-core is a non-goal for v1. Buyers still expect a chat surface. Choosing a harness that silently reimplements warehouse, ACL, or multi-tenant SaaS licensing creates dual systems of truth and procurement risk.

### Scope

**In:** OSS/self-hostable chat UIs, agent harnesses, RAG platforms, and orchestration frameworks that can sit on a customer VM (ADR-003 style isolation).  
**Out:** Managed-only SaaS, coding agents as primary product (OpenHands/Continue), closed enterprise suites, and last-30-days sentiment (sibling `last30days` run).

### Assumptions (surfaced)

1. Core remains source of truth for metrics, entity keys, and ACL; harness must not become a parallel semantic layer.  
2. “Lightweight” means ops footprint compatible with one VM per customer, not Kubernetes-only.  
3. Enterprise features may sit in paid EE tiers; that is scored as adopt-risk, not disqualification.  
4. Hermes means Nous Research hermes-agent, verified against GitHub + product site [1][2].

### Methodology (summary)

Deep mode: parallel web retrieval + primary README/docs fetches + `gh api` repo metadata; evidence persisted to `evidence.jsonl`; claims cited inline. Search-cli unavailable; WebSearch/WebFetch + GitHub API used. Full method in Methodology Appendix.

### Rubric (1–5, Core-weighted)

| Dimension | Means |
|---|---|
| Architecture fit | Harness vs full platform vs thin UI vs framework |
| Lightweight | Compose services, RAM floor, “lite” mode |
| RAG/KB depth | Persistent indexes, sync connectors, SQL/warehouse |
| Model agnosticism | OpenAI-compatible gateway, Anthropic, Azure, local |
| Security & enterprise | SSO/OIDC/SAML, RBAC, audit, isolation, secrets |
| Embeddability | MCP/API/tools next to Core IaC + ACL |
| License & community | Permissive license, active maintenance, health caveats |
| Adopt risk | Dual-stack / EE lock-in / license SaaS bars (5 = low risk) |

---

## Main Analysis

## Finding 1 — Hermes Is the Right Reference Project, Wrong Product Shape

The project matching the “Hermes” shorthand is **NousResearch/hermes-agent**, marketed as Hermes Agent by Nous Research, MIT-licensed, installable via curl installer or desktop apps [1][2]. Primary positioning is a self-improving personal agent: skills from experience, FTS5 memory, cron, subagents, multi-surface gateways (Telegram/Discord/Slack/WhatsApp/Signal/CLI), and multiple terminal sandbox backends [1][2]. Model choice is explicitly provider-agnostic (OpenRouter, OpenAI, custom endpoints, Nous Portal optional) [1][2].

What Hermes is *not*: a multi-tenant chat product with org SSO, document-level ACL inherited from Confluence/Drive, audit dashboards for enterprises, or first-class warehouse/RAG connector catalogs. Those gaps are structural, not missing toggles. For Narrowstack, Hermes scores high on harness lightness and model freedom, and low on enterprise controls and modeled-KB depth. Use it as a pattern reference (skills + MCP + BYO model + sandbox) and as a possible *operator* sidecar, not as the customer-facing Core chat surface.

GitHub API (2026-09-22) reports ~248k stars and tens of thousands of open issues for a repo created 2025-07-22. Treat popularity metrics as unreliable for due diligence until a human verifies issue hygiene; rely on docs and architecture fit instead.

**Rubric (Hermes):** Arch 4 · Light 5 · RAG 2 · Models 5 · Ent 1 · Embed 4 · License 5 · Risk 2 → **tier: reference / avoid as primary product**

---

## Finding 2 — Three Layers, One Decision Rule for Core

Independent and vendor surveys converge on a three-layer map: (1) batteries-included platforms with UI + connectors, (2) chat UIs with light file RAG, (3) frameworks (Haystack, LlamaIndex, LangChain/LangGraph) plus vector infra [5][27]. Decision rule for Core:

- If the job is **workforce enterprise search** across SaaS apps with permission mirroring → platform layer (Onyx EE strength) [4][5][16].  
- If the job is **chat + agents calling Core’s already-modeled API** → chat-UI / harness layer (LibreChat, Open WebUI) [11][15][17].  
- If the job is **custom agent graphs over MetricFlow with no product UI yet** → framework layer [20][22][23][24].  
- If the job is **deep PDF/table parsing** as an adjunct → RAGFlow as a retrieval microservice [9][10][27].

Narrowstack’s walking skeleton (“one question, one grant”) maps to framework or thin harness first. Buying a full second platform early maximizes ops and dual-ACL risk.

---

## Finding 3 — Shortlist Rubric Scores (10 Candidates)

Scores are Core-weighted judgments from cited capabilities, not marketing feature counts. Scale 1–5.

| Candidate | Arch | Light | RAG | Models | Ent | Embed | Lic/Comm | Risk↓ | Total | Shape |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| LibreChat | 5 | 4 | 2 | 5 | 4 | 5 | 5 | 4 | **34** | Thin chat + agents + MCP |
| Open WebUI | 4 | 4 | 3 | 5 | 5* | 4 | 3 | 3 | **31** | Full chat platform |
| Onyx (CE/EE) | 3 | 2–4† | 5 | 5 | 3/5‡ | 3 | 4 | 2 | **27–31** | Enterprise RAG platform |
| LangGraph + thin API | 5 | 5 | 3§ | 5 | 2 | 5 | 5 | 3 | **33** | Build-thin harness |
| Haystack | 4 | 4 | 4 | 5 | 2 | 5 | 5 | 3 | **32** | Framework |
| LlamaIndex | 4 | 4 | 5 | 5 | 2 | 5 | 5 | 3 | **33** | Framework + loaders |
| RAGFlow | 3 | 2 | 5 | 4 | 2 | 4 | 4 | 3 | **27** | RAG engine |
| Dify | 3 | 2 | 3 | 5 | 2/5‡ | 3 | 2 | 1 | **21–24** | Workflow platform |
| AnythingLLM | 3 | 5 | 3 | 5 | 2 | 3 | 4 | 3 | **28** | Workspace doc Q&A |
| Hermes | 4 | 5 | 2 | 5 | 1 | 4 | 4¶ | 2 | **27** | Personal agent |
| DataFoundry | 3 | 3 | 4 | 4 | 3 | 3 | 2 | 2 | **24** | SQL/semantic workbench |
| AgentSwarms | 2 | 1 | 5 | 3 | 3 | 2 | 2 | 1 | **19** | Agents + lakehouse |

\* Community edition documents SSO/OIDC/LDAP/SCIM/RBAC [15][16].  
† Onyx Lite &lt;1GB chat-only; Standard needs OpenSearch workers [3][28].  
‡ Enterprise features gated (Onyx RBAC/doc ACL; Dify SSO/multi-workspace) [4][7][8][30].  
§ Framework RAG depth depends on what you build.  
¶ Hermes community metrics anomalous; license MIT is clean [1][2].

---

## Finding 4 — Candidate Deep Dives (Wire to Modeled Knowledge)

### LibreChat — best default adopt for Core-adjacent chat

LibreChat is an MIT multi-provider chat workbench with Agents, Skills, MCP, code interpreter, and secure multi-user auth [11]. SAML and OIDC are supported (mutually exclusive at a time) [12]. MCP is first-class with OAuth/tool credential patterns suitable for calling a Core MCP server [13]. Built-in RAG is file-upload oriented via a RAG API sidecar — useful, not a connector fabric [14][5][17].

**Wire to Core:** Deploy LibreChat on the customer VM; register an MCP server (or OpenAPI Actions) that wraps `ns-core` / modeling API with per-user identity passthrough; enforce allowlist + metric ACL inside Core, not in LibreChat’s vector store. Optional: use LibreChat file RAG for runbooks, keep marts off-vector.

**Tier: adopt (UI harness) / fork-extend (agent presets + Core skills)**

### Open WebUI — adopt if community SSO/SCIM is the priority

Open WebUI documents RBAC, OIDC/SSO, LDAP, SCIM 2.0, and per-resource ACL on knowledge bases/tools in the free edition [15]. Comparators note it is stronger than LibreChat on knowledge/RAG surface area and weaker than Onyx EE on source-permission inheritance [16][17]. Migration guidance flags a branding/license wall at 50+ users and a custom (non-BSD) license posture that procurement must review [28][5]. Ops can stay single-container-ish versus Onyx’s multi-service stack [28].

**Wire to Core:** Tools/Pipelines/MCP calling Core; knowledge bases for unstructured docs only. Do not index warehouse tables into OWUI as a substitute for MetricFlow.

**Tier: adopt (enterprise-auth chat) with license diligence; avoid as sole RAG platform**

### Onyx (formerly Danswer) — adopt as optional second plane, not Core replacement

Onyx ships agentic RAG, 50+ connectors or MCP, hybrid index, custom agents, and dual CE (MIT core) / EE (SSO/SCIM/RBAC/analytics/query history) [3][4]. Docs state document RBAC and source permission mirroring are EE [4]. Lite mode drops RAG infra for chat-only under ~1GB; Standard adds OpenSearch, workers, Redis, MinIO [3][28]. Independent comparisons recommend Onyx when connector breadth + permission-aware retrieval dominate [5][27].

**Wire to Core:** Use Onyx for Slack/Drive/Confluence-style knowledge. Keep metrics/SQL answers in Core tools. Dual-ACL is the main risk — never let Onyx’s document ACLs become the metric grant system.

**Tier: adopt (org-doc RAG adjunct) / avoid (as Core’s semantic layer)**

### Dify — avoid as default; fork-extend only with legal review

Dify is a visual agent/workflow/RAG studio. Community license is Apache-2.0-derived with extra conditions; multi-tenant SaaS operation without LangGenius authorization is barred [6][8][30]. Enterprise adds SSO/SAML, fine-grained RBAC, audit/SIEM, Helm/air-gap [7]. Community vs Enterprise is license-unlocked on the same images via Enterprise API env vars [30]. Built-in RAG is faster to ship but often weaker than dedicated engines on complex docs [27][5].

**Wire to Core:** Possible as internal workflow builder calling Core APIs — high license friction if Narrowstack ever hosts multi-tenant.

**Tier: avoid (default) / conditional commercial license if visual builder is mandatory**

### RAGFlow — adopt as retrieval microservice for documents

Apache-2.0 RAG engine focused on deep parsing and context quality; self-host floor ~4 CPU / 16GB RAM [9]. v0.22 adds synchronized data sources (Confluence, S3, Drive, Notion, DBs, etc.) into datasets [10]. Positioned as API-first “RAG brain,” not full LLMOps studio [27].

**Wire to Core:** Index customer PDFs/wikis; Core agent tool retrieves citations when questions are document-shaped. Structured metric questions stay on MetricFlow.

**Tier: adopt (doc RAG sidecar) / build-thin-on-top (API only)**

### AnythingLLM — light workspace Q&A; weak enterprise SSO

MIT, Docker multi-user, workspace RAG, agents, embeddable widget [18]. SSO is Simple SSO passthrough (issue short-lived auth links), not native OIDC/SAML productization [19]. Connector depth is modest versus Onyx [5][29].

**Wire to Core:** Prototype only, or desktop-adjacent demos. Production Core should not depend on Simple SSO as the IdP story.

**Tier: avoid (primary) / adopt (throwaway prototype)**

### Haystack / LlamaIndex / LangGraph — build-thin-on-top for headless v1

Haystack (Apache-2.0) and LlamaIndex (MIT) are vendor-agnostic orchestration/RAG frameworks; LlamaIndex emphasizes broad loaders (LlamaHub), Haystack emphasizes pipeline serialization and enterprise connectors via deepset’s commercial overlay [20][21][22][23]. LangGraph (MIT) supplies durable agent graphs when the product is tool-calling over Core, not document RAG [24][27]. These match Core’s headless v1 and “bounded agent tooling” language.

**Wire to Core:** Agent tools = allowlisted `mf query` / modeling API; optional LlamaIndex loaders for docs; no second ACL store.

**Tier: build-thin-on-top (recommended for walking skeleton)**

### DataFoundry — watchlist for semantic/SQL agents

Apache-2.0 workbench: 28 datasource types, read-only analysis, auditability, OpenAI-compatible models, “enterprise semantics & context” [25]. Low star count (~37 via GitHub API 2026-09-22) ⇒ maturity risk. Conceptually closer to Core’s domain than Slack-RAG platforms.

**Wire to Core:** Evaluate whether it can *consume* Core semantics rather than define competing ones. If not, avoid dual semantics.

**Tier: watch / spike — not adopt yet**

### AgentSwarms — avoid overlap with Core’s data plane

Source-available platform combining agents with 27 DB/warehouse connectors (Snowflake, BigQuery, Postgres, etc.), lakehouse, BI, row filters/column masking [26]. This is a competing data platform, not a lightweight harness beside Core. Immature community (~257 stars).

**Tier: avoid**

---

## Finding 5 — Security, License, and Ops Gates That Change the Tier

Enterprise SSO appearing in README is not the same as CE availability. Onyx documents SSO options broadly but gates document RBAC and permission mirroring to EE [4]. Dify gates multi-workspace/SSO to Enterprise and restricts multi-tenant SaaS in the OSS license [7][8][30]. Open WebUI advertises SCIM/SSO in community docs but carries a custom license and branding constraints at scale [15][28][5]. LibreChat’s MIT + SAML/OIDC is the cleanest “chat shell” procurement story among UI options reviewed [11][12].

Ops: Onyx Standard and RAGFlow assume multi-service stacks (OpenSearch/ES, workers, object storage) [3][9][28]. AnythingLLM and Onyx Lite / Open WebUI stay closer to “one VM friendly” [3][18][28]. Core’s one-VM-per-customer posture favors thin shells unless a customer explicitly buys org-search.

Secrets: prefer harnesses that take provider keys via env (aligned with Core’s env-var-in-manifest pattern) and keep tool credentials server-side. LibreChat MCP OAuth and Core-issued short-lived tokens are preferable to stuffing warehouse passwords into chat UIs.

---

## Finding 6 — “Chat With Your Data” Mapping (Modeled Layer vs Paste-PDF)

| Knowledge kind | Own in Core? | Harness role |
|---|---|---|
| Metrics, marts, entity keys, allowlist ACL | Yes | Tools/MCP only; show SQL/query |
| Tenant semantics repo (dbt/MetricFlow) | Yes (pinned `semantics_ref`) | Never re-ingest as vectors as SoT |
| SaaS docs (Drive, Confluence, Slack) | No | Onyx / RAGFlow connectors |
| PDFs / policies | Optional | RAGFlow or LibreChat/OWUI file RAG |
| Raw warehouse SQL chat | Boundary | Prefer MetricFlow; DataFoundry/AgentSwarms only if ACL-equivalent |

Paste-PDF architectures (AnythingLLM workspaces, LibreChat RAG API uploads, Open WebUI knowledge uploads) fail the Core “modeled real sources” bar when used alone [14][18][5]. Connector platforms fix sync but invent a second permission model [4][5]. The durable pattern is **Core as governed query plane + optional doc RAG plane + thin chat harness**.

---

## Synthesis & Insights

The market labels almost everything an “AI platform.” For Narrowstack, architecture fit collapses to whether the candidate **owns data semantics** or **calls them**. Hermes, LibreChat, and LangGraph call. Onyx, Dify, AgentSwarms, and DataFoundry tend to own (to varying degrees). RAGFlow owns retrieval quality for documents without pretending to be the warehouse.

A second insight: **enterprise features and open-source licenses have decoupled**. MIT CE cores with EE ACL (Onyx) and Apache-derivative licenses with SaaS bars (Dify) are the dominant commercial pattern [3][8][30]. Build-vs-buy must price EE or accept building ACL in Core (already planned).

Third: **lightweight** and **RAG-deep** anti-correlate at the platform layer [5][28]. Core should not optimize for both in one box on day one.

---

## Limitations & Caveats

- Vendor docs and comparison pages (including Onyx’s own guides and Open WebUI alternatives pages) are interested parties; triangulation used but residual bias remains [5][16][17][28].  
- Live connector inventories change quickly (RAGFlow 0.22, Onyx “50+”); treat counts as order-of-magnitude [3][10].  
- Hermes popularity metrics look pathological; do not use stars as quality evidence.  
- No hands-on deploy benchmarks in this run (RAM/CPU on Coolify/Hetzner not measured).  
- last30days sentiment is out of scope (sibling agent).  
- Open WebUI full license text not reproduced here; legal review still required before adopt.  
- DataFoundry/AgentSwarms maturity not production-proven in cited materials.

---

## Recommendations (Tiers)

### Adopt

1. **LibreChat** as default customer/operator chat + agent shell (MIT, SAML/OIDC, MCP) [11][12][13].  
2. **LangGraph or Haystack/LlamaIndex** for headless walking-skeleton agents over Core tools [20][23][24].  
3. **Onyx** only when a deal requires synced org-document RAG; budget EE if permission mirroring matters [3][4][5].  
4. **RAGFlow** when document parsing quality is a separate SKU/need [9][10][27].

### Fork-extend

- LibreChat agent/Skills packs that encode Narrowstack query patterns (show query, respect allowlist errors).  
- Open WebUI Pipelines/Tools similarly, after license review [15][28].

### Build-thin-on-top

- Core MCP/OpenAPI server + minimal chat (LibreChat or even CLI-first).  
- Framework agents for MetricFlow Q&A without adopting a second ACL store [22][24].

### Avoid

- **Hermes** as primary multi-user enterprise surface [1][2].  
- **Dify** without commercial terms if multi-tenant/hosted path exists [8][30].  
- **AnythingLLM** as enterprise SSO/RAG backbone [19][5].  
- **AgentSwarms** as overlapping data platform [26].  
- Using **any** vector RAG as substitute for MetricFlow metrics.

---

## Open Questions for Build-vs-Buy

1. Is the first paid chat surface **operator-only** or **customer-end-user**? (Changes SSO/SCIM weight.)  
2. Must v1 answer **metric questions only**, or also **unstructured org docs** in the same UI?  
3. Accept **Onyx EE** cost for permission-aware connectors, or keep all ACL in Core?  
4. Coolify/single-VM RAM budget: can Standard Onyx/RAGFlow coexist with warehouse profile?  
5. License posture: will Narrowstack ever offer **multi-tenant hosted chat**? (Dify bar; OWUI branding.)  
6. Identity: one IdP across Coolify, Core API, and chat — OIDC everywhere?  
7. MCP vs OpenAPI for Core tools — security review of tool sandboxing.  
8. Telemetry: harness audit logs vs Core consent/telemetry protocol alignment.  
9. Does DataFoundry’s “semantics” conflict with private `semantics_ref` repos?  
10. Preserve Hermes only as internal ops agent?

---

## Counterevidence Register

| Claim pressure | Counterevidence | Handling |
|---|---|---|
| Prefer thin chat UI | Onyx/OWUI argue workforce search needs connectors + permission sync [5][16] | True if org-doc search is in-scope; Core’s first skeleton is metric Q&A — sequence adjuncts later |
| LibreChat “enterprise ready” | Built-in RAG is upload-centric; SCIM less emphasized than OWUI [14][15][17] | Pair LibreChat with Core ACL + optional Onyx/RAGFlow |
| Avoid Dify | Fastest path to visual apps [27] | Speed does not clear multi-tenant license bar [8][30] |
| Hermes as product | Extremely high GitHub stars | Metrics unreliable; architecture still personal-agent shaped [1][2] |
| Frameworks too slow | Batteries-included platforms ship UI faster [27] | Core already owns packaging; UI is the thinner problem |

## Claims-Evidence Table

| ID | Claim | Evidence |
|---|---|---|
| c01 | Hermes = Nous hermes-agent, personal harness | [1][2] |
| c02 | Three-layer landscape | [5][27] |
| c03 | Onyx CE MIT; doc ACL/RBAC EE | [3][4] |
| c04 | Dify license + EE SSO gate | [6][7][8][30] |
| c05 | LibreChat MIT + SAML/OIDC + MCP | [11][12][13] |
| c06 | OWUI CE SSO/SCIM; weaker source ACL than Onyx EE | [15][16] |
| c07 | LibreChat/OWUI chat-first light RAG | [5][14][17] |
| c08 | RAGFlow connectors + 16GB floor | [9][10] |
| c09 | AnythingLLM Simple SSO only | [19] |
| c10 | Onyx Lite vs Standard ops split | [3][28] |

---

## Bibliography

[1] Nous Research. *NousResearch/hermes-agent* (GitHub). https://github.com/NousResearch/hermes-agent  
[2] Nous Research. *Hermes Agent* (product site). https://hermes-agent.nousresearch.com/  
[3] Onyx. *README — The Open Source AI Platform*. https://raw.githubusercontent.com/onyx-dot-app/onyx/main/README.md  
[4] Onyx. *Access Controls*. https://docs.onyx.app/security/architecture/access_controls  
[5] Onyx AI. *Self-Hosted RAG: Stacks, Platforms, and Setup Guide for 2026*. https://onyx.app/insights/self-hosted-rag  
[6] LangGenius. *langgenius/dify* (GitHub). https://github.com/langgenius/dify  
[7] Dify. *Dify Enterprise*. https://dify.ai/dify-enterprise  
[8] Prompt Quorum. *Dify Review 2026*. https://www.promptquorum.com/power-local-llm/dify-ai-workflow-builder-review  
[9] InfiniFlow. *infiniflow/ragflow* (GitHub). https://github.com/infiniflow/ragflow  
[10] RAGFlow. *0.22.0 Overview — Supported Data Sources*. https://ragflow.io/blog/ragflow-0.22.0-data-source-synchronization-enhanced-parser-agent-optimization-and-admin-ui  
[11] Danny Avila et al. *LibreChat* (GitHub). https://github.com/danny-avila/LibreChat  
[12] LibreChat. *SAML Authentication*. https://www.librechat.ai/docs/configuration/authentication/SAML  
[13] LibreChat. *MCP*. https://www.librechat.ai/docs/features/mcp  
[14] LibreChat. *RAG API*. https://www.librechat.ai/docs/configuration/rag_api  
[15] Open WebUI. *Authentication & Access*. https://docs.openwebui.com/features/authentication-access/  
[16] Open WebUI. *Open WebUI vs Onyx*. https://docs.openwebui.com/alternatives/onyx/  
[17] Open WebUI. *Open WebUI vs LibreChat*. https://docs.openwebui.com/alternatives/librechat/  
[18] Mintplex Labs. *anything-llm* (GitHub). https://github.com/Mintplex-Labs/anything-llm  
[19] Mintplex Labs. *AnythingLLM Configuration (Simple SSO)*. https://docs.anythingllm.com/configuration  
[20] deepset. *Haystack* (GitHub). https://github.com/deepset-ai/haystack  
[21] deepset. *Haystack* (site). https://haystack.deepset.ai/  
[22] ZenML. *Haystack vs LlamaIndex*. https://www.zenml.io/blog/haystack-vs-llamaindex  
[23] LlamaIndex. *llama_index* (GitHub). https://github.com/run-llama/llama_index  
[24] LangChain. *langgraph* (GitHub). https://github.com/langchain-ai/langgraph  
[25] DataGallery Lab. *datafoundry* (GitHub). https://github.com/datagallery-lab/datafoundry  
[26] AgentSwarms. *agentswarms* (GitHub). https://github.com/AgentSwarms-fyi/agentswarms  
[27] Param Harrison / learnwithparam. *Batteries-included RAG platforms: Dify vs RagFlow vs Onyx* (2025-10-29). https://www.learnwithparam.com/blog/batteries-included-rag-platforms-dify-ragflow-onyx  
[28] Onyx AI. *Open WebUI to Onyx Migration Guide (2026)*. https://onyx.app/insights/open-webui-to-onyx-migration  
[29] Open WebUI Docs. *AnythingLLM alternative*. https://github.com/open-webui/docs/blob/main/docs/alternatives/anythingllm.mdx  
[30] LangGenius. *Self-Hosted Plans discussion #32254*. https://github.com/langgenius/dify/discussions/32254  

---

## Methodology Appendix

**Mode:** deep (8-phase pipeline per deep-research skill).  
**Date context:** 2026-09-22.  
**Retrieval:** WebSearch/WebFetch (search-cli not installed); GitHub REST via `gh api` for stars/licenses; primary README/docs preferred over secondary blogs; blogs used for triangulation only.  
**Evidence:** `sources.jsonl` (30), `evidence.jsonl` (28+), `run_manifest.json`.  
**Verification:** factual claims tied to evidence spans; EE vs CE distinctions taken from vendor security/license docs where available.  
**Non-goals:** no product code, no git commit, no last30days scrape.  
**Product context read:** `README.md`, `docs/product/prd.md` (headless Core, deprecated app, ACL/allowlist).
