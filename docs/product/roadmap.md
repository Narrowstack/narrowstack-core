---
kind: roadmap
slug: narrowstack-core
date: 2026-08-31
status: proposed
verified: 2026-08-31
note: All phases proposed until Phase G8 sign-off. Waves W0–W6 may reorder without build sunk cost.
---

# Roadmap — Narrowstack Core

**Status:** Proposed (Phase G). No `build-loop` until G8 operator sign-off.

**PRD:** `docs/product/prd.md` · **Architecture:** `docs/plans/narrowstack-core-architecture-20260831.md`

---

## W0 — Repo scaffold

**Goal:** Repository skeleton, manifest schema, semantics templates, ACL stubs, and CI exist — no customer deploy yet.

**Reference sections:** PRD §Walking skeleton steps 1–3 (structure only); architecture plan §Repo structure.

**Kickoff prompt:** Execute W0 tasks sequentially. Scaffold `narrowstack-core` per architecture plan; no green-check until W2.

- [ ] **TASK-001** — Create repo directory skeleton per architecture plan
  Files: `README.md`, `manifest/schema.json`, `deploy/`, `compose/`, `semantics/`, `acl/`, `scripts/`
  Notes: Directories only; stub README pointers to docs.
  Verify: `find . -type d | sort` matches plan tree.

- [ ] **TASK-002** — Author `manifest/schema.json` for instance manifest minimum fields
  Files: `manifest/schema.json`
  Notes: Fields per architecture plan — `tenant_id`, `warehouse`, `semantics_ref`, `enabled_pipelines`, `allowlist_profile`, `principals`, `provider_mode`, `telemetry_grants`.
  Verify: `node scripts/lint-manifest.mjs manifest/examples/example-local-warehouse.yaml` passes (script may be stub).

- [ ] **TASK-003** — Add generic example manifest
  Files: `manifest/examples/example-local-warehouse.yaml`
  Notes: `tenant_id: example`, `warehouse.mode: local`, placeholder `semantics_ref`.
  Verify: Validates against schema.

- [ ] **TASK-004** — Scaffold semantics template tree
  Files: `semantics/requirements.txt`, `semantics/dlt_pipelines/_template_pipeline.py`, `semantics/dbt_project/`, `semantics/allowlist/default.yaml`
  Notes: One vertical slice pattern only; no NS proprietary models.
  Verify: Directory structure matches architecture plan §semantics/ template tree.

- [ ] **TASK-005** — Add ACL framework stubs
  Files: `acl/metric-sensitivity.yaml`, `semantics/acl/metric-sensitivity.yaml`, `semantics/scripts/smoke_test.py` (stub)
  Notes: Schema for sensitivity tiers; smoke script exits 0 with TODO.
  Verify: Files exist; YAML parses.

- [ ] **TASK-006** — Add CI workflow skeleton
  Files: `.github/workflows/ci.yml`
  Notes: Lint manifest, allowlist check placeholder, `dbt parse` on template.
  Verify: Workflow YAML valid; runs on PR (may be stub jobs).

- [ ] **TASK-007** — Add deploy script stubs
  Files: `deploy/green-check.sh`, `deploy/pre-deploy-snapshot.sh`, `deploy/rollback.sh`, `deploy/destroy.sh`, `deploy/restore.sh`, `deploy/allowlist-gate.sh`, `deploy/acl-smoke.sh`
  Notes: Each script `--help` or echo stage name; no VM ops yet.
  Verify: `bash -n deploy/*.sh` passes.

---

## W1 — Allowlist, ACL, rollback

**Goal:** Default-deny allowlist enforced in CI and deploy; three-layer ACL schema wired; rollback-first pipeline scripted.

**Reference sections:** PRD §M3, §M5; `docs/features/allowlist-gate.md`, `metric-acl.md`, `rollback-deploy.md`.

**Kickoff prompt:** W1 makes gates real. Deploy must fail on unlisted models and auto-rollback on failure.

- [ ] **TASK-008** — Implement `check-allowlist.py` default-deny
  Files: `semantics/scripts/check-allowlist.py`, `semantics/allowlist/default.yaml`
  Notes: Seeds and dashboard tables in scope; `sfdc_demo` permanently denied.
  Verify: Unlisted model causes non-zero exit with model name in stderr.

- [ ] **TASK-009** — Wire allowlist into CI
  Files: `.github/workflows/ci.yml`, `deploy/allowlist-gate.sh`
  Notes: CI runs check on every PR to semantics template.
  Verify: CI fails when test fixture adds unlisted model.

- [ ] **TASK-010** — Implement metric ACL schema + smoke script
  Files: `acl/`, `semantics/acl/metric-sensitivity.yaml`, `deploy/acl-smoke.sh`
  Notes: Principals from manifest; three layers documented in feature spec.
  Verify: Smoke script reports pass/fail per principal fixture.

- [ ] **TASK-011** — Implement `pre-deploy-snapshot.sh`
  Files: `deploy/pre-deploy-snapshot.sh`
  Notes: Record `core_ref`, `semantics_ref`, manifest hash, optional pg_dump ref.
  Verify: Snapshot JSON written with all fields on dry-run.

- [ ] **TASK-012** — Implement `rollback.sh` with auto-rollback default
  Files: `deploy/rollback.sh`, `deploy/green-check.sh`
  Notes: Restore previous pins; `--no-auto-rollback` flag for operator override.
  Verify: Simulated gate failure triggers rollback and restores snapshot pins.

- [ ] **TASK-013** — Finalize deploy guide acceptance criteria
  Files: `docs/guides/deploy.md`, `docs/guides/rollback.md`
  Notes: Fill placeholders from feature specs; operator-facing steps.
  Verify: Guide sections match green-check sequence in architecture plan.

---

## W2 — Local warehouse compose + green-check

**Goal:** `compose/local-warehouse/` runs on Coolify substrate; green-check passes end-to-end on example tenant; `ns-core` CLI stubs ship.

**Reference sections:** PRD §Walking skeleton steps 1–5; `docs/features/local-warehouse-deploy.md`, `ns-core-cli.md`.

**Kickoff prompt:** W2 needs Cloud VM provisioning (NRWSTK-901–909). Core consumes manifest; Cloud provisions substrate.

- [ ] **TASK-014** — Author `compose/local-warehouse/docker-compose.yml`
  Files: `compose/local-warehouse/docker-compose.yml`, `compose/local-warehouse/.env.tpl`
  Notes: Postgres volume, dlt, dbt, MetricFlow services; per-role creds via op inject.
  Verify: `docker compose config` validates.

- [ ] **TASK-015** — Implement `scripts/clone-semantics.sh`
  Files: `scripts/clone-semantics.sh`
  Notes: Clone private semantics repo at `semantics_ref` git ref.
  Verify: Clones public test repo at pinned SHA.

- [ ] **TASK-016** — Wire green-check sequence steps 1–8
  Files: `deploy/green-check.sh`
  Notes: Snapshot → clone → pipelines → dbt → allowlist → ACL → tie-out → smoke `mf query` → write `active-manifest.json`.
  Verify: Green-check passes on local compose with example manifest.

- [ ] **TASK-017** — Implement `destroy.sh` and `restore.sh`
  Files: `deploy/destroy.sh`, `deploy/restore.sh`
  Notes: Destroy stops compose; restore replays green-check steps 3–7 after backup pull.
  Verify: Destroy + restore returns instance to known metric answer (fixture).

- [ ] **TASK-018** — Scaffold `ns-core` CLI stubs
  Files: `cli/ns-core.py` or `scripts/ns-core`, package entry in `pyproject.toml`
  Notes: Subcommands: `status`, `deploy`, `rollback`, `grants`, `acl list`, `backup`, `restore` — print TODO.
  Verify: `ns-core --help` lists all subcommands.

- [ ] **TASK-019** — Integrate Coolify deploy path
  Files: `docs/guides/deploy.md`, compose labels
  Notes: Document Cloud handoff; manifest `vm_size_class` token.
  Verify: Deploy doc describes operator flow Cloud → green-check.

---

## W3 — Semantics refactor + tenant manifest

**Goal:** `narrowstack-semantics` proprietary cut complete; NS tenant manifest in private repo; semantics template fork path proven.

**Reference sections:** `docs/features/semantics-template-cut.md`, `instance-manifest.md`; architecture plan §Semantics delivery.

**Kickoff prompt:** W3 is brownfield migrate of semantics — template in core, proprietary in private repo.

- [ ] **TASK-020** — Cut OSS-safe template in `narrowstack-core/semantics/`
  Files: `semantics/` tree
  Notes: Remove NS payroll, bonus, company-split; keep one example vertical slice.
  Verify: Allowlist CI green; no proprietary model names in tree.

- [ ] **TASK-021** — Create `narrowstack-semantics` private tenant manifest
  Files: `narrowstack-semantics/deploy/manifest.yaml` (partner repo)
  Notes: `tenant_id: narrowstack`, `allowlist_profile: internal`, real `semantics_ref` pin.
  Verify: Manifest validates against core schema.

- [ ] **TASK-022** — Move proprietary pipelines to private semantics repo
  Files: Partner repo `dlt_pipelines/`, `dbt_project/models/`
  Notes: Live connectors, bonus/payroll, company-split, internal allowlist profile.
  Verify: Private repo CI runs allowlist + `dbt parse` + ACL regression.

- [ ] **TASK-023** — Document semantics fork workflow
  Files: `docs/guides/operations.md`
  Notes: Fork template → customize → tag → bump `semantics_ref` → green-check.
  Verify: Operator can follow doc without asking builder.

- [ ] **TASK-024** — Wire phone-home telemetry interface stub
  Files: `deploy/acl-apply.sh`, docs reference
  Notes: Local kill-switch overrides remote; consent grants per telemetry protocol.
  Verify: `acl-apply.sh --dry-run` documents grant flow.

---

## W4 — NS tenant instance (PRD skeleton)

**Goal:** First real NS tenant passes PRD walking skeleton steps 1–10 on dedicated VM.

**Reference sections:** PRD §Walking skeleton (full); PRD §Done means.

**Kickoff prompt:** W4 is the dogfood gate — second instance, real data, non-builder provision test.

- [ ] **TASK-025** — Provision NS tenant VM via Cloud + manifest
  Files: `narrowstack-semantics/deploy/manifest.yaml`
  Notes: `warehouse.mode: local`; Coolify on Hetzner VPS per ADR-003.
  Verify: VM reachable; green-check stage 1 passes.

- [ ] **TASK-026** — Load one real NS source via dlt
  Files: Private semantics pipeline
  Notes: `_dlt_loads` completed row.
  Verify: PRD step 2 check.

- [ ] **TASK-027** — Build one mart + one MetricFlow metric with durable entity key
  Files: Private semantics dbt + MetricFlow
  Notes: No company-split dependency; surrogate key for client entity.
  Verify: PRD step 3 — `dbt parse` clean, entity resolves.

- [ ] **TASK-028** — Run tie-out validator and record result
  Files: `semantics/scripts/` or private repo validators
  Verify: PRD step 4 — validator passes, tie-out logged.

- [ ] **TASK-029** — Exercise allowlist gate on NS deploy
  Files: `deploy/allowlist-gate.sh`
  Verify: PRD step 5 — deliberate violation fails with model name.

- [ ] **TASK-030** — Principal queries metric via headless API
  Files: Modeling API stub or `mf query`
  Verify: PRD step 6 — answer matches tie-out.

- [ ] **TASK-031** — Switch provider mode M0 → M1
  Files: Manifest `provider_mode`
  Verify: PRD step 7 — same number, different vendor account.

- [ ] **TASK-032** — Telemetry grant lifecycle + kill-switch
  Files: Telemetry client stub
  Verify: PRD steps 8–9 — T0 only at rest; revoke; pipelines still run.

- [ ] **TASK-033** — Destroy and restore demonstration
  Files: `deploy/destroy.sh`, `deploy/restore.sh`
  Verify: PRD step 10 — restored instance answers known question.

- [ ] **TASK-034** — Non-builder provision test
  Files: `docs/guides/deploy.md`
  Verify: PRD §Done means — provision without asking builder.

---

## W5 — Full pipelines + modeling API

**Goal:** Full NS pipelines live; second self-hosted instance; modeling API first slice ships.

**Reference sections:** `docs/features/modeling-api.md`; PRD §Should S1–S2.

**Kickoff prompt:** W5 expands from skeleton to production NS dogfood + API surface.

- [ ] **TASK-035** — Enable full NS pipeline set per manifest
  Files: Private semantics `dlt_pipelines/`
  Verify: All `enabled_pipelines` load successfully.

- [ ] **TASK-036** — Provision instance #2 (self-hosted Postgres)
  Files: Second tenant manifest
  Notes: D3 — managed for #1, self-host for #2.
  Verify: Two instances reconcile same metric.

- [ ] **TASK-037** — Implement modeling API `list_metrics`
  Files: `api/` or service in compose
  Verify: Returns only metrics permitted for principal token.

- [ ] **TASK-038** — Implement modeling API `get_manifest` + `mf_query`
  Files: API routes
  Verify: Query result matches CLI `mf query` for same metric.

- [ ] **TASK-039** — Make `ns-core` CLI functional (W4 subcommands)
  Files: `cli/ns-core`
  Notes: `status`, `deploy`, `rollback` at minimum.
  Verify: Operator completes deploy + rollback via CLI only.

- [ ] **TASK-040** — Fleet upgrade doc + proposed-pin workflow
  Files: `docs/guides/operations.md`
  Verify: Documents pull-not-push upgrade with green-check per customer.

---

## W6 — External warehouse + legacy fit (deferred)

**Goal:** External warehouse compose path proven; legacy client sufficiency research complete.

**Reference sections:** `docs/features/legacy-client-fit.md`; PRD §Could C2.

**Kickoff prompt:** W6 is explicitly deferrable. Execute only after W4 gate passes.

- [ ] **TASK-041** — Author `compose/external-warehouse/docker-compose.yml`
  Files: `compose/external-warehouse/`
  Notes: `warehouse.mode: external`; DSN via `op://`; no local Postgres service.
  Verify: Green-check passes against external Postgres fixture.

- [ ] **TASK-042** — Document warehouse contract for external attach
  Files: `docs/guides/warehouse.md`
  Verify: Covers Supabase/managed Postgres via DSN; Snowflake/ClickHouse deferred.

- [ ] **TASK-043** — Legacy client inventory research
  Files: `docs/product/research/legacy-client-inventory-YYYYMMDD.md`
  Notes: Per-customer ingestion, warehouse, transform, semantic exposure, access model.
  Verify: All seven sites documented per legacy-client-fit spec.

- [ ] **TASK-044** — Gap matrix + 1–2 fit probes
  Files: Research package
  Verify: Per-customer verdict migrate / coexist / retain bespoke.

- [ ] **TASK-045** — Open Linear epic for legacy track
  Files: Linear only
  Verify: Epic linked to NS-2 Core project with W6 label.

---

## Feature spec — instance manifest

**Goal:** `docs/features/instance-manifest.md` acceptance criteria traced to W0 implementation tasks.

- [ ] **TASK-046** — Operator sign-off on manifest schema spec
  Files: `docs/features/instance-manifest.md`, `manifest/schema.json`
  Notes: Confirm minimum fields match architecture plan; example manifest is generic only.
  Verify: All five verification plan items have owning TASK in W0.

---

## Feature spec — allowlist gate

**Goal:** Allowlist feature spec gates W1 deploy enforcement.

- [ ] **TASK-047** — Security review on default-deny allowlist spec
  Files: `docs/features/allowlist-gate.md`
  Notes: Confirm seeds and dashboard tables in scope; sfdc_demo denial tested.
  Verify: Verification plan maps to TASK-008, TASK-009.

---

## Feature spec — rollback deploy

**Goal:** Rollback-first spec aligned with green-check orchestration.

- [ ] **TASK-048** — Operator sign-off on rollback deploy spec
  Files: `docs/features/rollback-deploy.md`
  Notes: Auto-rollback default; rollback is restore path not second mechanism.
  Verify: Verification plan maps to TASK-011, TASK-012, TASK-016, TASK-017.

---

## Feature spec — metric ACL

**Goal:** Three-layer ACL spec reviewed before W1 build; RFC tracked for remote push.

- [ ] **TASK-049** — Security review on metric ACL spec
  Files: `docs/features/metric-acl.md`
  Notes: Flag RFC for phone-home ACL push (Phase G5); local kill-switch override explicit.
  Verify: Verification plan maps to TASK-010; principal fixtures defined.

---

## Feature spec — local warehouse deploy

**Goal:** Local compose spec gates W2 green-check integration.

- [ ] **TASK-050** — Operator sign-off on local-warehouse deploy spec
  Files: `docs/features/local-warehouse-deploy.md`
  Notes: Cloud handoff documented; volume ceiling posture acknowledged.
  Verify: Verification plan maps to TASK-014 through TASK-019.

---

## Feature spec — ns-core CLI

**Goal:** CLI spec defines stub vs functional waves.

- [ ] **TASK-051** — Operator sign-off on ns-core CLI spec
  Files: `docs/features/ns-core-cli.md`
  Notes: W2 stubs vs W4/W5 functional scope explicit.
  Verify: Verification plan maps to TASK-018, TASK-039.

---

## Feature spec — semantics template cut

**Goal:** OSS/private cut line agreed before W3 brownfield migrate.

- [ ] **TASK-052** — Human sign-off on semantics template cut
  Files: `docs/features/semantics-template-cut.md`
  Notes: Data-boundary table reviewed; RFC for clone vs artifact delivery tracked.
  Verify: Verification plan maps to TASK-020 through TASK-023.

---

## Feature spec — modeling API

**Goal:** Headless API spec replaces core-app as v1 surface.

- [ ] **TASK-053** — Technical review on modeling API spec
  Files: `docs/features/modeling-api.md`
  Notes: API contract matches ADR-001 bounded-tool facade intent.
  Verify: Verification plan maps to TASK-037, TASK-038.

---

## Feature spec — legacy client fit

**Goal:** Deferred research spec scoped; no build commitment.

- [ ] **TASK-054** — Operator acknowledges legacy fit as W6 deferred
  Files: `docs/features/legacy-client-fit.md`
  Notes: Seven-site inventory; no auto-migration; OS-338 split referenced.
  Verify: Verification plan maps to TASK-043 through TASK-045.
