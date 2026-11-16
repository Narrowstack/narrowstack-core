---
kind: architecture
slug: core-runtime-deployment-coolify
date: 2026-09-22
verified: 2026-09-22
status: proposed
refs:
  - compose/local-warehouse/docker-compose.yml
  - compose/local-warehouse/.env.example
  - compose/external-warehouse/docker-compose.yml
  - manifest/schema.json
  - manifest/examples/example-local-warehouse.yaml
  - docs/architecture/decisions.md
  - docs/architecture/packaging.md
  - docs/features/local-warehouse-deploy.md
  - docs/features/rollback-deploy.md
  - docs/process/wave-review-gate.md
---

# Core runtime: deployment on Coolify

**Summary:** Each tenant's Core instance (warehouse, pipeline runner, Modeling API) deploys as **one Coolify Docker Compose resource** on that tenant's own VM, built from `Narrowstack/narrowstack-core` at a release tag. Only the `api` service gets a domain; nothing publishes a host port. Coolify handles the clone, build, proxy, TLS, env entry, and scheduled database backup. Core owns the deploy gate, rollback, and restore, because Coolify's versions of those do not cover volumes or database state.

> **Status: proposed, Phase G.** A real deploy is Phase B work and waits for the operator sign-off gate that opens it (G8, see [wave-review-gate](../../process/wave-review-gate.md) and decisions D13/D14 in [decisions.md](../decisions.md)). The `runner/` and `api/` build contexts do not exist yet, so only `postgres` can start today.
>
> **Not on the initial execution path:** the chat edge, model plane, and knowledge plane are stubs. They are not in this compose file and are not part of the first deployment ([edge-stubs.md](./edge-stubs.md)).

Quick-start commands live in [compose/local-warehouse/README.md](../../../compose/local-warehouse/README.md). Terms (Core, tenant, generation, green-check, principal) are defined in [README.md](./README.md#terms-used-here); invariants (INV-n) in [system-architecture.md](./system-architecture.md#invariants).

## Topology

```mermaid
flowchart LR
  subgraph NS["Narrowstack"]
    CP["Coolify control plane<br/>(multi-tenant, ADR-003)"]
    TCP["Telemetry control plane<br/>(optional)"]
  end
  GHC["GitHub: Narrowstack/narrowstack-core<br/>(release tag)"]
  GHS["GitHub: tenant semantics repo<br/>(private)"]
  S3[("S3-compatible<br/>backup target")]
  CLI["Integrators and operators<br/>(REST, MCP)"]
  subgraph VM["Tenant server: one VM per customer"]
    PX["Coolify proxy<br/>(TLS, routing)"]
    subgraph PRJ["Coolify project: tenant"]
      subgraph RES["Docker Compose resource (ns-core)"]
        API["api :8080"]
        RUN["runner"]
        PG[("postgres :5432")]
      end
    end
    EDGE["chat edge (stub)"]
    LLM["model plane (stub)"]
  end
  CP -->|manages server, deploys resource| RES
  GHC -->|cloned by Coolify, images built on deploy| RES
  CLI -->|HTTPS api.{tenant-domain}| PX --> API
  API --> PG
  RUN --> PG
  RUN -->|read-only deploy key| GHS
  PG -->|Coolify scheduled backup| S3
  RUN -->|ns-core backup| S3
  RUN -.->|outbound heartbeat, off by default| TCP
  EDGE -.->|/mcp via public URL| PX
  EDGE -.-> LLM
```

*Caption: one Coolify control plane manages many tenant servers; each tenant server runs one Core compose resource whose only public surface is `api` behind the Coolify proxy. Dashed edges are stubs or optional.*

- **Coolify control plane:** Narrowstack's Coolify instance. A multi-tenant control plane is allowed; the client data plane is single-tenant, one VM per customer (tenancy and isolation, ADR-003 in [decisions.md](../decisions.md)). Substrate is Coolify on Hetzner (D7).
- **Server:** each tenant VM is a Coolify server. Cloud provisions the VM; Core consumes it ([roadmap W2](../../product/roadmap.md)).
- **Project:** one Coolify project per tenant, holding one Docker Compose resource. Stubs, when activated, become separate resources in the same project (proposed, P6).

## Resource settings

| Setting | Value |
|---|---|
| Resource type / build pack | Docker Compose |
| Repository | `Narrowstack/narrowstack-core` at a release tag (the Core version pin) |
| Base directory | `/` |
| Docker Compose location | `compose/local-warehouse/docker-compose.yml` |
| Compose project name | `ns-core` (set in the file) |
| Domain | `api` service only (see [Domain and proxy](#domain-and-proxy)) |

Coolify combines base directory and compose location to find the file ([Coolify compose build pack](https://coolify.io/docs/applications/build-packs/docker-compose)). It clones the repo and builds the `runner` and `api` images from their build contexts on every deploy, tagged `ns-core-runner:${NS_CORE_VERSION}` and `ns-core-api:${NS_CORE_VERSION}` (images build during the Coolify deploy, CORE-DEP-07). The file uses standard Compose keys only (standard Compose keys only, CORE-DEP-03).

## Services

This table is the owning reference for per-service settings. Values are derived from [docker-compose.yml](../../../compose/local-warehouse/docker-compose.yml); if they disagree, the compose file wins and this table is the bug.

| Service | Image / build | Port | Public? | Volumes | Health check (interval / timeout / retries / start period) | Depends on |
|---|---|---|---|---|---|---|
| `postgres` (the warehouse) | `pgvector/pgvector:0.8.6-pg16` | 5432 (internal) | No | `pgdata` (rw) | `pg_isready` for the configured user and database (10s / 5s / 10 / 20s) | none |
| `runner` | build `runner/Dockerfile`, context repo root; image `ns-core-runner:${NS_CORE_VERSION}` | none | No | `semantics`, `artifacts`, `state` (rw) | `ns-core status --healthcheck`: an active, last-good generation exists (30s / 10s / 3 / **30m**) | `postgres` healthy |
| `api` | build `api/Dockerfile`, context repo root; image `ns-core-api:${NS_CORE_VERSION}` | 8080 (`expose` only) | **Yes**, via Coolify proxy | `artifacts` (ro), `state` (ro) | `GET /readyz` via curl: generation loaded and ACL self-test passed (15s / 5s / 3 / 60s) | `runner` healthy |

All three use `restart: unless-stopped`; `runner` has `stop_grace_period: 2m` so a running refresh can stop cleanly.

### Env each service receives

Each service receives only the secrets it needs (least-privilege secrets, CORE-SEC-03). Secrets are shown as *container name ← Coolify variable*.

| Service | Secrets | Non-secret config |
|---|---|---|
| `postgres` | `POSTGRES_PASSWORD` ← `SERVICE_PASSWORD_64_POSTGRES` | `POSTGRES_DB` ← `PG_DATABASE`, `POSTGRES_USER` ← `PG_SUPERUSER` |
| `runner` | `PG_SUPERUSER_PASSWORD` ← `SERVICE_PASSWORD_64_POSTGRES` (bootstrap stage only) · `DLT_PG_PASSWORD` ← `_LOADER` · `DBT_PG_PASSWORD` ← `_TRANSFORMER` · `MF_PG_PASSWORD` ← `_QUERY` · `API_RO_PG_PASSWORD` ← `_APISTATE` · `NS_SEMANTICS_DEPLOY_KEY_B64` · `BACKUP_S3_ACCESS_KEY_ID`, `BACKUP_S3_SECRET_ACCESS_KEY` · each enabled source's `SOURCES__<SOURCE>__<KEY>`, listed explicitly | `NS_TENANT_ID`, `NS_CORE_VERSION`, `NS_LOG_LEVEL`, `NS_STATE_DIR`, `NS_ARTIFACTS_DIR`, `NS_SEMANTICS_DIR`, `NS_SEMANTICS_REPO`, `NS_SEMANTICS_REF`, `NS_MANIFEST_PATH`, `PG_HOST`, `PG_PORT`, `PG_DATABASE`, `PG_SUPERUSER`, `NS_REFRESH_SCHEDULE`, `NS_AUTO_ROLLBACK`, `NS_GENERATIONS_RETAINED`, `NS_CORE_API_URL` (`http://api:8080`), `BACKUP_TARGET`, `NS_BACKUP_SCHEDULE`, `NS_CONTROL_PLANE_ENABLED` |
| `api` | `MF_PG_PASSWORD` ← `_QUERY` · `API_RO_PG_PASSWORD` ← `_APISTATE` · `NS_CORE_TOKEN_PEPPER` ← `SERVICE_PASSWORD_64_TOKENPEPPER` | `SERVICE_URL_API_8080` (bare declaration), `NS_CORE_PUBLIC_URL` ← `SERVICE_URL_API`, `NS_TENANT_ID`, `NS_CORE_VERSION`, `NS_LOG_LEVEL`, `NS_STATE_DIR`, `NS_ARTIFACTS_DIR`, `PG_HOST`, `PG_PORT`, `PG_DATABASE`, `NS_CORE_TOKEN_MAX_TTL_DAYS`, `NS_CORE_OIDC_ISSUER` and `NS_CORE_OIDC_AUDIENCE` (stub) |

`_LOADER` and the like abbreviate `SERVICE_PASSWORD_64_LOADER` and so on. Role meanings are in [access-control.md](./access-control.md); the full env contract, defaults, and state files are in [interface-contracts.md](./interface-contracts.md).

**Must never appear in `api`:** superuser, loader, or transformer passwords, any `SOURCES__*` variable, the semantics deploy key, or backup keys (API holds only query and API-state roles, CORE-ACC-09; source credentials reach only the runner, CORE-PIPE-06). This is what keeps the warehouse DSN inside Core services (warehouse credentials never leave Core, INV-2).

**Why the runner holds every role password:** the bootstrap stage creates and alters every role, and the ACL smoke and smoke query stages run as the query role through the same enforcement library the API uses ([runtime-flows.md](./runtime-flows.md)).

## Environment entry in Coolify

- **Runtime-only.** Enter every variable in the resource's Environment Variables UI with the build-time flag off, so no secret lands in an image layer (secrets are runtime env only, INV-11, CORE-SEC-02). Coolify variables carry independent runtime and build-time flags, both on by default ([Coolify env var docs](https://github.com/coollabsio/coolify-docs/blob/main/content/docs/knowledge-base/environment-variables.mdx)).
- **Magic variables.** `SERVICE_PASSWORD_64_*` and `SERVICE_URL_*` are generated by Coolify on first deploy, reused everywhere they are referenced, and kept across redeploys ([Coolify compose magic variables](https://coolify.io/docs/knowledge-base/docker/compose)). That lets `runner` and `api` share `SERVICE_PASSWORD_64_QUERY` without a sync step. Confirmed for one-click templates ([LiteLLM template](https://github.com/coollabsio/coolify/blob/main/templates/compose/litellm.yaml)); unconfirmed for a git-sourced compose resource. **Fallback:** if a value is not generated, set it by hand under the same name.
- **Required variables.** Compose refuses to render without `NS_TENANT_ID`, `NS_SEMANTICS_REPO`, `NS_SEMANTICS_REF`, and `NS_SEMANTICS_DEPLOY_KEY_B64` (missing inputs fail loudly, CORE-DEP-06).
- **Source credentials.** Add each `SOURCES__<SOURCE>__<KEY>` in Coolify **and** list it under `runner` in the compose file. Both steps are needed.
- **Pins must agree.** `NS_TENANT_ID` must equal manifest `tenant_id` and `NS_SEMANTICS_REF` must equal manifest `semantics_ref`; green-check stage 3 fails and names the field otherwise.
- **Access setup is optional but strongly advised.** Without a manifest `access` block the API runs in open mode. The setup step (optional access-setup step, CORE-ACC-07) is described in [access-control.md](./access-control.md).

## Domain and proxy

- Only `api` gets a domain, for example `https://api.<tenant-domain>`. The bare `SERVICE_URL_API_8080` declaration tells Coolify to route a generated domain to port 8080 of `api`; the proxy terminates TLS ([Coolify compose magic variables](https://coolify.io/docs/knowledge-base/docker/compose)). `NS_CORE_PUBLIC_URL` picks up the resulting `SERVICE_URL_API`.
- No service has `ports:` (only the API is published, INV-10, CORE-SEC-01). Coolify's guidance is the same: a published host port bypasses the proxy and can expose an internal service ([Coolify compose docs](https://coolify.io/docs/knowledge-base/docker/compose)).
- The resource gets its own Docker network; the Coolify proxy joins it to reach `api` ([Coolify networking](https://next.coolify.io/docs/core/networking-in-coolify)). Leave "Connect To Predefined Network" off so `postgres` and `runner` stay unreachable from other resources.

## Health and startup timing

Startup order is warehouse healthy, then runner healthy, then API (startup order, CORE-DEP-05), enforced by `depends_on: condition: service_healthy`. The API never accepts traffic before an active generation exists.

| Situation | Runner state | API |
|---|---|---|
| First deploy, bootstrap running | starting (up to the 30m start period) | not started |
| First deploy, green-check failed (no last-good) | unhealthy | never starts; deploy shows failed (rollback-first, CORE-GEN-06) |
| Redeploy or refresh, new generation failed | healthy, reporting `degraded`, serving last-good | keeps serving last-good (last-good generation always kept, INV-8) |
| Healthy | healthy | ready after `/readyz` self-test |

- The 30m runner start period exists because the first bootstrap loads every source and builds the first generation before a last-good generation exists. Whether Coolify's deploy step waits that long is unverified (see [Verify on first deploy](#verify-on-first-deploy)).
- Health endpoints expose no instance detail (health endpoints, CORE-API-08).
- Why a long-lived runner instead of a one-shot init container (proposed, P3): [system-architecture.md](./system-architecture.md).
- The `api` health check calls `curl`, so the Phase B `api` image must ship it.

## Volumes

| Volume (plain name) | Mounted by | Holds | Covered by Coolify DB backup? |
|---|---|---|---|
| `pgdata` | `postgres` (rw) | the warehouse, including `ns_core` state (token hashes, audit log, generation pointer) | Yes (the database dump) |
| `semantics` | `runner` (rw) | git checkout of the semantics repo at `NS_SEMANTICS_REF` | No; re-cloned |
| `artifacts` | `runner` (rw), `api` (ro) | per-generation dbt `manifest.json` and `semantic_manifest.json` | No; rebuilt |
| `state` | `runner` (rw), `api` (ro) | `active-manifest.json`, generation records, gate reports | No |

Inside containers they mount under `/var/lib/ns-core/`. Coolify prefixes deployed volume names with a resource identifier and does not document the format ([Coolify persistent storage](https://next.coolify.io/docs/services/configuration/persistent-storage)). **Never hardcode the prefixed name** in scripts, the manifest, or docs; manifest `warehouse.volume: pgdata` is the plain name. Read the deployed names from Coolify's "Show Deployable Compose" view or Persistent Storage page when a restore needs them.

## Backups

- **Platform backup (proposed, P15):** configure a Coolify scheduled backup on the `postgres` service inside the compose resource: cron, retention (match manifest `backup.retention_days`), S3-compatible destination. Coolify supports this for a database inside a compose stack and reads its credentials from the running container's env ([Coolify backups](https://coolify.io/docs/databases/backups)). Backup to an S3 target on a schedule is CORE-OPS-02.
- **Core snapshots:** the runner's cron runs `ns-core backup` at `NS_BACKUP_SCHEDULE` to `BACKUP_TARGET` (manifest `backup.target_env`).
- **Restore is scripted.** Coolify's restore UI works only for standalone database resources, not a database inside a compose resource ([coolify#7529](https://github.com/coollabsio/coolify/issues/7529)). Restore is `ns-core restore` (scripted restore, CORE-OPS-03): restore the warehouse, then re-run bootstrap at the pinned inputs, which re-clones `semantics`, rebuilds `artifacts`, rewrites `state`, and re-creates roles and grants from the env values. The acceptance test is destroy, restore, and the PRD step-6 question returning the step-4 number; the sequence is in [runtime-flows.md](./runtime-flows.md).

## Upgrades and rollback

- **Upgrade (CORE-OPS-04):** change the resource's git ref to the new Core release tag and `NS_CORE_VERSION` to match, and/or change `NS_SEMANTICS_REF` (with the manifest's `semantics_ref` at that ref matching it). Redeploy. Green-check runs against this tenant's data before anything publishes.
- **Automatic rollback:** a failed gate keeps or restores the last-good generation unless `NS_AUTO_ROLLBACK=0` (CORE-GEN-06; rollback-first, D11). Generation mechanics are in [system-architecture.md](./system-architecture.md).
- **Operator rollback:** revert the pins in Coolify and redeploy, or switch data only with `ns-core generations activate <N>` (switch to a retained generation, CORE-GEN-07).
- **Do not use Coolify's rollback button.** It redeploys an older image with the current runtime config and does not restore volumes or database state ([Coolify rollbacks](https://next.coolify.io/docs/applications/deployments/rollbacks)); on compose it can redeploy latest instead ([coolify#8445](https://github.com/coollabsio/coolify/issues/8445)).
- **No rolling updates.** Coolify does not support rolling updates for Docker Compose ([Coolify rolling updates](https://coolify.io/docs/knowledge-base/rolling-updates)). Expect `api` to be unavailable while containers are recreated. Because the runner's health check passes once a last-good generation exists, the gap should be the container recreate plus `/readyz`, not a full bootstrap (derived from the health definition; verify).

## Private semantics repo access

- Coolify deploy keys are one key per repository and cover only Coolify's own clone during build; they are not a credential inside a running container ([Coolify deploy keys](https://coolify.io/docs/applications/ci-cd/github/deploy-key)). No Coolify feature clones a second private repo at runtime.
- So the runner clones the tenant semantics repo itself (proposed, P8) with `NS_SEMANTICS_DEPLOY_KEY_B64`: base64 of a GitHub deploy key, read-only, added to that one repo only (read-only single-repo key, CORE-SEC-04; clone at pinned ref, CORE-PIPE-01). The key generation command is in [.env.example](../../../compose/local-warehouse/.env.example).
- `NS_SEMANTICS_REPO` is the SSH URL, for example `git@github.com:Narrowstack/<tenant>-semantics.git`.
- Alternative: a GitHub App installation token. Deploy key vs GitHub App is an open question.

## Sizing

- The example manifest uses `vm_size_class: standard-4x16` (4 vCPU, 16 GB). Core alone is expected to fit comfortably; this is an estimate, not a measurement.
- Disk: plan for the manifest's `volume_ceiling_gb` for raw loads plus roughly 2x mart storage if blue/green generation schemas are adopted (proposed, P4).
- Stubs add their own resources when activated; their co-residency budget is tracked in [edge-stubs.md](./edge-stubs.md).

## What Coolify does, what Core does

| Concern | Coolify | Core |
|---|---|---|
| Clone Core repo, build images | Yes, on every deploy | Provides `runner/` and `api/` build contexts (Phase B) |
| Clone tenant semantics repo | No | Runner, with its own read-only key |
| Secrets entry and generation | Env UI, magic variables | Declares names; manifest carries names only |
| Public domain and TLS | Proxy, via `SERVICE_URL_API_8080` | Exposes only `api:8080` |
| Service health and restarts | Runs compose health checks and restart policy | Defines what healthy means (last-good generation, `/readyz` self-test) |
| Deploy gate | No | Green-check inside the runner |
| Scheduled refresh | No | supercronic in the runner at `NS_REFRESH_SCHEDULE` |
| Rollback | Image-only button; not used | Generation pointer, pin revert, redeploy |
| Database backup | Scheduled dump to S3 | `ns-core backup` snapshots |
| Restore | No (compose-embedded DB) | `ns-core restore` |
| Access control | No | Modeling API (the front door and bouncer) |
| Logs | Log view per service | Logs to stdout/stderr; gate reports in `state` (CORE-OPS-06) |

## Verify on first deploy

Every item below is unverified Coolify behavior the design depends on. Record the result in [decisions-and-open-questions.md](./decisions-and-open-questions.md).

- [ ] **Magic variables on a git-sourced compose resource.** All six `SERVICE_PASSWORD_64_*` values and `SERVICE_URL_API` are generated, identical in every service that references them, and unchanged after a redeploy. If not: set by hand under the same names.
- [ ] **Per-container env scope.** Coolify writes runtime variables to a `.env` loaded through Compose's env file mechanism ([Coolify env var model](https://deepwiki.com/coollabsio/coolify/5.3-environment-variables-and-build-secrets)). Check whether every resource variable lands in every container: inspect `api`'s env for superuser, loader, transformer, `SOURCES__*`, deploy key, and backup keys. Any hit breaks CORE-SEC-03; mitigation is an open question.
- [ ] **`$$` escaping.** The `postgres` health check uses `$${POSTGRES_USER}` and `$${POSTGRES_DB}`. Confirm Coolify passes them to the container as literal `${...}` and the service turns healthy. Coolify has reported `$` handling problems ([coolify#6395](https://github.com/coollabsio/coolify/issues/6395)).
- [ ] **Required-variable syntax.** Confirm Coolify handles `${VAR:?message}`: a missing required variable blocks the deploy and names it, rather than rendering an empty or literal value.
- [ ] **Build contexts.** `runner` and `api` use context `../..` relative to the compose file (the repo root). Coolify may resolve build contexts relative to the base directory instead ([Coolify compose build pack](https://coolify.io/docs/applications/build-packs/docker-compose), confidence "likely"). Confirm both images build from the pinned tag.
- [ ] **Deploy timeout vs first bootstrap.** Confirm whether Coolify's deploy waits out the runner's 30m start period, times out, or reports success before `api` starts. Open question.
- [ ] **Domain.** Assigning `api.<tenant-domain>` to `api` updates `SERVICE_URL_API` and issues TLS; `/healthz` answers over HTTPS.
- [ ] **No other exposure.** An external scan of the VM finds only the proxy (CORE-SEC-01).
- [ ] **Volume names.** Record the prefixed names from "Show Deployable Compose" for the restore runbook.
- [ ] **Backup.** One scheduled backup of `postgres` completes and the object appears in the S3 target.
- [ ] **Control plane independence.** With the Coolify control plane unreachable, the instance keeps serving and refreshing (no inbound dependency on Narrowstack, INV-9; off by default, CORE-TEL-01).

## Local parity

- The same file runs locally. `docker compose --env-file .env.example config --quiet` must exit 0 (CORE-DEP-03).
- No ports locally either. Reach services with `docker compose exec`: the CLI in `runner`, `/readyz` from inside `api`.
- Locally nothing generates magic variables, and there is no proxy, TLS, or Coolify backup. Fill `SERVICE_PASSWORD_64_*` by hand in a gitignored `.env`.
- Steps: [compose/local-warehouse/README.md](../../../compose/local-warehouse/README.md).

## External-warehouse mode (stub, W6)

[compose/external-warehouse/](../../../compose/external-warehouse/docker-compose.yml) stays a placeholder for the deferred external-warehouse wave (W6). The intended shape: the same `runner` and `api` images against the customer's warehouse via the DSN named in manifest `warehouse.external_dsn_env` (example: `WAREHOUSE_DSN`), no `postgres` service, and no Coolify database backup because the customer owns the warehouse. Not part of the first deployment.

## Open questions from this doc

Tracked in [decisions-and-open-questions.md](./decisions-and-open-questions.md):

1. G8 sign-off scope for a Core-only Phase B slice (blocks the first deploy).
2. Coolify deploy timeout vs the 30m first bootstrap.
3. Mitigation if Coolify injects every resource variable into every container.
4. Build context resolution (`../..` vs base directory).
5. Which backup `ns-core restore` reads: the Coolify dump, the `ns-core backup` snapshot, or either; and whether both schedules run.
6. Keeping the resource git ref and `NS_CORE_VERSION` in step: nothing enforces that they match.
7. Which Hetzner server type `standard-4x16` maps to, and who provisions and registers the server in Coolify.
8. Runner behavior after a failed first bootstrap under `restart: unless-stopped`: does it stay up unhealthy or restart and re-run the full bootstrap?
9. Semantics repo credential: deploy key vs GitHub App.

## Related

[README.md](./README.md) · [system-architecture.md](./system-architecture.md) · [access-control.md](./access-control.md) · [runtime-flows.md](./runtime-flows.md) · [interface-contracts.md](./interface-contracts.md) · [edge-stubs.md](./edge-stubs.md) · [requirements.md](./requirements.md) · [decisions-and-open-questions.md](./decisions-and-open-questions.md) · canon: [packaging.md](../packaging.md), [local-warehouse-deploy](../../features/local-warehouse-deploy.md), [rollback-deploy](../../features/rollback-deploy.md)
