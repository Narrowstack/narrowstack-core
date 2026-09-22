# Slot discovery — scheduler / LLM gateway / vector-KB

**Date:** 2026-09-22  
**Why:** Prior harness pack covered chat shells deeply; operator architecture now requires explicit picks for **pipeline runtime**, **model routing/spend**, and **ACL-aware IP/KB**. This is a targeted gap fill — not a full re-research of LibreChat/Onyx/etc.

**Inputs:** `gh api user/starred` (463 repos); awesome lists (`awesome-selfhosted`, `awesome-data-engineering`, `Awesome-LLMOps`, `Awesome-RAG`, `awesome-mcp-servers`, `awesome-harness-engineering`); GitHub peer metadata for LiteLLM/Portkey/Bifrost, Prefect/Dagster/Airflow/Mage/Kestra, Qdrant/Weaviate/Chroma/LanceDB/pgvector.

## What changed vs prior pack

| Slot | Prior pack | This discovery |
|---|---|---|
| Chat harness | LibreChat default; OWUI alternate | **Unchanged.** Stars skew Open WebUI + AnythingLLM (no LibreChat star) — bookmark gravity ≠ shortlist change. |
| Scheduler | Implicit green-check / CI | **New:** cron/green-check v1; **Prefect or Kestra** as first upgrade; Airflow out. |
| LLM gateway | Not decided | **Adopt LiteLLM.** Peers: Portkey gateway (MIT), Bifrost (Apache-2.0) — spike if LiteLLM sour. |
| Vector/KB | Onyx/RAGFlow adjunct only | **Default store = pgvector in Core Postgres.** Onyx/RAGFlow remain connector sidecars when sold. |
| MCP fabric | Core MCP implied | **Confirm:** one Core MCP (+ optional `mcpproxy-go` / `googleapis/mcp-toolbox` for non-Core sources only). |

## Stars signal (operator bookmarks)

**Support Core spine:** `dlt-hub/dlt`, `dbt-labs/dbt`, `dbt-labs/metricflow`, `dbt-labs/dbt-mcp`, `open-webui/open-webui`, `ollama/ollama`.

**Gaps vs proposed stack:** no stars for LiteLLM, LibreChat, LangGraph, Qdrant/pgvector, Dagster/Prefect/Airflow, Onyx/RAGFlow.

**Surprises:** `Kong/kong` (generic API/AI gateway), `activepieces/activepieces` (workflow + MCP) — edge glue, not Core SoT. Stars favor OWUI path; architecture still defaults LibreChat for MIT + MCP fit (OWUI remains alternate).

## Awesome / peer shortlists (self-host, L/M/H weight)

### Scheduler / pipeline runtime

| Option | License | Weight | Fit |
|---|---|---|---|
| **cron + green-check / CI** | n/a | L | **Default v1** — already Core deploy model; ADR-003 one-VM |
| **Prefect** | Apache-2.0 | M | Python-native upgrade for dlt/dbt observability |
| **Kestra** | Apache-2.0 | M | YAML + event/cron; co-equal upgrade if ops prefer UI |
| **Dagster** | Apache-2.0 | M–H | When asset lineage is a sold story |
| Airflow | Apache-2.0 | H | Avoid default on Coolify single VM |
| Mage / Windmill | Apache-2.0 / verify | M | Avoid unless team already invested |

### LLM gateway / spend

| Option | License | Weight | Fit |
|---|---|---|---|
| **LiteLLM** | verify SPDX | L–M | **Default** — OpenAI-compat, budgets, multi-provider; LibreChat/OWUI friendly |
| **Portkey gateway** | MIT | L–M | Strong peer if LiteLLM license/ops sour |
| **Bifrost** | Apache-2.0 | L–M | Credible LiteLLM-class peer (governance + MCP ecosystem) |
| Helicone / Langfuse | Apache-2.0 / MIT | L–M | Observability **beside** gateway, not instead |
| OmniRoute | MIT | M | Coding-agent skew; not Core packaging default |
| Kong | Apache-2.0 | M–H | Only if already ops-owned; not a spend-native LLM product |

### Vector / KB store (not metric SoT)

| Option | License | Weight | Fit |
|---|---|---|---|
| **pgvector** (same Postgres) | PostgreSQL | L | **Default** — `warehouse.mode: local` already has PG; ACL via Core principals |
| **Qdrant** | Apache-2.0 | M | Scale/hybrid search upgrade |
| Chroma | Apache-2.0 | L–M | Prototype only |
| Weaviate / Milvus | verify / Apache-2.0 | M–H | Avoid default (ops weight) |
| Onyx / RAGFlow | MIT+EE / Apache-2.0 | M–H | **Connector adjuncts** — never MetricFlow SoT |

### Unchanged from prior shortlist

| Slot | Keep | Explicit peers to reject as SoT |
|---|---|---|
| Ingestion | **dlt** | Airbyte default; Meltano only if Singer estate |
| Transforms | **dbt** | SQLMesh = watch peer, not swap |
| Metrics SoT | **MetricFlow** + Core ACL | Cube / Orionbelt / Kaelio ktx = sidecars only |
| Harness | LibreChat / OWUI / LangGraph / Hermes op | Dify / Flowise as product platforms |

### MCP fabric (awesome-mcp + LLMOps)

| Option | Fit |
|---|---|
| **Core MCP/OpenAPI** | Metrics + `kb_*` + ACL — only metrics SoT path |
| `smart-mcp-proxy/mcpproxy-go` | Optional aggregate/filter of MCP servers |
| `googleapis/mcp-toolbox` | Governed SQL tools for **non-Core** sources only |
| `modelcontextprotocol/servers` | Reference patterns, not tenant fabric |

## Avoid (awesome-list diligence)

| Avoid | Why |
|---|---|
| Dify / Flowise as Core packaging | Second app/KB platform |
| Onyx / RAGFlow as metric SoT | Dual-ACL |
| AGPL defaults (Khoj, Firecrawl, ToolJet) | Packaging friction |
| GPL data-plane (sling-cli, Typesense) | Copyleft unless legal accepts |
| Elasticsearch-heavy / Milvus early | Ops weight before KB scale proven |

## Architecture impact

Prior “thin shell → Core MCP” verdict **holds**. No new topology variants beyond A/B/C already in architecture doc. Slot peers (Kestra, Bifrost, SQLMesh, Cube) are **swap options inside slots**, not alternate system shapes.

1. Scheduler does not become a second warehouse.  
2. LiteLLM sits between harness and providers — not between harness and MetricFlow.  
3. Vector/KB is a **second knowledge plane** with its own ACL filter; metrics stay MetricFlow-only.

Full architecture package: [`docs/architecture/chat-with-modeled-data.md`](../../../architecture/chat-with-modeled-data.md).

## Open diligence (not blockers for prototype)

1. LiteLLM SPDX / commercial terms for NS packaging.  
2. Prefect vs Kestra vs pure cron on smallest Coolify VM class.  
3. Optional spike: Bifrost vs LiteLLM (governance + license).  
4. pgvector embedding provider choice (local vs via LiteLLM).  
5. Whether ADR-001 Hermes wording needs G-phase update (operator sidecar vs v0 runtime).
