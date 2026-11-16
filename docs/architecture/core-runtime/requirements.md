---
kind: architecture
slug: core-runtime-requirements
date: 2026-09-22
verified: 2026-09-22
status: proposed
refs:
  - docs/product/prd.md
  - docs/architecture/packaging.md
  - docs/architecture/telemetry-protocol.md
  - docs/features/metric-acl.md
  - docs/features/modeling-api.md
  - compose/local-warehouse/docker-compose.yml
---

# Core runtime — requirements registry

**Summary:** This is the requirement stub for Core's runtime, the shared spine of Variant A (chat edge) and Variant C (headless). Core requirements are on the initial execution path. Chat edge, model plane, and knowledge plane requirements are **stubs**: written now so Core honors their contracts, but built later. Nothing here is implemented, and every design choice is **proposed** unless its trace cites operator direction (Tucker, 2026-09-22).

Terms (Core, principal, access mode, open mode, row scope, generation, green-check, stub) are defined in [README.md](./README.md#terms-used-here).

## How to read and cite

- **ID format:** `CORE-<area>-NN` for Core, `STUB-<surface>-NN` for stubs. Other docs cite them as *plain name (ID)*, for example "row scope fails closed (CORE-ACC-06)".
- **Areas:** `DEP` deploy and provision · `PIPE` pipelines and runtime · `GEN` generations and gates · `API` Modeling API, MCP, and CLI surface · `ACC` access control · `OPS` operations · `SEC` secrets and network · `TEL` telemetry.
- **Status:** `core` = on the initial execution path · `core, later` = Core, but after the first clean deploy · `stub` = off the initial execution path.
- **Trace** points at what the requirement comes from: PRD walking-skeleton step (`PRD n`), a canon doc, an invariant from [system-architecture.md](./system-architecture.md#invariants) (`INV-n`), or operator direction (`Tucker`).
- Sequencing (which requirement lands in which build slice) belongs to the implementation plan, not this file.

## Deploy and provision (DEP)

| ID | Requirement | Acceptance check | Trace | Status |
|---|---|---|---|---|
| CORE-DEP-01 | A tenant instance is fully described by three inputs: the Core release tag, the tenant manifest at its semantics ref, and runtime env values. | A second instance deploys from those inputs with zero manual steps beyond entering env values. | PRD 1; PRD done-means; packaging AC1 | core |
| CORE-DEP-02 | Core deploys as **one** Coolify Docker Compose resource built from `Narrowstack/narrowstack-core` at a release tag, compose location `compose/local-warehouse/docker-compose.yml`. | On a fresh Coolify server, creating the resource and deploying reaches all services healthy. | Tucker (Coolify goal); D7 | core |
| CORE-DEP-03 | The compose file uses standard Compose keys only: no `profiles:`, no Coolify-only keys, no YAML anchors. | `docker compose --env-file .env.example config --quiet` exits 0 in CI. | Coolify research 2026-09-22 | core |
| CORE-DEP-04 | Redeploying the same inputs is idempotent. | Second deploy produces no role, grant, or schema drift, and publishes content identical to the prior generation. | PRD 1; packaging AC2 | core |
| CORE-DEP-05 | Startup order is warehouse healthy, then runner healthy, then API. | The API never accepts traffic before an active generation exists. | INV-8 | core |
| CORE-DEP-06 | Missing or inconsistent inputs fail loudly and name what is wrong. | Missing required env fails compose rendering and names the variable. A manifest `tenant_id` or `semantics_ref` that disagrees with env fails gate stage 3 and names the field. | instance-manifest spec | core |
| CORE-DEP-07 | The runner and API images build from repo contexts `runner/` and `api/` during the Coolify deploy, tagged with `NS_CORE_VERSION`. | Coolify build log shows both images built from the pinned tag. | Proposed (new build contexts) | core |

## Pipelines and runtime (PIPE)

| ID | Requirement | Acceptance check | Trace | Status |
|---|---|---|---|---|
| CORE-PIPE-01 | The runner clones the tenant semantics repo at `NS_SEMANTICS_REF` with a read-only deploy key and records the resolved commit SHA. | `active-manifest.json` shows `semantics_ref` and `semantics_sha`; a key with write scope is rejected by the setup checklist. | semantics delivery (D5) | core |
| CORE-PIPE-02 | dlt loads exactly the manifest's `enabled_pipelines` into `raw_<source>` schemas as role `ns_loader`. | `_dlt_loads` shows a completed load for each enabled source and none for others. | PRD 2 | core |
| CORE-PIPE-03 | dbt builds staging, then marts with one durable entity key per mart, as role `ns_transformer`. | `dbt parse` succeeds; the metric's entity resolves to a surrogate key. | PRD 3 | core |
| CORE-PIPE-04 | Scheduled refresh runs on container-native cron at `NS_REFRESH_SCHEDULE` and never changes pins. | Two refreshes publish two generations with identical `semantics_sha` and `core_version`. | Cursor pack (cron + green-check v1) | core |
| CORE-PIPE-05 | A refresh publishes atomically or not at all. | Induced dbt failure mid-refresh: the API keeps answering from the prior generation with the same number. | INV-8 | core |
| CORE-PIPE-06 | Source credentials reach only the runner, one explicitly listed variable per secret (`SOURCES__<SOURCE>__<KEY>`). | Env of the `api` container contains no `SOURCES__*` variable. | INV-11 | core |
| CORE-PIPE-07 | Loads are full-refresh; the manifest documents `volume_ceiling_gb` and the runner warns before the ceiling is reached. | Runner logs a warning at 80% of the ceiling. | packaging (volume ceiling) | core, later |

## Generations and gates (GEN)

| ID | Requirement | Acceptance check | Trace | Status |
|---|---|---|---|---|
| CORE-GEN-01 | Every deploy runs the green-check stages in canon order (snapshot, clone, validate, warehouse bootstrap, pipelines + dbt, allowlist, ACL smoke, tie-out, smoke query, telemetry check, publish) and records each stage's result. | Gate report in the state volume lists every stage with result and timing. | packaging (green-check) | core |
| CORE-GEN-02 | Allowlist is default-deny in every access mode. | A deliberately unlisted model fails the deploy and the error names the model. | PRD 5; packaging AC3; INV-6 | core |
| CORE-GEN-03 | Every shipped metric is tied out against its source before publish. | Tie-out coverage is 100% of shipped metrics; the result is recorded in the gate report. | PRD 4; PRD done-means | core |
| CORE-GEN-04 | ACL smoke runs each manifest principal fixture through the same enforcement library the API uses. | A fixture that sees one metric more or one fewer than its grant fails the gate. | metric-acl spec | core |
| CORE-GEN-05 | A successful gate publishes a numbered generation atomically and writes `active-manifest.json` with the fields in [interface-contracts.md](./interface-contracts.md#state-files). | Killing the runner mid-publish leaves either the old or the new generation active, never a mix. | packaging (active-manifest) | core |
| CORE-GEN-06 | Rollback-first: on any gate failure the last-good generation stays or becomes active automatically, unless `NS_AUTO_ROLLBACK=0`. With no last-good generation (first deploy) the runner reports unhealthy. | Induced failure on deploy 2: API still serves generation 1; `ns-core status` shows the failed gate. | D11; INV-8 | core |
| CORE-GEN-07 | An operator can switch to a retained generation on demand. | `ns-core generations activate <N>` completes in under a minute with blue/green schemas (proposed) and the API answers from N. | D11 | core |
| CORE-GEN-08 | Customer instances carry no Narrowstack-internal models (payroll, bonus, company-split, demo). | `dbt parse` output for a customer instance has no such models; the allowlist gate enforces it. | PRD 3; packaging AC6 | core |

## Modeling API, MCP, and CLI surface (API)

| ID | Requirement | Acceptance check | Trace | Status |
|---|---|---|---|---|
| CORE-API-01 | REST `/v1` and MCP `/mcp` are served by one process through one enforcement library. | Same principal, same question over REST and MCP returns identical rows and SQL. | Tucker (front door and bouncer); INV-1 | core |
| CORE-API-02 | `list_metrics` returns only metrics the caller may query; denied names are omitted, not masked. | Principal limited to `revenue_*` sees no other names. | metric-acl verification 1; INV-5 | core |
| CORE-API-03 | `get_manifest` returns the semantic-manifest slice for allowed metrics only. | Definitions of denied metrics are absent from the response. | modeling-api spec | core |
| CORE-API-04 | `mf_query` returns rows plus compiled SQL, generation, and applied row scope with every number. | For the PRD step-6 question, the number matches the step-4 tie-out and the SQL is shown. | PRD 6; INV-4 | core |
| CORE-API-05 | A denied query returns 403 with no value, row count, or SQL. | Response body for a denied metric contains only `error` and `query_id`. | metric-acl verification 2; INV-5 | core |
| CORE-API-06 | MCP exposes `list_metrics`, `get_manifest`, and `mf_query` with the same inputs and outputs as REST, and requires the bearer credential on every HTTP request, tool discovery included. | Unauthenticated `tools/list` returns 401 in token mode. | Tucker (MCP in Core surface) | core |
| CORE-API-07 | CLI metric reads (`ns-core query`) call the API with a principal token; the CLI has no direct query path. | With the API stopped, `ns-core query` fails; it never falls back to the warehouse. | INV-1 | core |
| CORE-API-08 | `/healthz` reports liveness and `/readyz` reports readiness (generation loaded and self-test passed); neither exposes instance detail. | Both endpoints return only a status word, unauthenticated. | Coolify health model | core |
| CORE-API-09 | The contract is versioned: path `/v1` and a `tool_contract` field in every response; a breaking change ships as a new version. | Contract tests pin `tool_contract: 1`. | packaging (versioned interfaces) | core |
| CORE-API-10 | The API loads a newly published generation without a restart; in-flight queries finish on the generation they started on. | Publish during a load test causes no errors. | Proposed | core |
| CORE-API-11 | Variant C proof: an off-VM example client (`examples/headless-agent/`, LangGraph) answers the PRD step-6 question through `/mcp` with the tie-out number. | Eval fixture "known question, known number" passes against a deployed instance. | PRD 6; Cursor pack (headless skeleton) | core, later |

## Access control (ACC)

| ID | Requirement | Acceptance check | Trace | Status |
|---|---|---|---|---|
| CORE-ACC-01 | Access modes are `open`, `token`, and `oidc`, set by the manifest `access` block. A manifest without `access` runs in open mode. | Example manifest without `access` boots in open mode; with `access.mode: token` it rejects anonymous calls. | Tucker (default open if not set up) | core |
| CORE-ACC-02 | Open mode is loud: a warning at startup and every 15 minutes, `X-NS-Core-Access-Mode: open` on every response, `access_mode: "open"` in every body and in `/v1/status`, a red banner in `ns-core status`, and a warning (not a failure) in the gate report. | Each signal is observable on an open-mode instance. | Tucker (strongly advised against) | core |
| CORE-ACC-03 | Open mode never exposes more than the allowlist ships, and warehouse role grants stay on. | Open-mode `list_metrics` equals the shipped set exactly; the API role still cannot read `raw_*`. | INV-6; INV-7 | core |
| CORE-ACC-04 | Principal tokens are opaque, prefixed `nsc_`, shown once, stored only as an HMAC with the pepper, always expire (at most `NS_CORE_TOKEN_MAX_TTL_DAYS`), and revoke immediately. | The database holds no plaintext token; a revoked token fails on its next call. | metric-acl non-goal 3 (revocable tokens only) | core |
| CORE-ACC-05 | Allowed metrics are the principal's `metrics` patterns intersected with the shipped metrics, enforced on list, manifest, and query. | Fixture matrix in the ACL smoke passes. | metric-acl; packaging (access control) | core |
| CORE-ACC-06 | Row scope: a principal's `row_scope` filters are ANDed into every query and appear in the returned SQL. A metric that cannot reach a scope dimension is denied (fails closed). | Scoped principal gets EMEA-only rows; an unscopable metric returns 403. | Tucker (row-level scoping, v1) | core |
| CORE-ACC-07 | Instance setup offers an optional access-setup step (`ns-core access setup`): verify mode, run the ACL smoke, issue the first operator token. Skipping it leaves open mode with every warning. | Setup guide documents the step with a "strongly advised" callout; the command exists. | Tucker (optional setup step) | core |
| CORE-ACC-08 | Every call writes an append-only audit row (time, principal, surface, tool, metrics, dimensions, filters including scope, decision, row count, duration, generation) with no metric values. The customer can export it without a support ticket. | API role cannot update or delete audit rows; `ns-core` exports the log. | telemetry protocol (audit) | core |
| CORE-ACC-09 | Warehouse roles are per purpose (`ns_loader`, `ns_transformer`, `ns_query`, `ns_api`); the API holds only `ns_query` and `ns_api` credentials. | `api` container env has no superuser, loader, or transformer password; `ns_query` cannot read `raw_*`. | PRD 1; INV-7 | core |
| CORE-ACC-10 | Access config is reproducible from the manifest: an `access` block and `principals[].row_scope` (proposed schema change). | Schema validates both; a second instance from the same manifest enforces the same grants. | PRD 1; instance-manifest | core |
| CORE-ACC-11 | `oidc` mode validates JWTs from the configured issuer (discovery + JWKS, audience check) and maps a claim to a manifest principal. | A token from another issuer or audience is rejected; a mapped claim gets that principal's grants. | Stub contract for the chat edge | stub |
| CORE-ACC-12 | Postgres row-level security on scoped marts as a backstop to CORE-ACC-06 (policies re-created by dbt post-hooks). | A direct `ns_query` session without the scope setting sees no scoped rows. | Proposed hardening | core, later |

## Operations (OPS)

| ID | Requirement | Acceptance check | Trace | Status |
|---|---|---|---|---|
| CORE-OPS-01 | `ns-core status` shows pins, active generation, last gate result, access mode (red banner when open), and control-plane state. | Output matches `active-manifest.json`. | ns-core CLI spec | core |
| CORE-OPS-02 | The warehouse is backed up on a schedule to an S3-compatible target (Coolify scheduled backup as the platform backup; `ns-core backup` for Core snapshots). | Backup objects appear at `BACKUP_TARGET` with manifest retention. | packaging (backup) | core |
| CORE-OPS-03 | Destroy then restore returns the PRD step-6 answer with the step-4 number. Restore is scripted (`ns-core restore`) because Coolify's restore UI does not cover databases inside a compose resource. | Restore drill passes on a fresh server. | PRD 10; packaging AC4 | core, later |
| CORE-OPS-04 | Upgrade = change the Core release tag and/or `NS_SEMANTICS_REF`, then redeploy through green-check. Rollback = revert those values and redeploy. | Upgrade and rollback drills pass without SSH. | packaging (fleet upgrades) | core |
| CORE-OPS-05 | Someone who did not build Core can provision an instance from the written procedure. | Non-builder provision test passes. | PRD done-means | core, later |
| CORE-OPS-06 | All services log to stdout/stderr; gate reports are retained in the state volume for the retained generations. | Coolify log view shows gate stages; reports survive restarts. | Proposed | core |
| CORE-OPS-07 | Provider mode M0 to M1 via config change gives the same answer. **Definition gap:** M0–M3 are not defined anywhere in this repo. | Blocked until the provider spec is linked. | PRD 7 | core, later |

## Secrets and network (SEC)

| ID | Requirement | Acceptance check | Trace | Status |
|---|---|---|---|---|
| CORE-SEC-01 | No service publishes host ports; only the API is routed publicly, through Coolify's proxy with TLS. | `docker compose config` shows no `ports:`; external scan of the VM finds only the proxy. | INV-10 | core |
| CORE-SEC-02 | Secrets are runtime env values only, never in images, the manifest, or git. | Image history and repo scans find no secret values. | INV-11 | core |
| CORE-SEC-03 | Each service receives only the secrets it needs (see the service table in [deployment-coolify.md](./deployment-coolify.md)). | `api` env lacks superuser, loader, transformer, source, and deploy-key values. Verify Coolify does not inject every resource variable into every container. | INV-2; INV-11 | core |
| CORE-SEC-04 | The semantics deploy key is read-only and scoped to one repo. | Key listed as read-only deploy key on exactly one repo. | Proposed | core |
| CORE-SEC-05 | Committed files carry no hostnames, IPs, personal paths, or personal identities. | Repo scan in CI. | Workspace confidentiality rule | core |

## Telemetry and control plane (TEL)

| ID | Requirement | Acceptance check | Trace | Status |
|---|---|---|---|---|
| CORE-TEL-01 | Control plane is off by default; with it off there is no outbound connection to Narrowstack. | Gate stage 10 and a packet capture show no egress to Narrowstack. | telemetry protocol; INV-9 | core |
| CORE-TEL-02 | The kill-switch never degrades pipelines, dbt, MetricFlow, or the API. | With Narrowstack blocked, refresh and `mf_query` succeed. | PRD 9; INV-9 | core, later |
| CORE-TEL-03 | Consent-first telemetry: T0 heartbeat only at rest; a T1 sample is shown before grant; grant and revoke are audited. | Packet capture matches grant state. | PRD 8 | core, later |

## Stub — chat edge, Variant A (STUB-EDGE)

| ID | Requirement | Acceptance check | Trace | Status |
|---|---|---|---|---|
| STUB-EDGE-01 | The chat edge runs as a separate Coolify resource; enabling it changes no Core semantics, ACL, or metric definitions. | Core compose file and manifest are unchanged when the edge is added. | INV-12 | stub |
| STUB-EDGE-02 | The edge forwards a verifiable per-user credential (IdP-signed access token) to Core on tool discovery and tool calls; identity headers alone are not accepted. | Core in `oidc` mode rejects a call with headers but no valid token. | Tucker (Core is the bouncer); CORE-ACC-11 | stub |
| STUB-EDGE-03 | Per-group model and tool access in the UI. | Group B cannot see a model or tool granted only to group A. | Tucker (v1 edge requirement) | stub |
| STUB-EDGE-04 | Per-group document and knowledge access, enforced at retrieval. | Group B retrieval never returns group A documents. | Tucker (v1 edge requirement) | stub |
| STUB-EDGE-05 | SCIM provisioning and deprovisioning from the customer IdP. | Deprovisioned user loses chat access within one sync cycle. | Tucker (v1 edge requirement) | stub |
| STUB-EDGE-06 | Sized for ≤50 users per tenant; white-label deferred and recorded as a reassessment trigger. | Build-vs-buy verdict records both. | Tucker | stub |
| STUB-EDGE-07 | The edge never holds a warehouse credential; completions go to the model plane, metric tools go to Core directly. | Edge env has no Postgres DSN. | INV-2 | stub |

## Stub — model plane (STUB-MODEL)

| ID | Requirement | Acceptance check | Trace | Status |
|---|---|---|---|---|
| STUB-MODEL-01 | LiteLLM runs as a separate Coolify resource with its own Postgres for keys and spend, never the warehouse cluster. | LiteLLM env has no warehouse DSN. | INV-2; Cursor pack | stub |
| STUB-MODEL-02 | Core's MCP server is never registered in LiteLLM's MCP gateway. | LiteLLM config lists no Core MCP upstream. | INV-1 | stub |
| STUB-MODEL-03 | MIT core only, with no enterprise-directory features without a contract; exact version tag pinned; admin env-credential login disabled. | Deployed tag is exact; admin login via env credentials is off. | LiteLLM license research 2026-09-22 | stub |
| STUB-MODEL-04 | Per-user or per-key budgets and spend tracking. | Budget exhaustion blocks completions for that key only. | Cursor pack (route + spend) | stub |

## Stub — knowledge plane (STUB-KB)

| ID | Requirement | Acceptance check | Trace | Status |
|---|---|---|---|---|
| STUB-KB-01 | The `vector` extension and a `kb` schema live in the warehouse cluster, created only when the knowledge plane is activated. | Before activation, `vector` is not installed. | Proposed (image ready from day one) | stub |
| STUB-KB-02 | `kb_search` and `kb_cite` go through the same API enforcement with a per-principal document filter. | Principal without a document grant gets no excerpts from it. | INV-1 | stub |
| STUB-KB-03 | An allowlist equivalent for knowledge content exists before activation; the model allowlist does not cover documents today. | Unlisted document collection fails ingestion. | allowlist-gate scope gap | stub |
| STUB-KB-04 | Knowledge content never answers a metric; metric numbers come only from `mf_query`. | Eval: metric questions route to `mf_query`, never to `kb_search`. | INV-3 | stub |
| STUB-KB-05 | The embedding path (local model or via the model plane) is decided before activation. | Decision recorded in the document it governs. | Open question | stub |
