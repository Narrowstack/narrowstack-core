# Build vs buy — chat with modeled data beside Narrowstack Core

_As of 2026-09-22. Re-run Step 3–5 if the reassessment trigger below fires,
or if a candidate's pricing/license/health changes materially._

**Companion:** [`build-vs-buy-recommendation.md`](./build-vs-buy-recommendation.md) (one-page verdict).  
**Inputs:** [`executive-summary.md`](./executive-summary.md), [`shortlist.md`](./shortlist.md), [`report.md`](./report.md), [`last30days-community.md`](./last30days-community.md), Core [`README.md`](../../../README.md) + [`docs/product/prd.md`](../../prd.md).  
**Artifact home:** research folder (no `docs/decisions/` in this repo yet). Status ledger skipped — Narrowstack forbids parallel `status.yaml`.

## The job

Let a user ask a natural-language question and get a **governed answer from real modeled sources** (MetricFlow/marts + allowlist ACL via Core tools), optionally with citations from org docs/PDFs — without a second warehouse/ACL platform becoming source of truth.

## Candidates

Grouped decision objects (build custom + self-host OSS landscape both mandatory):

| # | Option | Shape |
|---|---|---|
| A | **Build custom thin chat + Core tools** | Minimal UI/API we own; tools = modeling API / MCP |
| B | **Self-host LibreChat** | Adopt OSS chat/agent shell; MCP → Core |
| C | **Self-host Open WebUI** | Alternate shell; license diligence required |
| D | **Adopt-OSS LangGraph / Haystack / LlamaIndex** | Headless agent skeleton libs (not a product UI) |
| E | **Self-host Onyx (CE vs EE)** | Org-doc connector adjunct only |
| F | **Self-host RAGFlow** | Hard-PDF / layout RAG sidecar |
| G | **Self-host Hermes** | Operator/internal sidecar only |
| H | **Self-host Dify / AnythingLLM / full platforms** | Why-not / when |
| I | **Buy SaaS** (managed chat/RAG/BI copilots) | Only if it beats self-host under Core constraints |

Landscape sweep (2026-09-22, sibling deep-research): credible self-host OSS exists in three layers — chat UIs (LibreChat, Open WebUI, AnythingLLM), connector platforms (Onyx, RAGFlow, Dify), frameworks (LangGraph, Haystack, LlamaIndex). No “none credible” exit. SaaS peers (Hex, ThoughtSpot Sage, Snowflake Cortex, Databricks Genie, managed enterprise search) fail the ADR-003 + Core ACL SoT test unless they only front Core tools — rare; none researched beat self-host for v1 packaging.

## Criteria (weighted per Step 2)

| Criterion | Weight | Why this weight |
|---|---|---|
| Total cost of ownership | M | Lean team; EE licenses and multi-service stacks burn cash fast |
| Time to value | M | Walking skeleton matters; Phase B still gated on G8 — don't over-buy UI early |
| Control & customizability | **H** | Must shape to Core MCP/OpenAPI + show query; platforms that reshape the job lose |
| Maintenance burden & bus factor | M | Inherit OSS bus factor OK if shell is commodity; don't inherit data-plane bus factor |
| Hosting & operational overhead | **H** | ADR-003 one VM / Coolify; heavy OpenSearch stacks fight the packaging story |
| Security, compliance & data surface | **H** | Metric ACL + allowlist stay in Core; dual-ACL and SaaS data exfil are deal-breakers |
| Integration fit & lock-in | **H** | Embed beside Core IaC; never replace semantics/`semantics_ref` |
| Reliability & ecosystem health | M | Need active MIT/Apache projects; license walls score as health risk |
| Strategic differentiation | **H** | Differentiated IP = Core modeling + ACL; chat chrome is commodity |
| Scalability headroom | L | Per-customer VM, not shared multi-tenant warehouse |
| **Core SoT / dual-plane risk** (capability-specific) | **H** | Does this invent a second semantic or ACL plane? |

## The circumstantial interview

Answers derived from operator framing + research consensus + Core PRD/README (not a live Q&A — vectors already settled for this run).

| # | Question | Answer |
|---|---|---|
| 1 | Budget & runway | Prefer zero/low recurring license for default path; EE only when a deal requires org-doc permission sync. No budgeted LangGenius/Dify commercial auth assumed. |
| 2 | Team | Small OS team; ops appetite for Coolify compose on Hetzner, not a second platform SRE load. Skills exist for Python/TS agent glue + IaC; not for forking enterprise RAG platforms. |
| 3 | Timeline | Headless Core walking skeleton first (PRD step 6 = modeling API/CLI). Customer chat shell is adjacent, not blocking G8. Ship thin proof before heavy UI. |
| 4 | Existing stack | Core: manifest, ACL, MetricFlow, Coolify, one VM/customer. Deprecated `narrowstack-core-app`. Chat must call Core — not re-ingest marts as vectors. |
| 5 | Self-hosting capacity | **Real.** Self-host OSS is the default posture (ADR-003). Buy SaaS only if it clearly wins on ops *and* keeps ACL in Core — bar not cleared by researched SaaS. |
| 6 | Scale & growth curve | Low concurrent chat today; growth = more VMs, not one mega-tenant. Light–medium compose footprint required. |
| 7 | Compliance / security / data | Allowlist default-deny; three-layer metric ACL; identity passthrough to Core tools; secrets via env names. Customer data stays on customer VM. |
| 8 | Differentiation | Commodity: chat UI, file upload RAG, provider pickers. Differentiated: governed metric answers + audit/query shown. Build the latter; self-host the former. |
| 9 | Risk & lock-in | High cost of wrong SoT (dual ACL). Medium cost of wrong UI (swap LibreChat ↔ OWUI). Low cost of framework choice if tools are Core-shaped. |
| 10 | Prior form | In-repo chat GUI deprecated for v1. Hermes used as pattern reference. Research already ranked LibreChat + LangGraph ahead of platforms. |

Vectors skipped this run: exact dollar EE quotes and hands-on RAM benchmarks (call out as open operator decisions). Prior form of building a full chat GUI counted as evidence against rebuilding chrome.

## Research

Claims below cite sibling research as-of **2026-09-22** (`report.md` bibliography [1]–[30]) unless tagged `[assumption]`.

### A — Build custom thin chat + Core tools

- **Scope:** Minimal authenticated chat (or even CLI+API first) + Core MCP/OpenAPI that wraps allowlisted MetricFlow queries; optional later UI.  
- **Effort:** With AI-assisted coding, a walking skeleton (one question / one grant / query shown) is **days–low weeks**, not a quarter — PRD already defines the headless pass check. Full multi-user SSO chat chrome is the expensive part `[assumption]` relative to adopting LibreChat.  
- **Comparable:** Deprecated `narrowstack-core-app` path — don't resurrect a full GUI in-core for v1 (PRD Won't).  
- **Fit:** Max control; max ownership of auth UX; slowest path to “feels like ChatGPT” polish.

### B — LibreChat (self-host)

- **Health:** MIT; ~45k stars; very active; Agents/Skills/MCP; multi-provider `[report.md]` [11].  
- **Cost:** Self-host compose; no SaaS floor; ops = medium (app + optional RAG API sidecar) [11][14].  
- **Integration:** First-class MCP; SAML **or** OIDC (not both at once) [12][13]. File RAG is upload-centric — not Core SoT [14].  
- **Loved:** Multi-provider + agents/MCP; Docker workable. **Complained:** MCP via YAML not GUI; setup heavier than OWUI [`last30days-community.md`].

### C — Open WebUI (self-host)

- **Health:** Custom license; ~153k stars; very active; CE claims SSO/OIDC/LDAP/SCIM/RBAC [15].  
- **Cost:** Self-host light–medium; branding/EE wall ~50+ users / white-label [28][5].  
- **Integration:** Tools/Pipelines + stronger built-in KB than LibreChat; weaker source-permission inheritance than Onyx EE [16][17].  
- **Loved:** Easier setup / solid UX. **Complained:** License diligence for packaging/resale; not a MetricFlow substitute.

### D — LangGraph / Haystack / LlamaIndex (adopt-OSS libs)

- **Health:** MIT / Apache-2.0; maintained vendor ecosystems [20][23][24].  
- **Cost:** Eng time only; no UI license.  
- **Integration:** Best match for headless Core — tools = allowlisted queries; optional loaders for docs adjunct. Auth/enterprise you build.  
- **Loved:** Control, composability. **Complained:** You ship the product surface yourself [27].

### E — Onyx CE vs EE (self-host adjunct)

- **Health:** MIT CE; EE for SSO/SCIM/doc RBAC / permission mirroring [3][4].  
- **Cost:** CE free; EE commercial; Standard ops = OpenSearch + workers + Redis + MinIO (heavy) [3][28]. Lite &lt;1GB chat-only drops RAG depth.  
- **Integration:** Best org connectors; **dual-ACL risk** if used as metric SoT.  
- **When:** Customer needs Slack/Drive/Confluence search *and* budgets EE if perm sync required.

### F — RAGFlow (self-host sidecar)

- **Health:** Apache-2.0; ~91k stars; API-first RAG brain [9][10].  
- **Cost:** ~4 CPU / 16GB floor — VM budget pressure [9].  
- **Integration:** Retrieve tool for hard PDFs/wikis; not chat chrome. Compose behind LibreChat/OWUI is community-normal [`last30days`].

### G — Hermes (operator sidecar)

- **Health:** MIT; personal agent (skills, MCP, BYO model, gateways); enterprise SSO/ACL/RAG weak [1][2]. Star metrics unreliable.  
- **Verdict shape:** Pattern reference + optional NS-staff sidecar — **not** customer product.

### H — Dify / AnythingLLM / AgentSwarms / full platforms

- **Dify:** Apache+ multi-tenant SaaS bar; EE for SSO/multi-workspace — avoid default packaging [6][8][30].  
- **AnythingLLM:** MIT, light; Simple SSO only — prototype, not enterprise backbone [18][19].  
- **AgentSwarms:** Overlaps Core data plane (warehouse connectors + masking) — avoid [26].  
- **When Dify might win:** Internal visual workflow builder with commercial license + no multi-tenant Cloud packaging.

### I — Buy SaaS

Under Core constraints (per-customer VM, ACL in Core, any model provider, no parallel semantics):

| SaaS class | Why it usually loses |
|---|---|
| Managed ChatGPT-clone hosts | Data leaves customer VM; weak Core tool/ACL binding |
| Enterprise search SaaS (Glean-class) | Doc plane only; expensive; still need Core for metrics |
| Warehouse copilots (Cortex/Genie/Hex AI) | Compete with / bypass MetricFlow allowlist unless heavily constrained |
| Managed Onyx/Dify cloud | Same dual-plane + tenancy issues; worse residency story |

**None researched beat self-host for v1.** Revisit if Cloud offers a hosted chat SKU with contractual residency + Core-only tools and still cheaper than LibreChat-on-VM.

## Scored matrix

Scores 1–5 (higher = better for Narrowstack). Columns are the live decision forks (adjuncts and avoid-list summarized below). Citations: sibling research 2026-09-22.

| Criterion (weight) | A Build thin custom | B LibreChat SH | C Open WebUI SH | D LangGraph/… libs | E Onyx adjunct | F RAGFlow sidecar |
|---|---|---|---|---|---|---|
| TCO (M) | 4 — eng time, no license | 4 — free MIT, medium compose | 3 — free until branding/EE | 5 — libs only | 2 — EE + heavy stack | 3 — free but RAM-heavy |
| Time to value (M) | 3 — UI polish slow | 5 — chat+MCP ready | 5 — fastest install | 4 — skeleton fast, no UI | 2 — ops ramp | 3 — API wire-up |
| Control (H) | 5 — full | 4 — MCP-shaped | 3 — platform opinions | 5 — full agent graph | 2 — owns doc ACL | 4 — API retrieve only |
| Maintenance (M) | 3 — we own UI bugs | 4 — upstream UI | 4 — upstream UI | 3 — we own glue | 2 — multi-service | 3 — dedicated RAG ops |
| Hosting ops (H) | 5 — minimal | 4 — medium | 4 — medium-light | 5 — process beside API | 1 — Standard heavy | 2 — 16GB class |
| Security/data (H) | 5 — Core ACL only | 4 — shell+Core ACL | 3 — license+KB ACL mix | 5 — Core ACL only | 2 — dual ACL unless disciplined | 4 — doc plane only |
| Integration/lock-in (H) | 5 — native | 5 — MCP→Core | 4 — tools→Core | 5 — tools=Core | 2 — SoT temptation | 4 — sidecar API |
| Reliability/ecosystem (M) | 3 — our SLA | 5 — MIT active | 3 — custom license risk | 5 — strong libs | 4 — active; EE gate | 4 — active Apache |
| Differentiation (H) | 4 — own surface; risk reinventing chrome | 5 — commodity UI, build Core tools | 4 — same | 5 — framework behind Core IP | 1 — platform IP elsewhere | 3 — doc quality SKU |
| Scale headroom (L) | 4 — enough | 4 — per-VM | 4 — per-VM | 4 — enough | 3 — more services | 3 — RAM bound |
| **Core SoT risk↓ (H)** | 5 — none | 5 — if metrics stay in tools | 4 — KB misuse risk | 5 — none | 1 — high if mis-scoped | 4 — docs only |
| **Weighted sanity (≈)** | **~4.5** | **~4.5** | **~3.7** | **~4.7** | **~2.1** | **~3.4** |

**Hermes (G):** high lightness/models; enterprise/RAG fail → operator-only (not scored as customer path).  
**Dify / AnythingLLM / AgentSwarms (H):** fail Integration + Core SoT and/or license — avoid defaults.  
**SaaS (I):** fail Hosting residency + Integration under ADR-003 — no score ≥ self-host for v1.

**Swing criteria (what actually decided this):** (1) **Integration fit / Core SoT**, (2) **Security — single ACL plane for metrics**, (3) **Hosting overhead on one VM**. Totals are sanity only — LibreChat and build-thin tie on score for different layers; the hybrid assigns each layer its winner.

## Verdict

**Hybrid — Self-Host OSS chat shell + Build Core tools + Adopt-OSS headless libs; adjunct self-host only on demand.**

1. **Build** the differentiated piece: Core MCP/OpenAPI tools enforcing allowlist + metric ACL, query-shown answers, identity passthrough.  
2. **Self-host LibreChat** as default customer/operator chat chrome (MIT, MCP, multi-provider). **Open WebUI** alternate after license diligence if CE SSO/SCIM/RBAC is the buyer gate.  
3. **Adopt-OSS LangGraph** (Haystack/LlamaIndex OK) for the **headless walking skeleton** aligned to PRD step 6 — before or without shipping full chat UI.  
4. **Self-host Onyx** (budget EE if permission sync matters) and/or **RAGFlow** only when unstructured org knowledge is in-scope SKU — never as MetricFlow substitute.  
5. **Hermes** = pattern + optional internal operator sidecar.  
6. **Do not Buy SaaS** for v1 packaging; **do not** default Dify / AnythingLLM backbone / AgentSwarms.

- **Confidence:** **high** on hybrid shape and avoid-list (research + PRD aligned); **med** on LibreChat vs OWUI final pick (license + SSO weight open); **med** on when Onyx/RAGFlow ROI clears ops cost.  
- **Risks accepted:** LibreChat's upload RAG and weaker SCIM story vs OWUI; OWUI's custom license if chosen; OSS bus factor on the shell; temptation to over-index docs into the chat KB; EE cost if org-search deals appear. Losing option's best case: full custom UI for perfect brand control — deferred until chrome is proven insufficient.  
- **Reassessment trigger (any one):** (a) Open WebUI license review blocks NS packaging/resale; (b) paying customer requires SCIM/RBAC beyond LibreChat's SAML/OIDC; (c) org-doc search is sold and dual-plane ops is staffed; (d) Coolify VM RAM cannot host shell + warehouse co-resident; (e) Phase B opens and MCP identity passthrough fails security review; (f) **2027-03-01** calendar re-look if none of the above.

**Verification:** Independent re-read of Steps 1–4 (criteria weights + interview + research matrix, ignoring session preference) yields the same **Hybrid** assignment: build Core tools, self-host thin shell, frameworks for skeleton, adjuncts conditional, SaaS/Dify/AnythingLLM/AgentSwarms out. **Match** — no reconciliation needed. LibreChat vs OWUI remains a **sub-decision** under the hybrid, not a Build vs Buy flip.

## Recommended walking skeleton (Core)

Aligned to PRD “one question, one grant”:

1. **Core tools first** — MCP or OpenAPI wrapping allowlisted MetricFlow / modeling API; deny unlisted; return number + query text.  
2. **Headless agent** — LangGraph (or Haystack) calling those tools; prove PRD step 6 without a product GUI.  
3. **Optional shell** — LibreChat on the same VM registered to Core MCP; SAML/OIDC to customer IdP when multi-user.  
4. **Docs later** — RAGFlow retrieve tool and/or Onyx plane only after metric path is boringly correct.

## Explicit non-goals / avoid

- Restoring `narrowstack-core-app` as v1 product surface.  
- Vector RAG as MetricFlow / allowlist substitute.  
- Onyx/Dify/AgentSwarms/DataFoundry as semantic or metric ACL SoT.  
- Hermes as customer multi-user chat.  
- Dify as default (multi-tenant license bar).  
- AnythingLLM as SSO/RAG backbone.  
- SaaS copilots that bypass Core ACL or leave customer VM without a residency win.  
- Shipping heavy Standard Onyx + RAGFlow + warehouse on day-one RAM budget.

## Operator decisions still needed

1. First chat surface: **operator-only** vs **customer end-user** (sets SSO/SCIM weight → LibreChat vs OWUI).  
2. v1 answer scope: **metrics only** vs metrics + org docs in same UI.  
3. Accept **Onyx EE** when permission-aware connectors are sold?  
4. Single-VM RAM budget: can RAGFlow/Onyx Standard coexist with `warehouse.mode: local`?  
5. Will NS ever offer **multi-tenant hosted chat**? (Dify bar; OWUI branding.)  
6. Identity: one OIDC across Coolify, Core API, chat?  
7. MCP vs OpenAPI for Core tools (security review).  
8. Hermes as **internal** NS staff sidecar — yes/no.  
9. Legal: Open WebUI license text for packaging/resale red lines.

---

**Not decided by Tucker yet.** Recommend and stop — do not stamp production docs until operator confirms.
