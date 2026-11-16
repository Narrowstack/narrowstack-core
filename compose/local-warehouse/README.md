# compose/local-warehouse — Core full instance

**What this is:** the one compose file for a full Core instance (`warehouse.mode: local`): the warehouse, the pipeline runner, and the Modeling API that is Core's front door and bouncer. It is the shared spine of Variant A (chat edge) and Variant C (headless). Variant C is served directly by this stack through its API, MCP endpoint, and CLI. Variant A adds a chat edge later, as a separate resource.

> **Status: proposed spec stub (2026-09-22). Not deployable yet.** The `runner/` and `api/` build contexts arrive in Phase B, the build phase, which waits on operator sign-off (G8 in `docs/process/wave-review-gate.md`). Today only `postgres` can start, and `docker compose config` validates the whole file. Commands below marked *(Phase B)* don't exist yet.

Architecture depth lives in [`docs/architecture/core-runtime/`](../../docs/architecture/core-runtime/README.md). Coolify specifics: [`deployment-coolify.md`](../../docs/architecture/core-runtime/deployment-coolify.md).

## Services

| Service | Role | Public |
|---|---|---|
| `postgres` | Warehouse. Postgres 16 with pgvector available; the extension stays off until the knowledge plane is activated | No |
| `runner` | Runs green-check on deploy, publishes a numbered generation (or keeps the last-good one), then runs scheduled refreshes (dlt, then dbt, then MetricFlow). Hosts the `ns-core` CLI | No |
| `api` | Modeling API (`/v1`) and MCP (`/mcp`) in one process. Enforces access and row scoping for every metric read, CLI included | Yes, through Coolify's proxy |

Startup order: `postgres` healthy, then `runner` healthy, then `api`. The API never serves before a generation is active.

**Not in this file, on purpose.** The chat edge (Open WebUI or LibreChat), the model plane (LiteLLM), and the knowledge plane are stubs, off the initial execution path. When activated, each runs as its own Coolify resource on the same tenant server. See [`edge-stubs.md`](../../docs/architecture/core-runtime/edge-stubs.md).

## Instance setup (Coolify)

1. **Prerequisites.**
   - A tenant server in Coolify (one VM per customer).
   - The tenant semantics repo with `deploy/manifest.yaml`, tagged at the ref you'll deploy.
   - A GitHub **read-only deploy key** on that semantics repo only.
   - Optional: an S3-compatible bucket for backups.
2. **Create the resource.** New Docker Compose resource from `Narrowstack/narrowstack-core` at a release tag, with base directory `/` and compose location `compose/local-warehouse/docker-compose.yml`.
3. **Environment.** Enter every variable from [`.env.example`](./.env.example) as a runtime-only value (build-time flag off).
   - `[required]` values: tenant id, semantics repo, ref, and base64 deploy key.
   - `[generated]` values (`SERVICE_PASSWORD_*`, `SERVICE_URL_API`): Coolify fills these. On the first deploy, confirm it did. If it didn't, set them by hand.
4. **Domain.** Assign a domain to `api` only. No other service gets one.
5. **Access setup: optional, strongly advised.** Add an `access` block (mode `token`) and principals to the tenant manifest, then deploy. Then run *(Phase B)*:

   ```bash
   docker compose exec runner ns-core access setup
   ```

   This verifies the mode, runs the ACL smoke test, and prints the first operator token once.

   > **Skipping this step leaves the API in open mode.** Anyone who can reach the domain can query every allowlisted metric, and row scoping is off. Open mode stays possible but is strongly advised against. Every response carries `X-NS-Core-Access-Mode: open`, and `ns-core status` shows a red banner until access is set up. The allowlist and warehouse role grants still apply in open mode.

6. **Deploy and verify.** Watch the runner log walk the green-check stages. Then, *(Phase B)*:

   ```bash
   docker compose exec runner ns-core status
   ```

   ```bash
   docker compose exec runner ns-core query --token "$NS_CORE_TOKEN" <metric>
   ```

   Pass: the number matches the tie-out, with its SQL shown.

## Local validation

```bash
cp .env.example .env
```

```bash
docker compose --env-file .env config --quiet
```

No ports are published, by design. Once the Phase B images exist, reach services with `docker compose exec`, for example `docker compose exec api curl -s localhost:8080/readyz`. For a local-only published port, use an untracked override file. Never commit a `ports:` entry here.

## Day-two operations *(Phase B)*

| Task | Command |
|---|---|
| Instance status, pins, generation, access mode | `ns-core status` |
| Run a refresh now | `ns-core refresh` |
| List or switch generations | `ns-core generations list` · `ns-core generations activate <N>` |
| Roll back to the previous pins | `ns-core rollback` (or revert the tag / `NS_SEMANTICS_REF` in Coolify and redeploy) |
| Issue or revoke a principal token | `ns-core access token issue <principal> --ttl 30d` · `ns-core access token revoke <id>` |
| Backup / restore | `ns-core backup` · `ns-core restore` (scripted; Coolify's restore UI does not cover databases inside a compose resource) |

Run each as `docker compose exec runner ns-core …` locally, or from the resource terminal in Coolify.

**Upgrades:** change the Core release tag and/or `NS_SEMANTICS_REF`, then redeploy. Green-check gates the change, and a failure keeps the last-good generation serving. Details: [`runtime-flows.md`](../../docs/architecture/core-runtime/runtime-flows.md).

## References

- Requirements: [`requirements.md`](../../docs/architecture/core-runtime/requirements.md)
- Access model: [`access-control.md`](../../docs/architecture/core-runtime/access-control.md)
- Env contract: [`interface-contracts.md`](../../docs/architecture/core-runtime/interface-contracts.md)
- Feature spec: [`local-warehouse-deploy.md`](../../docs/features/local-warehouse-deploy.md)
