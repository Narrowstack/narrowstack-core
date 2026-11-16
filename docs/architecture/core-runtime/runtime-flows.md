---
kind: architecture
slug: core-runtime-runtime-flows
date: 2026-09-22
verified: 2026-09-22
status: proposed
refs:
  - docs/architecture/core-runtime/requirements.md
  - compose/local-warehouse/docker-compose.yml
  - compose/local-warehouse/.env.example
  - docs/architecture/packaging.md
  - docs/features/rollback-deploy.md
  - docs/features/ns-core-cli.md
  - docs/product/prd.md
  - deploy/restore.sh
---

# Core runtime — runtime flows

**Summary:** How Core behaves at runtime, as sequence diagrams: deploy, redeploy, refresh, query, deny, access setup, rollback, and restore. Flows 1 to 8 are on the initial execution path. Flow 9 (chat edge) is a **stub** and is not part of the first deployment. Every flow is **proposed** and describes Phase B (build) behavior, which waits for operator sign-off G8 ([wave-review-gate.md](../../process/wave-review-gate.md)).

## How to read these flows

- Terms (Core, principal, access mode, generation, green-check, row scope) are defined in [README.md](./README.md#terms-used-here). Invariants (INV-n) live in [system-architecture.md](./system-architecture.md#invariants). Requirement IDs come from [requirements.md](./requirements.md).
- Services match the compose file ([docker-compose.yml](../../../compose/local-warehouse/docker-compose.yml)): `postgres` (the warehouse), `runner`, `api`. Env names match [.env.example](../../../compose/local-warehouse/.env.example).
- Green-check stage numbers (1 to 11) follow the table in [deployment-coolify.md](./deployment-coolify.md). State file fields are owned by [interface-contracts.md](./interface-contracts.md#state-files). Enforcement rules are owned by [access-control.md](./access-control.md).
- `alt` / `else` blocks are failure branches. Dashed arrows mark stub surfaces.

## 1. First deploy on Coolify

*A fresh tenant server goes from an empty Coolify resource to an API serving generation 1, or to no API at all.*

**Exercises:** three-input instance (CORE-DEP-01) · one compose resource (CORE-DEP-02) · startup order (CORE-DEP-05) · loud input failures (CORE-DEP-06) · images built on deploy (CORE-DEP-07) · read-only semantics clone (CORE-PIPE-01) · dlt load (CORE-PIPE-02) · dbt build (CORE-PIPE-03) · green-check in order (CORE-GEN-01) · allowlist (CORE-GEN-02) · tie-out (CORE-GEN-03) · ACL smoke (CORE-GEN-04) · atomic publish (CORE-GEN-05) · rollback-first (CORE-GEN-06) · health endpoints (CORE-API-08) · per-role credentials (CORE-ACC-09) · no host ports (CORE-SEC-01) · control plane off (CORE-TEL-01).

```mermaid
sequenceDiagram
  autonumber
  actor Op as Operator
  participant C as Coolify
  participant PG as postgres (warehouse)
  participant R as runner
  participant A as api
  Op->>C: Create Docker Compose resource at a Core release tag, enter runtime env values, deploy
  C->>C: Render compose with env, build runner and api images from repo contexts
  alt A required env value is missing
    C-->>Op: Render fails and names the variable. Nothing starts
  end
  C->>PG: Start
  PG-->>C: pg_isready healthy
  C->>R: Start (depends on postgres healthy), entrypoint ns-core bootstrap
  R->>R: Stage 1 snapshot (no active generation yet)
  R->>R: Stage 2 clone semantics repo at NS_SEMANTICS_REF with the read-only deploy key, resolve SHA
  R->>R: Stage 3 validate manifest. semantics_ref and tenant_id must equal env, else name the field
  R->>PG: Stage 4 as superuser: roles, schemas, grants (idempotent), then drop to per-role credentials
  R->>PG: Stage 5 dlt as ns_loader into raw_*, dbt as ns_transformer into staging__g1 and marts__g1
  R->>R: Stages 6 to 10: allowlist, ACL smoke, tie-out, smoke query, telemetry T0 verify
  alt All stages pass
    R->>PG: Stage 11 publish: set ns_core.active_generation to 1
    R->>R: Write state/active-manifest.json, exec supercronic
    R-->>C: Healthcheck healthy (active last-good generation exists)
    C->>A: Start (depends on runner healthy)
    A->>A: Load generation 1 from state and artifacts volumes, run ACL self-test
    alt Self-test passes
      A-->>C: /readyz ready. Coolify proxy routes the api domain with TLS
    else Self-test fails
      A-->>C: /readyz not ready (503). api unhealthy, no traffic served
    end
  else Any stage fails
    R->>R: Record the failed gate report in the state volume. There is no last-good generation
    R-->>C: Healthcheck unhealthy once start_period (30m) ends
    Note over C,A: api never starts, so nothing is served without a generation
  end
```

- Coolify builds `build:` services from its own clone of the Core repo ([Coolify compose build pack](https://coolify.io/docs/applications/build-packs/docker-compose)). The tenant semantics repo is cloned by the runner at stage 2, not by Coolify.
- Recovery from a failed first deploy: fix the input the gate report names, then redeploy. The runner container keeps running while unhealthy, so `ns-core status` works in the resource terminal.

## 2. Redeploy with a pin change

*An upgrade (new `NS_SEMANTICS_REF` or Core release tag) publishes generation N+1, or leaves N active and says why.*

**Exercises:** upgrade by pins (CORE-OPS-04) · idempotent redeploy (CORE-DEP-04) · green-check in order (CORE-GEN-01) · atomic publish (CORE-GEN-05) · rollback-first (CORE-GEN-06) · hot-load without restart (CORE-API-10) · status output (CORE-OPS-01) · retained gate reports (CORE-OPS-06).

```mermaid
sequenceDiagram
  autonumber
  actor Op as Operator
  participant C as Coolify
  participant R as runner
  participant PG as postgres (warehouse)
  participant A as api
  Op->>C: Change NS_SEMANTICS_REF and/or the resource's Core release tag, redeploy
  C->>C: Rebuild images, recreate containers (no rolling updates for compose)
  Note over C,A: api is down while containers are recreated. How long depends on when runner reports healthy (open question)
  R->>R: Stage 1 snapshot records generation N, its pins, and the manifest hash
  R->>R: Stages 2 to 4 with the new pins
  R->>PG: Stage 5 builds staging__gN+1 and marts__gN+1 while marts__gN keeps serving
  R->>R: Stages 6 to 10
  alt All stages pass
    R->>PG: Stage 11 publish N+1 (pointer plus active-manifest.json)
    A->>A: Poll sees N+1 and hot-loads it. In-flight queries finish on N
    R->>PG: Drop generations beyond NS_GENERATIONS_RETAINED. N stays as the rollback target
  else Any stage fails
    R->>R: Keep N active, write the failed stage and reason to the gate report
    R-->>C: Healthcheck healthy, state degraded (serving last-good N)
    Op->>R: ns-core status shows the failed gate and the pins that failed
  end
```

- Coolify does not support rolling updates for compose resources ([Coolify rolling updates](https://coolify.io/docs/knowledge-base/rolling-updates)), so every redeploy has an API gap. Core does not try to hide it.
- A degraded runner looks healthy in Coolify. The failed gate is visible only in `ns-core status`, the gate report, and the runner log.

## 3. Scheduled refresh

*supercronic fires a refresh on the same pins; the refresh gate publishes N+1 atomically or keeps N.*

**Exercises:** container cron that never changes pins (CORE-PIPE-04) · atomic refresh (CORE-PIPE-05) · dlt load (CORE-PIPE-02) · atomic publish (CORE-GEN-05) · hot-load without restart (CORE-API-10).

```mermaid
sequenceDiagram
  autonumber
  participant SC as supercronic (PID 1 in runner)
  participant R as ns-core refresh
  participant PG as postgres (warehouse)
  participant A as api
  SC->>R: Fire at NS_REFRESH_SCHEDULE with the pins of generation N
  R->>PG: Stage 5: full-refresh dlt load into raw_*, dbt build into gN+1
  R->>R: Stage 7 ACL smoke (cached, manifest unchanged), stage 8 tie-out, stage 9 smoke query
  alt Refresh gate passes
    R->>PG: Stage 11 publish N+1 (same semantics_sha and core_version as N)
    A->>A: Hot-load N+1 without restart
  else Refresh gate fails
    R->>R: Keep N active, record the failed gate report, runner degraded
    Note over A: api keeps answering from N with the same numbers
  end
```

- The refresh gate is stages 5, 7 (cached), 8, 9, 11. Stages 1 to 4, 6 (allowlist), and 10 (telemetry) are skipped because pins and manifest are unchanged.
- supercronic also fires `ns-core backup` at `NS_BACKUP_SCHEDULE` (Core snapshots, CORE-OPS-02). supercronic keeps the container env for jobs and logs to stdout ([supercronic](https://github.com/aptible/supercronic)).

## 4. Headless metric query over MCP (Variant C)

*An off-VM integrator agent gets a number with its SQL and generation through `/mcp`; REST and CLI take the same path.*

**Exercises:** one process, one enforcement library (CORE-API-01) · filtered listing (CORE-API-02) · rows plus SQL and generation (CORE-API-04) · bearer on every MCP request (CORE-API-06) · CLI goes through the API (CORE-API-07) · versioned contract (CORE-API-09) · principal tokens (CORE-ACC-04) · allowed metrics (CORE-ACC-05) · row scope (CORE-ACC-06) · audit row (CORE-ACC-08) · API holds only query and state roles (CORE-ACC-09) · headless example client (CORE-API-11, core later).

```mermaid
sequenceDiagram
  autonumber
  participant Cl as Integrator agent (off-VM)
  participant P as Coolify proxy (TLS)
  participant A as api /mcp
  participant PG as postgres (warehouse)
  Cl->>P: POST /mcp initialize, Authorization Bearer nsc_ token
  P->>A: Forward
  A->>PG: As ns_api: look up HMAC(pepper, token) in ns_core.principal_tokens
  alt Token missing, unknown, expired, or revoked
    A-->>Cl: 401
  else Token valid
    PG-->>A: Principal id, metric patterns, row scope
    Note over Cl,A: Authentication repeats on every HTTP request, tools/list included
    Cl->>A: tools/list
    A-->>Cl: list_metrics, get_manifest, mf_query
    Cl->>A: tools/call list_metrics
    A->>A: Allowed = principal patterns ∩ shipped metrics of generation N
    A-->>Cl: Allowed metrics only, each with a row_scoped flag
    Cl->>A: tools/call mf_query (metrics, group_by, where, time range)
    A->>A: Check every metric is allowed and scopable (else flow 5), AND the row scope into where
    A->>A: MetricFlowEngine compiles against generation N's semantic manifest
    A->>PG: Execute the compiled SQL as ns_query on marts__gN
    PG-->>A: Rows
    A->>PG: As ns_api: insert audit row (surface mcp, no metric values)
    A-->>Cl: columns, rows, sql, applied_scope, generation, query_id, tool_contract 1
  end
```

- **REST is identical:** `GET /v1/metrics` and `POST /v1/query` run the same enforcement library and return the same rows and SQL for the same principal (one enforcement point, INV-1). Shapes are in [interface-contracts.md](./interface-contracts.md).
- **CLI:** `ns-core query` in the runner calls the api on the resource network with a principal token (surface `cli`). With the api stopped it fails; there is no direct warehouse path.
- **Open mode:** no bearer is checked, the principal is `open`, allowed = all shipped metrics, no row scope, and every response is marked open (open-mode signals, CORE-ACC-02). The allowlist and warehouse grants still apply (CORE-ACC-03).
- Other errors on this path: 400 invalid request, 409 no active generation, 503 not ready.

## 5. Denied query

*A metric outside the grant, or one the principal's row scope cannot reach, returns 403 with nothing leaked and still leaves an audit row.*

**Exercises:** denial body (CORE-API-05) · denied names omitted from listings (CORE-API-02) · allowed metrics (CORE-ACC-05) · row scope fails closed (CORE-ACC-06) · audit row (CORE-ACC-08).

```mermaid
sequenceDiagram
  autonumber
  participant Cl as Caller (REST, MCP, or CLI)
  participant A as api enforcement library
  participant PG as postgres (warehouse)
  Cl->>A: mf_query with a valid token
  A->>A: Resolve principal, allowed metrics, row scope
  alt A requested metric is not in the allowed set
    A->>PG: As ns_api: audit row, decision deny
    A-->>Cl: 403, body is error and query_id only
  else Principal is row-scoped and a metric cannot reach a scope dimension
    A->>PG: As ns_api: audit row, decision deny
    A-->>Cl: 403, body is error and query_id only (fails closed)
  else Every metric is allowed and scopable
    A->>PG: Execute as ns_query (flow 4)
  end
  Note over A,PG: The check runs before compile and execute, so no SQL, value, or row count exists to leak
```

- Example, not granted: a principal limited to `revenue_*` asks for `payroll_total`. It never saw that name in `list_metrics`.
- Example, scope-incompatible: a principal scoped to `customer__region in [EMEA]` asks for a metric with no path to `customer__region`.
- A request mixing one allowed and one denied metric is denied as a whole. There are no partial rows.

## 6. Optional access-setup step

*The operator turns on token mode through the manifest and issues the first operator token; skipping the step leaves the instance in open mode.*

**Exercises:** optional access setup (CORE-ACC-07) · access modes (CORE-ACC-01) · access config in the manifest (CORE-ACC-10) · principal tokens (CORE-ACC-04) · ACL smoke (CORE-GEN-04).

```mermaid
sequenceDiagram
  autonumber
  actor Op as Operator
  participant S as Tenant semantics repo
  participant C as Coolify
  participant R as runner
  participant A as api
  participant PG as postgres (warehouse)
  Op->>S: Add the access block (mode token) and principals with row scopes to the manifest, tag a new ref
  Op->>C: Set NS_SEMANTICS_REF to the new tag, confirm the token pepper is set, redeploy
  C->>R: Bootstrap runs green-check (flow 2). Stage 7 smokes every principal fixture
  alt Gate passes
    R->>R: Publish a generation whose access_mode is token
    A->>A: Hot-load it. From now on every call without a token gets 401
    Op->>R: docker compose exec runner ns-core access setup
    R->>R: Verify access_mode in active-manifest.json, run the ACL smoke through the enforcement library
    R->>PG: Store HMAC(pepper, first operator token) with its expiry in ns_core.principal_tokens
    Note over R,A: Open question: compose gives the pepper to api only, so where the HMAC is computed is unresolved
    R-->>Op: First operator token, shown once
  else Gate fails
    R->>R: Previous generation stays active, so the instance stays in open mode
  end
```

- Between publish and `ns-core access setup` no token exists, so every metric call gets 401. The gap fails closed.
- On Coolify the pepper is normally generated (`SERVICE_PASSWORD_64_TOKENPEPPER`); the step is to confirm it, not to invent one. Rotating it invalidates every issued token.
- **If the step is skipped:** no `access` block means open mode. The instance works, and every open-mode signal fires (CORE-ACC-02): startup and repeated warnings, the response header and body field, the red banner in `ns-core status`, and a gate-report warning. Details are owned by [access-control.md](./access-control.md).

## 7. Operator rollback

*Two paths back: revert pins and redeploy (durable), or flip the pointer to a retained generation (fast).*

**Exercises:** upgrade and rollback by pins (CORE-OPS-04) · activate a retained generation (CORE-GEN-07) · rollback-first (CORE-GEN-06).

```mermaid
sequenceDiagram
  autonumber
  actor Op as Operator
  participant C as Coolify
  participant R as runner
  participant A as api
  alt Durable: revert pins
    Op->>C: Revert NS_SEMANTICS_REF and/or the Core release tag to last-good values, redeploy
    C->>R: Rebuild and recreate. Bootstrap gates the reverted pins (flow 2)
    alt Gate passes
      R->>R: Publish a generation built from the reverted pins
      A->>A: Hot-load it
    else Gate fails
      R->>R: Keep the current generation, runner degraded
    end
  else Fast: pointer flip
    Op->>R: ns-core generations activate N
    alt N is retained
      R->>R: Set active_generation to N, rewrite active-manifest.json
      A->>A: Hot-load N (target under one minute)
      Note over Op,C: Coolify env still holds the newer pins. Follow up with the durable path
    else N was dropped
      R-->>Op: Error names N. Nothing changes
    end
  end
```

- Coolify's own rollback button redeploys an older image but does not restore volumes or database state ([Coolify rollbacks](https://next.coolify.io/docs/applications/deployments/rollbacks)). It is not a Core rollback; Core owns rollback through the generation pointer.

## 8. Destroy, then restore drill

*The buyer-checkable claim: a restored instance answers the PRD step-6 question with the step-4 tie-out number.*

**Exercises:** destroy and restore (CORE-OPS-03, core later) · scheduled backup (CORE-OPS-02) · audit export (CORE-ACC-08). Trace: [PRD](../../product/prd.md) step 10.

```mermaid
sequenceDiagram
  autonumber
  actor Op as Operator
  participant Old as Old instance
  participant B as Backup target (S3-compatible)
  participant C as Coolify
  participant New as New instance
  Op->>Old: Ask the step-6 question. Record the number, SQL, and generation (equals the step-4 tie-out)
  Op->>Old: Confirm a recent backup at BACKUP_TARGET, export the audit log
  Op->>C: Destroy the resource and its volumes
  Op->>C: Create the resource on a fresh server with the same inputs (tag, pins, env values)
  C->>New: Deploy (flow 1)
  Op->>New: docker compose exec runner ns-core restore
  New->>B: Pull the latest backup
  New->>New: Restore the warehouse, rebuild and gate a generation, publish
  alt Restore gate passes
    Op->>New: Ask the step-6 question through the API or CLI
    alt Number equals the recorded step-4 number
      Op->>Op: Drill passes
    else Number differs
      Op->>Op: Drill fails. Record both numbers and both SQL strings
    end
  else Restore gate fails
    New-->>Op: Drill fails. Gate report names the stage
  end
```

- Restore is scripted because Coolify's restore UI does not cover a database inside a compose resource ([Coolify backups](https://coolify.io/docs/databases/backups)).
- If flow 1 fails on the fresh server, the runner still runs (unhealthy), so `ns-core restore` can still be run from the resource terminal.

## 9. Chat query via the edge (Variant A, stub)

**Stub, off the initial execution path.** Not in the compose file and not part of the first deployment. Shown only so Core's `oidc` seam is designed now. Edge contracts are owned by [edge-stubs.md](./edge-stubs.md).

*A signed-in chat user's IdP access token reaches Core `/mcp`, and Core maps it to a manifest principal before the same enforcement as flow 4.*

**Exercises (stub):** separate resource (STUB-EDGE-01) · verifiable per-user credential (STUB-EDGE-02) · edge holds no warehouse credential (STUB-EDGE-07) · Core MCP not behind the model gateway (STUB-MODEL-02) · OIDC mode (CORE-ACC-11) · bearer on every MCP request (CORE-API-06).

```mermaid
sequenceDiagram
  autonumber
  actor U as Customer user
  participant E as Chat edge (stub)
  participant I as Customer IdP
  participant M as Model plane (stub)
  participant A as api /mcp (oidc mode, stub)
  U-->>E: Open chat
  E-->>I: OIDC sign-in
  I-->>E: IdP-signed access token for this user
  E-->>A: initialize and tools/list, Bearer IdP access token
  A-->>I: Issuer discovery and JWKS fetch (cached)
  A->>A: Verify signature, issuer, audience, expiry. Map claim (sub or groups) to a manifest principal
  alt Invalid token, wrong issuer or audience, or identity headers only
    A-->>E: 401
  else Valid and mapped
    A-->>E: Tools the principal may use
    U-->>E: Ask a metric question
    E-->>M: Completion request with tool definitions
    M-->>E: Tool call mf_query
    E-->>A: tools/call mf_query, Bearer the same user token
    A->>A: Same enforcement as flows 4 and 5, audit surface mcp
    A-->>E: Rows, SQL, generation, or 403
    E-->>M: Tool result
    E-->>U: Answer with the query shown
  end
```

- The edge calls Core directly for metric tools; completions go to the model plane, never to Core (INV-12 keeps Core unchanged when this lands).

## Generation lifecycle

*One generation from build to drop; the pointer flip is the only way a generation becomes active.*

**Exercises:** atomic publish (CORE-GEN-05) · rollback-first (CORE-GEN-06) · activate a retained generation (CORE-GEN-07).

```mermaid
stateDiagram-v2
  state "building (stage 5)" as building
  state "gated (stages 6 to 10)" as gated
  state "published (active)" as published
  state "retained (previous)" as retained
  [*] --> building: bootstrap or refresh starts generation N
  building --> gated: dlt load and dbt build finished
  building --> failed: load or model failure
  gated --> published: every stage passes, stage 11 flips the pointer
  gated --> failed: any stage fails
  published --> retained: a newer generation is published or another is activated
  retained --> published: ns-core generations activate N
  retained --> dropped: beyond NS_GENERATIONS_RETAINED
  failed --> dropped: failed schemas removed (timing open)
  dropped --> [*]
```

## Open questions raised by these flows

Owned by [decisions-and-open-questions.md](./decisions-and-open-questions.md) once reconciled.

1. **Runner health on redeploy.** Is the runner healthy as soon as generation N exists (short API gap, API serves N while N+1 builds), or only after bootstrap finishes (API gap up to the full bootstrap)?
2. **Pins after a failed gate or a pointer flip.** Does a scheduled refresh use the Coolify env pins or the active generation's pins? If env, a refresh after a failed upgrade or after `generations activate` retries the pins the operator backed away from.
3. **Core version skew.** Can the api at a new Core tag load a generation built by the previous tag while the new one builds?
4. **Publish atomicity.** Publish writes both `ns_core.active_generation` and `active-manifest.json`. Which one wins after a crash between the two writes (CORE-GEN-05)?
5. **Shared `raw_*` during refresh.** Atomic refresh (CORE-PIPE-05) holds only if nothing in the active generation reads `raw_*` live (for example staging views). Must staging and marts be materialized per generation?
6. **Refresh concurrency.** What happens when a scheduled refresh fires during a bootstrap, a backup, or another refresh?
7. **Token issue and the pepper.** Compose gives `NS_CORE_TOKEN_PEPPER` to `api` only, yet `ns-core access token issue` runs in the runner. Does issuance go through an api endpoint (not in the contract yet) or does the runner also get the pepper?
8. **Existence oracle.** Should an unknown metric name and a denied one return the same response, so a 400 versus 403 difference does not reveal that a denied metric exists?
9. **Unscopable metrics in listings.** Should `list_metrics` omit a metric that matches the grant but cannot reach the principal's scope, since `mf_query` will always deny it?
10. **Audit edge cases.** Are unauthenticated (401) calls audited, and does a failed audit insert block the response?
11. **`NS_AUTO_ROLLBACK=0` under blue/green.** A failed generation is never published, so what does disabling auto-rollback change beyond keeping failed schemas for inspection?
12. **Rollback commands.** How does the existing `ns-core rollback` relate to `ns-core generations activate`? Does a redeploy whose pins match a retained generation reuse it or rebuild it?
13. **Restore contents and entrypoint.** The platform backup covers the database, not the `state` and `artifacts` volumes. Does restore rebuild artifacts from the pinned SHA? Should a fresh server skip the full source load before `ns-core restore`? Canon [restore.sh](../../../deploy/restore.sh) replays green-check "steps 3 to 6" (stages 5 to 8 here), which reloads sources and can change the number.
14. **Pepper across restore.** A new Coolify resource generates a new pepper, which invalidates every restored token hash. Carry the pepper over, or reissue tokens after restore?
15. **Stub, OIDC.** Does a valid token whose claim maps to no principal get 401 or 403? Must Core serve MCP protected-resource metadata ([MCP authorization](https://modelcontextprotocol.io/specification/2025-06-18/basic/authorization))? Stage 10 must not treat JWKS egress to the customer IdP as telemetry.
