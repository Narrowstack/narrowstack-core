# Shortlist & tiers — OSS agent/chat harnesses (2026-09-22)

Companion to `report.md` / `deep-research.md`. Community corroboration: `last30days-community.md`. Parent handoff: `executive-summary.md`. Core-weighted rubric totals (max 40).

| Rank | Candidate | Total | Tier | Wire to Core modeled layer |
|---:|---|---:|---|---|
| 1 | LibreChat | 34 | **Adopt** UI harness | MCP/OpenAPI tools → modeling API / MetricFlow; ACL stays in Core |
| 2 | LangGraph (+ thin API) | 33 | **Build-thin-on-top** | Agent graph tools = allowlisted queries; headless-first |
| 3 | LlamaIndex | 33 | **Build-thin-on-top** | Loaders for docs adjunct; metrics via custom tools not vectors |
| 4 | Haystack | 32 | **Build-thin-on-top** | Pipelines call Core; optional enterprise overlay later |
| 5 | Open WebUI | 31 | **Adopt** (license diligence) | Tools/Pipelines → Core; OWUI KB for docs only |
| 6 | Onyx CE/EE | 27–31 | **Adopt adjunct** / avoid as SoT | Org-doc connectors; never replace metric ACL |
| 7 | AnythingLLM | 28 | **Avoid** primary | Prototype workspaces only |
| 8 | RAGFlow | 27 | **Adopt** doc sidecar | Dataset sync for PDFs/wikis; API retrieve tool |
| 9 | Hermes Agent | 27 | **Reference / avoid** primary | Pattern: skills+MCP+BYO model; not multi-user RAG |
| 10 | DataFoundry | 24 | **Watch / spike** | Only if consumes Core semantics, not forks them |
| 11 | Dify | 21–24 | **Avoid** default | License SaaS bar + EE for SSO |
| 12 | AgentSwarms | 19 | **Avoid** | Overlaps Core data plane |

**Hermes identity:** NousResearch/hermes-agent (MIT) — confirmed.

**Default stack proposal:** LibreChat + Core MCP tools (+ LangGraph for headless skeleton). Add Onyx and/or RAGFlow only when unstructured org knowledge is in-scope.
