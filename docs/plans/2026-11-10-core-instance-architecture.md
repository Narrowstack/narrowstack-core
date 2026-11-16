# Core template and instance architecture (v1)

> Status: decided, 2026-11-10. Revised the same day: repo names, push-on-merge, Metabase MCP only.
> Work status lives in Linear (project *Narrowstack Core (Stackflow)*), not here.
> Supersedes [2026-10-02-core-template-instance-split.md](./2026-10-02-core-template-instance-split.md) for deploy shape, naming, and access. That plan's N-stack and C-stack PR sequence stands, with the [deltas](#deltas-to-the-2026-10-02-pr-sequence) below.

**Summary.**
- The runtime image is a versioned toolchain. It is built once per template tag and pulled from GHCR. Instance deploys never build it.
- A merge to instance `main` pushes an apply to the box. The box does not poll git. The apply checks out that SHA and runs dbt and the Metabase sync. It does not rebuild the image or recreate containers.
- Data is never in the image or in git. Data refresh stays on a schedule. Code promotion does not.
- Postgres is the only v1 policy engine: two writer roles, three read tiers, RLS keyed off `current_user`.
- v1 ships Metabase's own MCP. No custom MCP.
- Pilot: Coolify on a box, with a dedicated preexisting Supabase project as the warehouse.

## Naming

| Thing | Name |
|---|---|
| Template (public) | `core` |
| Instance repo | `<company>-core` |
| Dogfood instance | `narrowstack-core` |
| Customer example | `acme-core` |

`narrowstack-core` today is the template. It vacates that name when it is renamed to `core`. The dogfood instance takes `narrowstack-core` only after that rename. Until then the instance repo is still `nsportal-dbt`, with `narrowstack-semantics` as the donor. Do not rename either GitHub repo until the fold is on `main` and a Coolify deploy from `main` has passed. GitHub redirects the old template URL after the rename. Update Coolify's repo source in the same step. It matches on the repo name.

Rejected: `narrowstack-core-hq`, `narrowstack-core-<slug>`, `narrowstack-warehouse`, `nsportal-dbt` and `narrowstack-semantics` as long-term names.

## Shape

```mermaid
flowchart LR
  classDef code fill:#eef4ff,stroke:#3b5bdb,color:#1c2b5a
  classDef data fill:#e8f7ee,stroke:#2f855a,color:#123d24
  classDef writer fill:#fff0f0,stroke:#c92a2a,color:#5a1414
  classDef reader fill:#fff7e6,stroke:#b7791f,color:#3d2c06

  T["core (template)<br/>dbt package, CI, Dockerfile"]:::code
  G["GHCR<br/>runtime image :vX.Y.Z"]:::code
  I["company-core (instance)<br/>models, semantic YAML, dlt pipelines,<br/>Metabase specs, RLS scope rows, deploy/**"]:::code
  GA["Instance CI<br/>on merge to main"]:::code

  T -->|"tag: template CI builds + pushes"| G

  subgraph BOX["Coolify box"]
    R["runner<br/>apply SHA, dlt, dbt, access apply, data cron, run lock"]:::writer
    MB["metabase<br/>upstream image, pinned<br/>official MCP on the same app"]:::reader
    V[("volumes: src at SHA, run state")]:::data
    BP[("box Postgres 17<br/>Metabase app DB<br/>optional local warehouse")]:::data
  end

  W[("Supabase warehouse<br/>Data API off")]:::data

  G -->|"pull on deploy tag PR"| R
  I -->|"deploy/** recreates containers, no image build"| BOX
  GA -->|"webhook: apply this SHA"| R
  R --- V
  MB --- BP
  R -->|"ns_loader: raw_* only<br/>ns_transformer: build + grants"| W
  MB -->|"mb_ops / mb_finance / mb_people"| W
```

Red services write to the warehouse. Amber services read only, each login pinned to one tier.

## Image split

- **Runtime image (toolchain only).** Pinned dbt, dlt, MetricFlow, `ns-core` scripts, supercronic. Built in template CI on a template tag, pushed to GHCR. Coolify pulls it. An instance deploy never runs `docker build`.
- **Instance code (git, not image).** dbt models, semantic YAML, dlt pipelines, Metabase content specs, RLS scope rows. Merge to `main` tells the runner which SHA to check out. The runner records that SHA. This does not rebuild the image or recreate containers.
- **Data (never image, never git).** Warehouse data lives in Supabase (pilot) or an optional local Postgres volume. Metabase's application DB lives in a box Postgres volume and survives image rebuilds.
- **New Python dependency** is the one instance-driven change that needs a template image bump. No runtime `pip install` in v1.
- **Metabase** is the upstream image pinned to an exact version. Not `:latest`, not baked into the runtime image. Its official MCP is part of that app. There is no second MCP service.

| Component | Lives in | Updated by | Survives image rebuild |
|---|---|---|---|
| Runtime image | template repo, GHCR | template tag, then instance deploy tag PR | n/a |
| Metabase binary | upstream image, pin in `deploy/**` | pin bump PR | n/a |
| Compose, image pins | instance `deploy/**` | PR to `deploy/**` | yes (git) |
| Models, semantics, pipelines, Metabase specs, RLS scope rows | instance repo, `src` volume at SHA | merge to `main` pushes apply | yes |
| Warehouse data | Supabase or local Postgres volume | dlt + dbt runs | yes |
| Metabase app DB | box Postgres volume | Metabase | yes |
| Run state (lock, recorded SHA, last run) | runner volume | runner | yes |
| Secrets | Coolify runtime env | operator | yes (never in image) |

| Change | Trigger | Containers recreated |
|---|---|---|
| Template tag | template CI builds and pushes image | none on instances |
| Deploy tag PR (image pin in `deploy/**`) | Coolify redeploy, pulls image | yes |
| Metabase pin or compose change in `deploy/**` | Coolify redeploy | yes |
| Coolify env or secret change | operator redeploy | yes |
| Models, semantics, pipelines, Metabase specs, RLS scope rows | instance CI webhook, apply that SHA | no |
| New Python dependency | template change, tag, deploy tag PR | yes |
| Data refresh | supercronic in runner, recorded SHA only | no |

## Runtime flows

```mermaid
sequenceDiagram
  autonumber
  participant TR as Template repo
  participant CI as Template CI
  participant GH as GHCR
  participant IR as Instance repo
  participant CF as Coolify
  participant RN as Runner
  participant WH as Warehouse
  participant MB as Metabase

  Note over TR,GH: Template tag release (the only docker build)
  TR->>CI: push tag vX.Y.Z
  CI->>GH: build + push runtime image vX.Y.Z
  IR->>CF: merge deploy tag PR (deploy/**)
  CF->>GH: pull vX.Y.Z
  CF->>RN: recreate runner, mcp

  Note over IR,MB: Model, pipeline, or dashboard merge (no container recreate)
  IR->>IR: merge to main (non-deploy paths)
  IR->>RN: CI webhook, apply this SHA
  RN->>IR: fetch that SHA (read-only deploy key)
  RN->>RN: take run lock, check out SHA in src
  RN->>WH: dbt build as ns_transformer, apply_rls post-hook, ACL probe
  RN->>MB: upsert the managed Metabase collection
  RN->>RN: record SHA on success, release lock

  Note over RN,WH: Data refresh (no git fetch)
  RN->>RN: take run lock, use recorded SHA
  RN->>WH: dlt load as ns_loader into raw_*
  RN->>WH: dbt build as ns_transformer, apply_rls, ACL probe
  RN->>RN: release lock
```

- **Apply** runs when instance CI calls the runner with a SHA. The runner fetches that SHA. It does not poll. On failure the previous SHA stays recorded and keeps serving.
- **Data refresh** runs dlt then dbt at the recorded SHA. It never fetches git.
- **Failure leaves last-good tables.** dbt replaces a table only when its build succeeds; failed and downstream models keep their previous relations. A failed ACL probe fails the run.
- **Run lock** serializes apply and data refresh.

Rollback:
- Models: revert the commit on `main`. That merge pushes another apply.
- Image: revert the deploy tag PR.
- Do not use Coolify's rollback button. It redeploys an older image with current config and restores no volume or database state.

## Access (v1)

Postgres is the only policy engine. Same SQL on box Postgres 17 and Supabase.

| Role | Kind | Can |
|---|---|---|
| `ns_loader` | runner login | write `raw_*` only |
| `ns_transformer` | runner login | build models, apply grants and RLS |
| `read_ops` < `read_finance` < `read_people` | NOLOGIN tier groups | read marts in their tier and below |
| `mb_ops`, `mb_finance`, `mb_people` | Metabase logins, one per tier | read one tier |

- Tier names come from instance config. The mechanism ships in the template dbt package.
- Reader logins are members of exactly one tier, with `default_transaction_read_only` and a statement timeout.
- Metabase gets one connection per tier because Metabase OSS cannot impersonate.
- RLS inside a tier keys off `current_user` via `acl.principal_scope`, loaded from the instance's RLS scope rows.
- The dbt `apply_rls` post-hook recreates policies after every rebuild. The ACL probe fails the run if a policy is missing.
- The admin DSN is used only by `ns-core access apply`.
- `staging`, `raw_*`, and `etl_*` are never granted to readers.
- Supabase: Data API off on the warehouse project. `service_role` and the anon key are never placed in Coolify, dbt, or Metabase. Supabase Auth users are not warehouse roles.
- Metabase's MCP authenticates as a Metabase user. That user's group selects the tier connection. There is no warehouse login for the MCP.

## Trust zones and invariants

- **Box:** runner, Metabase (including its MCP), box Postgres. The only place warehouse credentials exist.
- **Warehouse:** Supabase project (or local volume). Reached only with per-role credentials.
- **GitHub:** template and instance code. No data, no secrets.
- **Operator:** Coolify env UI and the admin DSN.

Invariants:
- Warehouse credentials stay on the box.
- One credential per role. No shared logins.
- No host ports. The warehouse is never published. Metabase and its MCP route only through the Coolify proxy with TLS.
- Secrets are runtime env only, never in an image layer or git.

## Coolify notes

- **Per-service env.** List each variable only under the service that needs it. Writer passwords and source credentials reach only `runner`. Verify Coolify does not inject every resource variable into every container.
- **Runtime-only.** Turn the build-time flag off on every variable.
- **`$$` and required vars.** Escape literal `${...}` in compose health checks as `$${...}`. Use `${VAR:?message}` for required variables and confirm a missing one blocks the deploy.
- **Private instance repo.** Coolify's deploy key covers its clone of `deploy/**`. The runner needs its own read-only deploy key, scoped to the instance repo, to fetch the SHA a merge names.
- **Watch paths.** Coolify recreates containers only when `deploy/**` changes. Every other merge to `main` is an apply webhook. The webhook carries the SHA and an HMAC. The runner rejects anything else. There is no scheduled git fetch.
- **Restore caveat.** Coolify's restore UI does not handle a database inside a compose resource. Restore of the box Postgres is scripted.
- **Restore drill (v1).** Restore the Metabase app DB and warehouse, fetch code at the recorded SHA, run `ns-core access apply` and a dbt build, and confirm a known question returns the pre-restore number.

First deploy checklist:
- [ ] Only the variables each service needs appear in its container env.
- [ ] `$$` escapes reach the container as literal `${...}`; health checks pass.
- [ ] A missing required variable blocks the deploy and names it.
- [ ] Runner fetches the private instance repo with its own key, only for a SHA the webhook names.
- [ ] A non-`deploy/**` merge does not recreate containers. It does call apply.
- [ ] A webhook with a bad HMAC does not check out anything.
- [ ] External scan finds only the proxy.
- [ ] One scheduled box Postgres backup lands and one restore drill passes.

## Pilot deploy

- Coolify on a box.
- Warehouse: preexisting dedicated Supabase project, not the app's Supabase project.
- Optional local Postgres warehouse stays a supported template mode, with the same role SQL.

## Metabase: git and the MCP

Two zones in one Metabase:

| Zone | Source of truth | Apply on merge | MCP and the UI |
|---|---|---|---|
| Managed collection | instance repo `metabase/` | upsert by stable id | read. Writes here are drift and the next apply overwrites them |
| Sandbox collection | Metabase app DB | never touched | read and write. Questions, drafts, MCP edits live here |

Promotion is a pull request, not a sync job. Someone exports the sandbox change into `metabase/` (the official serialization export on a paid plan, or a reviewed dump of the API objects on OSS). Merge to `main` upserts it into the managed collection. The sandbox copy can then be archived.

v1 ships Metabase's official MCP, aimed at the sandbox for writes and at the managed collection for reads. It does not ship a custom warehouse MCP.

Leaving the MCP out would keep git clean and drop the way an agent asks questions of the dashboards. Leaving git out would make the next person's laptop the source of truth. Both stay, with the write target split as above.

Do not point a write-capable MCP at the managed collection on the production app. The next apply will either clobber that work or the repo will stop matching production.

## Publishing the runtime image

The template workflow publishes `ghcr.io/narrowstack/core` with the built-in `GITHUB_TOKEN`. A personal token is the fallback when a person has to push an image by hand.

Org owner, once:

1. Org **Settings → Actions → General → Workflow permissions**: allow actions to request `packages: write`. The workflow must set that permission itself.
2. Org **Settings → Packages**: members may create packages. New packages inherit access from the source repo.
3. After the first push, open the package and set visibility to public if Coolify should pull without a credential. The template repo is public.

The workflow lives in `core` and requests `contents: read` plus `packages: write`. `GITHUB_TOKEN` from a fork pull request cannot publish. Tag pushes from `main` can.

If a person publishes by hand:

1. They are a member of the Narrowstack org. A personal account that is not a member can read public repos and will get a 404 on publish.
2. `gh auth refresh -s write:packages,read:packages`
3. Authorize that credential for the org's SSO. GitHub → **Settings → Developer settings → Personal access tokens** → **Configure SSO** → authorize Narrowstack. An unauthorized token looks like a missing package.
4. `docker login ghcr.io` with that token, then push.

Do not put a long-lived token in Coolify for the pull if the package is public.

## Cut from v1

Modeling API bouncer, principal tokens, OIDC, open mode, blue/green schema generations, pgvector, chat edge, telemetry, control-plane API, copier scaffold (until a second instance exists), manifest JSON schema, a custom MCP.

Kept: tier grants, two writer roles, `apply_rls`, push-on-merge apply, data-refresh cron, run lock, Metabase per-tier connections, Metabase's official MCP, restore drill.

## Deltas to the 2026-10-02 PR sequence

- **C1 (OS-589):** this doc plus the Oct 2 plan. System map, layers, and contributing docs come in later C-stack PRs from the chat branch corpus. The control-plane API proposal is out of v1.
- **C2:** adds the two writer roles, tier groups, reader login hardening, `acl.principal_scope`, `apply_rls`, the ACL probe, and `ns-core access apply` to the shared package.
- **C3 (scaffold):** deferred until a second instance exists. Package, reusable workflow, and image stay the consumption path.
- **C4 (runtime):** toolchain image built on tag and pushed to GHCR; apply webhook, data-refresh cron, run lock; pinned upstream Metabase and its official MCP. No custom MCP.
- **C5:** shrinks to `deploy/**` pins and the restore drill. Manifest schema, green-check generations, and snapshot scripts are out.
- **N6:** role names follow this doc (`ns_loader`, `ns_transformer`, `mb_*`). No `agent_cos` warehouse login in v1.
- **N8:** also adds `deploy/**` pinned to a GHCR image tag.
- **Row-level security** moves into v1 (Oct 2 listed it out of scope).

## Branch salvage

Record only. No branch is deleted in this change.

- `docs/core-template-split` (PR #7): merges now.
- `feat/chat-data-architecture`: corpus for later C-stack PRs, not this merge. Contains `develop` and OS-399.
- `develop`, OS-399: contained in the chat branch; cut later.
- OS-395: archive. Its unique file is an executed PR-split map.
- OS-396, OS-397, OS-398, `feat/core-iac-spec`: cut later (older copies).
- `feat/core-phase-g`: archive later.
- Meeting-intelligence scaffold: held, not in v1.
- `narrowstack-semantics`: donor. Archive the GitHub repo only after the port lands and only on explicit operator instruction.
- `nsportal-dbt`: becomes `narrowstack-core` only after the template repo has been renamed to `core`, the fold is on `main`, and a Coolify deploy from `main` has passed.

## core-runtime draft docs: disposition

The uncommitted core-runtime draft docs in the agent worktree are not committed as a branch. A human can remove that worktree once this is accepted.

- **Discard:** README (Phase G gate); access-control model (open mode, HMAC tokens, filter injection, leadership/team/agent tiers); edge stubs; interface contracts except env-name discipline; requirements as a parallel ledger; the decisions file as a file (content belongs in Linear); the compose rewrite (pg16, no Metabase, `api`/`runner` build contexts that do not exist); build-vs-buy chat surface doc; dbt logs.
- **Incorporated above:** trust zones and invariants; per-role credentials; no host ports; runtime-only secrets; Coolify per-service env, `$$` and required-var handling, runtime deploy key, restore caveat, first deploy checklist; apply, data refresh, and last-good failure flows.
- **Out of v1:** blue/green generations, pgvector, chat edge, Modeling API.

## Open items

- GHCR publish still needs the org Actions and SSO steps in [Publishing the runtime image](#publishing-the-runtime-image). Nobody has published an image yet.
- Staging materialization (views vs tables) is an instance-repo question for Max.
- A public-branch confidentiality leak on `feat/chat-data-architecture` needs a fix-forward. Not part of this merge; no history rewrite.
- Coolify watch-path behavior on compose resources is unverified.
