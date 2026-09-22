---
kind: architecture
slug: chat-with-modeled-data
date: 2026-09-22
verified: 2026-09-22
status: prototype
refs:
  - docs/product/prd.md
  - docs/plans/narrowstack-core-architecture-20260831.md
  - docs/product/research/oss-agent-harness-chat-data-20260922/executive-summary.md
  - docs/product/research/oss-agent-harness-chat-data-20260922/slot-discovery-20260922.md
---

# Chat with modeled data — architecture prototype

**Verdict:** Thin chat/agent shell → **Core MCP/OpenAPI** (MetricFlow + ACL SoT). **LiteLLM** for model routing/spend. **pgvector-in-Postgres** for IP/KB adjunct. **cron + green-check** for v1 pipeline runtime (Prefect or Kestra upgrade path). Chat chrome never owns warehouse, metrics, or ACL.

**Archify HTML:** [`chat-data-plane/`](./chat-data-plane/) (lean primary). Mermaid variants below for operator compare.

---

## Variant compare

| Variant | When | Harness | KB plane | Scheduler | VM weight |
|---|---|---|---|---|---|
| **A — Lean Core+LibreChat** | Default packaging | LibreChat (OWUI swap OK) | pgvector + Core `kb_*` tools | cron + green-check | L–M |
| **B — Core+Onyx dual-plane** | Org-doc SKU sold | LibreChat/OWUI | Onyx (± RAGFlow) + Core metrics tools | same as A | M–H |
| **C — Headless-first** | PRD walking skeleton / G8→B | LangGraph (or CLI) only | optional later | cron + green-check | L |

**Hermes:** operator/internal sidecar only (pattern + BYO model). Not customer UI. Aligns with research; ADR-001 wording still says Hermes v0 — **open operator revisit**.

---

## Core context: Variant A vs C (same spine)

**Yes — Core is the same thing whether or not a customer edge exists.** A and C are packaging profiles over one data plane, not two Cores.

| Layer | Shared Core (A and C) | A only (customer edge) | C only (integrator edge) |
|---|---|---|---|
| Ingest / transform | dlt → Postgres → dbt marts | — | — |
| Metrics SoT | MetricFlow + allowlist + three-layer ACL | — | — |
| Product surface | Modeling API + `ns-core` CLI (+ MCP when shipped) | LibreChat/OWUI → same API/MCP | LangGraph / LlamaIndex / Haystack / CLI → same API/MCP |
| Models / spend | LiteLLM (when any agent/chat on) | Harness base URL → LiteLLM | Agent SDK base URL → LiteLLM |
| IP / KB | pgvector + Core `kb_*` (optional) | Exposed as chat tools | Same tools if agent binds them |
| Pipelines | cron + green-check | — | — |

```mermaid
flowchart LR
  subgraph EDGE["Optional edge — swap freely"]
    A["A: LibreChat / OWUI"]
    C["C: LangGraph / CLI"]
  end

  subgraph CORE["One Core — identical"]
    API["Modeling API / MCP / ns-core"]
    ACL["ACL + allowlist"]
    MF["MetricFlow"]
    PG["Postgres + pgvector"]
    PIPE["dlt → dbt via cron/green-check"]
    LL["LiteLLM"]
  end

  A --> API
  C --> API
  A --> LL
  C --> LL
  API --> ACL --> MF --> PG
  PIPE --> PG
```

**Implication:** Prove PRD step 6 on C (headless). Turn on compose profile `chat-ui` for A without changing semantics, ACL, or MetricFlow. Do not fork Core for chat.

---

## Sequence — initial pipelines, then chat a metric

Same Core path for A and C. Edge differs only at the left: LibreChat vs LangGraph/`ns-core`.

### 1. Setup — provision + first green pipeline

```mermaid
sequenceDiagram
  actor Op as Operator
  participant Man as Instance manifest
  participant Sem as Semantics repo (pinned ref)
  participant Dep as Deploy / Coolify
  participant GC as green-check
  participant Cron as cron / systemd
  participant DLT as dlt
  participant PG as Postgres
  participant DBT as dbt
  participant MF as MetricFlow
  participant API as Modeling API

  Op->>Man: warehouse.mode, semantics_ref, principals, pipelines
  Op->>Dep: provision VM + compose (Postgres, API, LiteLLM…)
  Dep->>Sem: clone at semantics_ref
  Dep->>GC: allowlist + ACL + schema gates
  alt gate fail
    GC-->>Op: deploy blocked
  else gate pass
    GC-->>Dep: active-manifest.json
    Cron->>DLT: run enabled pipeline (e.g. source X)
    DLT->>PG: load raw_<source>
    Cron->>DBT: build staging → marts
    DBT->>PG: mart tables + durable entity keys
    DBT->>MF: refresh semantic artifacts
    Op->>API: smoke list_metrics / mf_query (principal token)
    API-->>Op: metric list + tie-out number (query shown)
  end
```

### 2. Chat — ask a specific metric (A or C)

```mermaid
sequenceDiagram
  actor U as Principal
  participant Edge as Edge (LibreChat OR LangGraph/CLI)
  participant LL as LiteLLM
  participant API as Core Modeling API / MCP
  participant ACL as Three-layer ACL
  participant MF as MetricFlow
  participant PG as Postgres marts

  U->>Edge: "What was revenue last week for entity E?"
  Edge->>LL: optional plan / tool choice (virtual key)
  LL-->>Edge: completion
  Edge->>API: list_metrics (Bearer principal)
  API->>ACL: filter by allowlist + grants + token
  ACL-->>Edge: [revenue, …] (denied names omitted)
  Edge->>API: mf_query(metric=revenue, grain=week, entity=E)
  API->>ACL: enforce principal on metric + entity scope
  alt denied
    ACL-->>Edge: 403 (no value in body)
    Edge->>LL: explain denial
    LL-->>U: cannot answer (no leak)
  else allowed
    ACL->>MF: compile
    MF->>PG: execute
    PG-->>MF: row
    MF-->>API: value + SQL
    API-->>Edge: {value, sql, metric}
    Edge->>LL: synthesize with query shown
    LL-->>Edge: natural-language answer
    Edge-->>U: number + query shown (PRD step 6)
  end
```

Invariant: warehouse DSN never leaves Core. Edge and LiteLLM see tools/tokens only.

---

## Target repo layout (Core + optional edge)

Maps onto today’s shell (`manifest/`, `semantics/`, `compose/`, `deploy/`, `acl/`) plus chat/agent profiles. Private tenant code stays in the pinned semantics repo.

```
narrowstack-core/                    # OSS shell (this repo)
├── manifest/
│   ├── schema.json
│   └── examples/
│       ├── example-local-warehouse.yaml
│       └── example-external-warehouse.yaml
├── acl/                             # framework + sensitivity defaults
├── semantics/                       # in-repo TEMPLATES only (not tenant IP)
│   ├── dlt_pipelines/
│   ├── dbt_project/
│   ├── allowlist/
│   └── acl/
├── compose/
│   ├── local-warehouse/             # Postgres (+ pgvector), base Core
│   ├── external-warehouse/
│   ├── modeling-api/                # Modeling API (+ MCP when shipped)
│   ├── litellm/                     # model route + spend (profile)
│   └── chat-ui/                     # Variant A overlay: LibreChat|OWUI
├── deploy/
│   ├── green-check.sh
│   ├── allowlist-gate.sh
│   ├── acl-apply.sh
│   └── smoke-query.sh
├── api/                             # Modeling API service (Phase B)
│   └── openapi/
├── mcp/                             # MCP server wrapping same API contract
├── examples/
│   └── headless-agent/              # Variant C: LangGraph walking skeleton
│       ├── graph.py                 # tools → Core MCP/OpenAPI
│       ├── eval_fixtures.yaml       # known question → known number
│       └── README.md
├── scripts/
│   ├── ns-core                      # CLI entry
│   └── clone-semantics.sh
└── docs/
    ├── architecture/chat-with-modeled-data.md
    └── features/modeling-api.md

# Separate private repo (pinned by manifest.semantics_ref)
tenant-semantics-<customer>/
├── deploy/manifest.yaml
├── dlt_pipelines/                   # real sources
├── dbt_project/                     # marts + entity keys
├── metrics/                         # MetricFlow defs
├── allowlist/internal.yaml
└── kb/                              # optional IP docs → pgvector ingest
```

**Customer boilerplate (ideal appliance):**

1. Copy `manifest/examples/example-local-warehouse.yaml` → set `semantics_ref`, principals, pipeline enable flags.  
2. Fork semantics template → private repo; one source, one mart, one metric.  
3. Enable compose profiles: `local-warehouse` + `modeling-api` (+ `litellm` when agents on).  
4. Deploy → green-check → cron runs dlt/dbt.  
5. **C:** run `examples/headless-agent` (or `ns-core` query) for PRD step 6.  
6. **A:** enable `chat-ui` profile; point harness MCP at Core and OpenAI base URL at LiteLLM.  

Same Core steps 1–4 for both; edge is step 5 vs 6.

---

## Options matrix (new slots)

| Slot | Recommendation | Alternate | Avoid |
|---|---|---|---|
| **Scheduler** | **Adopt** cron/systemd + Core `green-check` / CI | Prefect or Kestra when run UX / retries needed | Airflow default; Mage unless already owned |
| **LLM gateway** | **Self-host LiteLLM** (budgets, OpenAI-compat) | Portkey gateway (MIT) or Bifrost (Apache-2.0) | OmniRoute as Core product; Kong unless ops already runs it |
| **Vector/KB** | **Self-host pgvector** in Core Postgres | Qdrant if scale; Onyx/RAGFlow for connectors | Vector RAG as MetricFlow SoT; Elasticsearch-heavy default |

Harness / dlt / dbt / MetricFlow picks unchanged from research pack — see executive summary.

---

## How the harness talks to each plane

| Plane | Protocol | Auth | What it may answer |
|---|---|---|---|
| **Metrics / marts** | Core MCP + Modeling API (`list_metrics`, `get_manifest`, `mf_query`) | Principal token → three-layer ACL | Numbers from MetricFlow only; query shown |
| **IP / docs KB** | Core `kb_search` / `kb_cite` tools (or Onyx retrieve tool in variant B) | Same principal + doc ACL filter | Citations / excerpts — **never** metric definitions as SoT |
| **Models / spend** | Harness OpenAI base URL → **LiteLLM** → providers | LiteLLM virtual keys + per-principal budgets | Completions only; no warehouse credentials |

Invariant: LiteLLM never holds warehouse DSNs. Vector index never stores MetricFlow metric definitions as authoritative truth (docs may *describe* metrics; queries go through Core).

---

## Variant A — Lean Core+LibreChat (primary)

```mermaid
flowchart TB
  subgraph EDGE["Customer edge"]
    U["Principals / browsers"]
    H["LibreChat or Open WebUI"]
    HER["Hermes — operator sidecar"]
  end

  subgraph GATE["Model plane"]
    LL["LiteLLM — route + spend"]
    P["Model providers / Ollama"]
  end

  subgraph CORE["Core — one VM ADR-003"]
    MCP["Modeling API + MCP tools"]
    ACL["Allowlist + three-layer ACL"]
    MF["MetricFlow"]
    PG["Postgres — marts + pgvector KB"]
    DBT["dbt"]
    DLT["dlt"]
    SCH["cron / green-check"]
  end

  U --> H
  HER -.->|optional| LL
  H -->|chat completions| LL
  LL --> P
  H -->|MCP / OpenAPI| MCP
  MCP --> ACL
  ACL --> MF
  MF --> PG
  MCP -->|kb_search ACL-filtered| PG
  SCH --> DLT
  SCH --> DBT
  DLT --> PG
  DBT --> PG
  DBT --> MF
```

---

## Variant B — Core+Onyx dual-plane

```mermaid
flowchart TB
  subgraph EDGE["Customer edge"]
    U["Principals"]
    H["LibreChat / Open WebUI"]
  end

  subgraph GATE["Model plane"]
    LL["LiteLLM"]
    P["Providers"]
  end

  subgraph CORE["Core metrics SoT"]
    MCP["Core MCP — metrics tools"]
    ACL["Metric ACL"]
    MF["MetricFlow"]
    PG["Postgres marts"]
  end

  subgraph DOCS["Doc plane — adjunct"]
    ON["Onyx CE/EE ± RAGFlow"]
    DOCACL["Doc permission sync"]
  end

  U --> H
  H --> LL --> P
  H -->|metrics tools| MCP
  MCP --> ACL --> MF --> PG
  H -->|doc retrieve tool| ON
  ON --> DOCACL
  ON -.->|never replaces| MF
```

**Risk:** dual ACL. Mitigate by product copy + tool naming: metrics tools vs doc tools; no silent merge of Onyx answers into “the number.”

---

## Variant C — Headless-first

```mermaid
flowchart TB
  subgraph CLIENT["Integrators"]
    LG["LangGraph / LlamaIndex / Haystack"]
    CLI["ns-core CLI"]
  end

  subgraph GATE["Model plane"]
    LL["LiteLLM"]
    P["Providers"]
  end

  subgraph CORE["Core"]
    API["Modeling API"]
    ACL["ACL"]
    MF["MetricFlow"]
    PG["Postgres"]
    PIPE["dlt → dbt via cron/green-check"]
  end

  LG --> LL --> P
  LG -->|tools| API
  CLI --> API
  API --> ACL --> MF --> PG
  PIPE --> PG
```

Proves PRD step 6 before packaging a chat UI. LibreChat lands later without changing Core tools. **Core subgraph ≡ Variant A Core** — see [Core context](#core-context-variant-a-vs-c-same-spine).

Full setup + metric-chat sequences: [Sequence — initial pipelines, then chat a metric](#sequence--initial-pipelines-then-chat-a-metric).

---

## Compose footprint (lean A)

| Service | Role | Required v1 |
|---|---|---|
| Postgres (+ pgvector) | Warehouse / marts / KB | Yes (`warehouse.mode: local`) |
| dlt workers | Ingest | Yes (enabled pipelines) |
| dbt | Transforms | Yes |
| MetricFlow + Modeling API/MCP | Metrics SoT + tools | Yes |
| LiteLLM | Route + spend | Yes when chat/agent on |
| LibreChat (or OWUI) | Customer harness | After headless proof |
| Hermes | Operator only | Optional |
| Onyx / RAGFlow / Qdrant / Prefect | Adjuncts | No until sold / scaled |

`warehouse.mode: external` keeps MetricFlow + API + LiteLLM + harness against customer DSN; dlt/dbt may run off-box per customer ops.

---

## Operator decisions still open

1. LibreChat vs Open WebUI packaging (license / SCIM weight) — stars lean OWUI; shortlist still LibreChat MIT default.  
2. Stamp ADR-001: Hermes operator-sidecar vs keep “v0 runtime” language.  
3. When to introduce Prefect vs Kestra (RAM vs run UX).  
4. Org-doc SKU → variant B timing (Onyx CE vs EE permission sync).  
5. LiteLLM license diligence; optional Bifrost spike.  
6. pgvector embedding path (local model via Ollama vs cloud via LiteLLM).

---

## Related artifacts

| Artifact | Path |
|---|---|
| Harness research | `docs/product/research/oss-agent-harness-chat-data-20260922/` |
| Slot discovery (this run) | `…/slot-discovery-20260922.md` |
| Archify lean A | `docs/architecture/chat-data-plane/` |
| Core overview | `docs/architecture/overview.md` |
| Canonical plan | `docs/plans/narrowstack-core-architecture-20260831.md` |
