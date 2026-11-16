# Build vs buy — chat surface that honors per-user ACL and row scoping

_As of 2026-09-22. Re-run Step 3–5 if the reassessment trigger below fires,
or if a candidate's pricing/license/health changes materially._

**Narrows:** [`build-vs-buy-chat-with-modeled-data.md`](./build-vs-buy-chat-with-modeled-data.md) (same day). That run settled the hybrid shape (build Core tools, self-host a thin shell) and left the shell pick open: LibreChat by default, Open WebUI as the alternate "if SSO/SCIM/RBAC outweigh license diligence." This run answers that sub-decision now that per-user ACL is a v1 requirement.

**Scope note:** the chat surface is **not** on the initial execution path. Core ships first; this verdict governs the edge stub in [`docs/architecture/core-runtime/edge-stubs.md`](../../../architecture/core-runtime/edge-stubs.md).

## The job

Give each customer user a chat surface that only shows the models, tools, and knowledge their group is granted, and that carries a verifiable per-user identity to Core, so Core's API (the front door and bouncer) decides every metric answer, including row-level scoping.

## Candidates

- **Build custom:** a thin chat UI we own (for example an OSS chat component kit plus our own OIDC, SCIM, and group RBAC), with tools bound to Core's API/MCP.
- **Self-host OSS: Open WebUI.** The operator's hypothesis.
- **Self-host OSS: LibreChat.** The prior run's default.
- **Self-host OSS landscape sweep:** any other credible option that turns up (AnythingLLM, LobeHub, Onyx, Hugging Face chat-ui, and others). Results are in Research below.

## Criteria (weighted per Step 2)

Written before candidate research started, 2026-09-22.

| Criterion | Weight | Why this weight |
|---|---|---|
| Total cost of ownership | M | ≤50 users per tenant; prefer no recurring license on the default path |
| Time to value | L | Edge is off the initial execution path; no deadline pressure |
| Control & customizability | M | Must bind tools to Core and pass identity; branding work deferred |
| Maintenance burden & bus factor | M | Commodity chrome; we inherit upstream's cadence either way |
| Hosting & operational overhead | **H** | One VM per customer on Coolify; Core must stay lean, edge must not crowd it |
| Security, compliance & data surface | M | General posture (advisory history, audit, secrets); the ACL specifics are split out below |
| Integration fit & lock-in | **H** | OIDC sign-in, OpenAI-compatible model routing, MCP/OpenAPI tools to Core; swapping the shell later must stay cheap |
| Reliability & ecosystem health | M | License or governance changes count here |
| Strategic differentiation | L | Chat chrome is commodity; Core's governed answers are the product |
| Scalability headroom | L | ≤50 users per tenant over 12–24 months |
| **Identity propagation to Core** (capability-specific) | **H** | A per-user credential Core can verify (IdP-signed token or Core-issued token) must reach Core tools at discovery and call time; spoofable headers don't count |
| **Built-in surface ACL** (capability-specific) | **H** | v1 needs per-group model/tool access, per-group knowledge access, and SCIM provisioning without us building them |
| **License & white-label optionality** (capability-specific) | M | Branding deferred ("probably later"); at ≤50 users some branding clauses stop binding |

## The circumstantial interview

| # | Question | Answer |
|---|---|---|
| 1 | Budget & runway | Carried over from the prior run: zero or low recurring license on the default path; an enterprise license only when a deal requires it. |
| 2 | Team | Carried over: small team, happy running Coolify compose; not staffed to operate a second platform. |
| 3 | Timeline | **Changed.** Core (API/CLI/MCP + pipelines) ships first. The chat surface is a documented stub, off the initial execution path (Tucker, 2026-09-22). |
| 4 | Existing stack | **Changed.** Core's API/CLI/MCP is the front door and bouncer: it enforces ACLs and row-level scoping against the system. Access setup is an optional instance-setup step; if skipped, the API runs open, strongly advised against in setup and docs (Tucker, 2026-09-22). LiteLLM for models, pgvector for knowledge (both stubs). |
| 5 | Self-hosting capacity | Carried over: real. Self-host is the default posture (ADR-003). |
| 6 | Scale & growth curve | **≤50 chat users per tenant** over 12–24 months (Tucker, 2026-09-22). |
| 7 | Compliance / security / data constraints | **v1 requires all four:** row-level metric scoping, per-group model/tool access, per-group doc/knowledge access, SCIM provisioning (Tucker, 2026-09-22). Row scoping is enforced by Core, not the UI. |
| 8 | Differentiation | Carried over: chat chrome is commodity; governed answers are the product. |
| 9 | Risk & lock-in tolerance | Carried over, plus: white-label is **deferred, "probably later"** (Tucker, 2026-09-22), so it's a reassessment trigger, not a v1 criterion. |
| 10 | Prior form | Carried over: the in-repo chat GUI was deprecated; the prior run picked LibreChat as default and Open WebUI as alternate pending license and SSO weight. |

Vectors skipped this run, and why: identity provider choice. Tucker wants Core to stay lean and IdP-agnostic: Core validates credentials and does not run an IdP. The candidates are scored on whether they can forward a verifiable credential, not on which IdP they pair with.

## Research

Researched 2026-09-22, after the weighting above was committed. All claims are as of 2026-09-22 unless dated otherwise; `[assumption]` marks anything not confirmed.

**Governing standard.** The MCP authorization spec (2025-06-18) sets the bar for "a credential Core can verify":

- MCP servers **MUST** publish OAuth 2.0 Protected Resource Metadata (RFC 9728).
- They **MUST** "validate that access tokens were issued specifically for them as the intended audience" (RFC 8707).
- They "**MUST NOT** accept or transit any other tokens". Token passthrough is explicitly forbidden.
- The client **MUST** send `Authorization` on every HTTP request.

[modelcontextprotocol.io/specification/2025-06-18/basic/authorization](https://modelcontextprotocol.io/specification/2025-06-18/basic/authorization)

### Build custom

- **Shape:** an OSS chat UI kit (assistant-ui MIT, or CopilotKit MIT), plus OIDC (Auth.js ISC or oauth4webapi MIT), a SCIM 2.0 server library (SCIMMY, 71★, small), group RBAC tables, the MCP TypeScript SDK with per-request bearer headers, and streaming to LiteLLM. All components are permissive and active, as of 2026-09-22.
- **Effort:** roughly **30–45 dev-days** (6–9 weeks, one AI-assisted engineer) to reach all six v1 requirements, excluding file-upload RAG. SCIM (4–6d: filter parsing, PATCH semantics, re-sync dedup) and the admin UI (3–4d, most likely to overrun) are the risk items. Ongoing: about 0.5–1 day per new customer IdP, plus 1–2 days per quarter for upgrades `[assumption: bottom-up estimate]`.
- **Loved:** no upstream license or roadmap risk; zero white-label risk; MCP SDK bearer forwarding is a documented pattern ([typescript-sdk client docs](https://github.com/modelcontextprotocol/typescript-sdk/blob/main/docs/client.md)).
- **Complained:** we'd own SCIM edge cases against real IdPs; building doesn't exempt us from the MCP and identity CVE class every comparable project hit in 2025–2026; admin UI scope creep.

### Open WebUI

- **Health:** v0.11.4 released 2026-09-21; multiple releases per week through 2025–2026; 152.8k★, 22.4k forks. Led by one company (Open WebUI Inc.) `[assumption: no foundation]`. Sources: [releases](https://github.com/open-webui/open-webui/releases), [CHANGELOG](https://github.com/open-webui/open-webui/blob/main/CHANGELOG.md).
- **License:** BSD-3-Clause plus a Section 4 branding clause. GitHub reports it as NOASSERTION. Branding may be removed only if end users "do not exceed fifty (50) within any rolling thirty (30) day period", or with written permission, or with an enterprise license ([LICENSE](https://github.com/open-webui/open-webui/blob/main/LICENSE)). Our ≤50 ceiling sits exactly on that threshold, with zero headroom.
- **Per-group model/tool access: native.** Groups grant read or write `access_control` on Models, Knowledge, Tools, and Prompts. Grants are additive, with no deny. Workspace permissions are set per group ([RBAC groups](https://docs.openwebui.com/features/authentication-access/rbac/groups/), [permissions](https://docs.openwebui.com/features/authentication-access/rbac/permissions/)).
- **Per-group knowledge access: native, enforced in Open WebUI's backend.** CVE-2026-44560 ([GHSA-h36f-rqpx-j5wx](https://github.com/open-webui/open-webui/security/advisories/GHSA-h36f-rqpx-j5wx), CVSS 6.5, 2026-05-05) bypassed retrieval ACL in versions ≤0.8.12. Fixed in ≥0.9.0.
- **SCIM 2.0: native, in the open-source tree.** Added v0.6.19 (2025-08-09) and labeled "experimental" at introduction. Users and Groups endpoints at `/api/v1/scim/v2/`; configured with `SCIM_ENABLED` and `SCIM_TOKEN`. Hardened through 2026 (Entra group filtering, timing-safe token compare) ([SCIM docs](https://docs.openwebui.com/features/authentication-access/auth/scim/)).
- **Identity to Core: native via MCP.** Native MCP (streamable HTTP) since v0.6.31 (2025-09-25). With OAuth 2.1 auth (dynamic client registration or static client), each user completes the flow once, and tokens are stored per account. Open WebUI reads `resource` from Core's RFC 9728 metadata and sends it on authorize, token, and refresh, so tokens are **audience-bound to Core** ([MCP docs](https://github.com/open-webui/docs/blob/main/docs/features/extensibility/mcp.mdx)). Caveats:
  - OAuth 2.1 MCP tools can't be always-on default tools, because consent needs a browser redirect.
  - That the token rides discovery as well as calls is `[assumption]` (one authenticated session per user); verify it.
  - The OpenAPI tool-server path is **partial**: static shared bearer or Open WebUI's own session cookie, not an IdP token. So Core must be wired as MCP, not OpenAPI.
  - `ENABLE_FORWARD_USER_INFO_HEADERS` sends unsigned headers: fine for LiteLLM budgets, not for ACL.
- **OIDC:** native generic OIDC, with role and group claim mapping (`ENABLE_OAUTH_ROLE_MANAGEMENT`, `ENABLE_OAUTH_GROUP_MANAGEMENT`) ([SSO docs](https://docs.openwebui.com/features/authentication-access/auth/sso/)).
- **Footprint:** a single container. `DATABASE_URL` takes Postgres; `VECTOR_DB=pgvector` is supported. Redis is required only with more than one worker. Baseline 2–4 GB RAM without local models. A slim image is about 175 MB (v0.11.4). Coolify one-click template: [open-webui.yaml](https://github.com/coollabsio/coolify/blob/main/templates/compose/open-webui.yaml).
- **Security history, 2025–2026:**
  - CVE-2025-64496: SSE code injection via Direct Connections, CVSS 7.3, fixed 0.6.35.
  - CVE-2025-64495: stored XSS.
  - CVE-2025-63681: task-ownership bug, low.
  - CVE-2026-44560: RAG ACL bypass, above.
  - No advisory found in the SCIM or MCP-OAuth paths.
  - Public [vendor dispositions](https://docs.openwebui.com/security/vendor-dispositions/cve-2025-15603/) page.
- **Loved:** easiest install and UX; SCIM plus groups without an enterprise tier; fast fixes.
- **Complained:** docs lag features; RAM heavy on small boxes; MCP identity-header forwarding confused users until v0.9.6 ([Discussion #21184](https://github.com/open-webui/open-webui/discussions/21184)).

### LibreChat

Gap-fill only. The facts already gathered on 2026-09-22 were reused rather than re-researched, per the operator's cancel.

- **Health:** MIT; adopted by ClickHouse on 2025-11-04 and still MIT ([ClickHouse blog](https://clickhouse.com/blog/librechat-open-source-agentic-data-stack)); 44.7k★; active daily.
- **Per-group model/tool access: native.** Admin-panel config overrides per role or group since v0.8.5 ([admin panel](https://www.librechat.ai/docs/features/admin_panel)).
- **Knowledge access: native, resource-level.** ACLs on agents, prompts, MCP servers, files, and projects, at viewer, editor, or manage level. Files mostly inherit from their agent ([access control](https://www.librechat.ai/docs/features/access_control)).
- **SCIM: absent.** [#9720](https://github.com/danny-avila/LibreChat/issues/9720) has been open since 2025-09-19. Groups come from IdP claims at login, so deprovisioning waits for the next login.
- **Identity to Core: passthrough.** `{{LIBRECHAT_OPENID_ACCESS_TOKEN}}` forwards the user's **login** access token, whose audience is LibreChat's client, not Core. It works only in YAML-defined servers ([mcp_servers](https://www.librechat.ai/docs/configuration/librechat_yaml/object_structure/mcp_servers)). Accepting it would make Core take tokens not issued for it, which the MCP spec forbids. The `{{LIBRECHAT_USER_*}}` placeholders are headers.
- **Footprint:** MongoDB plus Meilisearch, optionally rag_api with its own pgvector, plus a new admin-panel container.
- **Security:** 29 GitHub advisories, 28 of them between 2025-08 and 2026-06. Three are critical: CVE-2025-69222 SSRF, CVE-2026-22252 MCP stdio RCE, and CVE-2026-32625 secrets exfiltration via MCP. Two are MCP OAuth token-theft bugs ([advisories](https://github.com/danny-avila/LibreChat/security/advisories)).

### Self-host OSS landscape sweep

| Candidate | License | Fails on | Source |
|---|---|---|---|
| Onyx (ex-Danswer) | MIT outside `ee/`; groups, document ACL, SCIM, and white-label are **Enterprise-only** | No-license default path; heaviest stack (Postgres + Vespa + Redis + workers); OAuth-token passthrough to MCP, with a critical cross-user token-leak CVE-2026-71424 | [access controls](https://docs.onyx.app/security/architecture/access_controls), [SCIM](https://docs.onyx.app/deployment/authentication/scim) |
| AnythingLLM | MIT | No native OIDC (header-based SIMPLE_SSO), no SCIM, no groups; 25 advisories including critical RCE | [#2934](https://github.com/Mintplex-Labs/anything-llm/issues/2934) |
| LobeHub (ex-LobeChat) | Community license (derivatives need a commercial license) | No documented RBAC or SCIM; forgeable auth-header CVE-2026-39411; mid-2026 repositioning | [LICENSE](https://github.com/lobehub/lobe-chat/blob/main/LICENSE) |
| Hugging Face chat-ui | Apache-2.0 | No groups, collection ACL, or SCIM; identity tied to HF org roles | [docs](https://huggingface.co/docs/chat-ui/index) |
| big-AGI | MIT | No SSO, RBAC, or SCIM ("email the maintainer") | [README](https://github.com/enricoros/big-AGI) |
| Chainlit | Apache-2.0 | A framework, not a product: every ACL feature is ours to build; two MCP-transport CVEs (Aug 2026); per-user MCP headers limited ([#2530](https://github.com/Chainlit/chainlit/issues/2530)) | [docs](https://docs.chainlit.io/authentication/overview) |

Credible self-host OSS exists: Open WebUI and LibreChat. The rest either fail two or more musts, or reduce to "build custom on a framework."

## Scored matrix

Scores run 1–5 (higher is better for Narrowstack). Weights are H=3, M=2, L=1, used for the sanity total only. Onyx is shown as the strongest sweep entrant.

| Criterion (weight) | Build custom | Open WebUI | LibreChat | Onyx |
|---|---|---|---|---|
| TCO (M) | 2 — 30–45 dev-days + per-IdP upkeep | 4 — free; enterprise only if >50 users and white-label | 4 — free (MIT) | 1 — EE seats required for the v1 musts |
| Time to value (L) | 2 — weeks | 5 — one container | 4 — heavier setup, YAML MCP | 2 — multi-service ramp |
| Control & customizability (M) | 5 — all ours | 3 — platform opinions, branding clause | 4 — MIT, config-driven | 2 — EE-gated features |
| Maintenance & bus factor (M) | 2 — we own SCIM/OIDC quirks | 3 — one company, very fast release churn | 3 — ClickHouse-backed, busy advisory stream | 3 — YC-backed company |
| Hosting & ops overhead (H) | 4 — one app + Postgres | 4 — one container + Postgres (Redis only if multi-worker) | 3 — Mongo + Meili (+ rag_api + pgvector) | 1 — Vespa + Redis + workers |
| Security, compliance & data (M) | 3 — no history, same bug class | 3 — several 2025–26 CVEs, fixed fast | 2 — 29 advisories, 3 critical, MCP token theft | 3 — few advisories, one critical in MCP tokens |
| Integration fit & lock-in (H) | 5 — built to Core's contract | 5 — MCP OAuth 2.1 + OpenAI-compatible + OIDC groups | 4 — MCP + OpenAI-compatible; token placeholders YAML-only | 3 — LiteLLM native; dual-ACL temptation |
| Reliability & ecosystem (M) | 3 — our SLA; SCIM lib thin | 4 — very active, largest community | 4 — active, MIT | 4 — active company |
| Strategic differentiation (L) | 3 — spends effort on commodity chrome | 4 — frees effort for Core | 4 — same | 2 — platform IP elsewhere |
| Scalability headroom (L) | 4 | 4 | 4 | 4 |
| **Identity propagation to Core (H)** | 5 — we implement RFC 8707/9728 | **5 — audience-bound per-user tokens (spec-conformant)** | **2 — login-token passthrough (spec-forbidden) or headers** | 2 — token passthrough |
| **Built-in surface ACL (H)** | 3 — all four musts to build | **5 — groups on models/tools/knowledge + SCIM in OSS** | **3 — strong group/resource ACL, no SCIM** | 2 — only with paid EE |
| License & white-label optionality (M) | 5 — none | 3 — branding clause; exemption at exactly ≤50 | 5 — MIT | 1 — white-label is EE |
| **Weighted total (sanity only)** | **3.70** | **4.07** | **3.41** | **2.22** |

**Swing criteria (what actually decided it):**

1. **Identity propagation to Core.** Open WebUI is the only turnkey candidate that obtains per-user tokens bound to Core's audience, as the MCP spec requires. LibreChat's route is passthrough of a token minted for LibreChat.
2. **Built-in surface ACL.** SCIM ships in Open WebUI's open-source tree. In LibreChat it's an open request a year old, so deprovisioning would lag until next login.
3. **Hosting overhead.** Open WebUI is one container plus Postgres; LibreChat needs Mongo and Meilisearch beside Core on the same VM.

## Verdict

**Self-Host OSS: Open WebUI** as the Variant A chat edge. This confirms the operator hypothesis. It wins on the two capability-specific must-haves (spec-conformant identity propagation and built-in group ACL with SCIM) and on single-VM weight. Self-hosting means inheriting Open WebUI Inc.'s bus factor and release cadence, and running and patching it ourselves.

- **Confidence:** high on fit (ACL and identity); **medium** on the long run, given license headroom at the 50-user line and upgrade churn.
- **Risks accepted:**
  - The branding exemption holds at ≤50 users in a rolling 30 days, with no headroom. A larger tenant keeps the branding or needs permission or an enterprise license.
  - Single-company governance and a very fast release cadence. Pin exact versions, upgrade deliberately, and watch advisories.
  - SCIM was introduced as "experimental".
  - OAuth 2.1 MCP tools need one-time per-user consent and can't be default always-on tools.
  - That the token rides discovery is an `[assumption]` to verify.
  - Open WebUI's own Knowledge feature is a document plane enforced by Open WebUI, not Core. Whether per-group docs live in Open WebUI Knowledge or in Core's `kb_*` tools is an open question (see the edge stub).
  - LibreChat's best case (MIT, no branding clause, excellent resource ACLs) is real. It loses on SCIM and token audience, not on quality.
- **Reassessment trigger (any one):**
  - (a) A tenant exceeds 50 users in a rolling 30 days **and** white-label is required.
  - (b) Open WebUI's license changes (check `LICENSE_HISTORY`).
  - (c) LibreChat ships SCIM (#9720) **and** audience-bound MCP OAuth.
  - (d) A critical advisory in Open WebUI's auth, SCIM, or MCP path stays unpatched for more than 30 days.
  - (e) Core's `oidc` mode security review finds Open WebUI's MCP discovery doesn't carry the token.
  - (f) 2027-03-01 calendar re-look, if nothing above fires.
- **Community pass skipped:** the call isn't close on the swing criteria, so an optional `last30days` pass on the finalists wouldn't change it.

**Verification:** fresh-context read of Steps 1–4 → _pending (verify pass running)._

_Not decided until Tucker stamps it. On a yes, the dated line goes into [`docs/architecture/core-runtime/edge-stubs.md`](../../../architecture/core-runtime/edge-stubs.md) with the reassessment trigger._
