---
kind: architecture
slug: packaging
date: 2026-08-31
verified: 2026-08-31
wiki: operating-system/working/core-packaging-spec.md
---

# Packaging — IaC and deploy contract

**Wiki:** `operating-system/working/core-packaging-spec.md` (strategy canon)

**Summary:** How a Core instance is provisioned, upgraded, restored, and destroyed on a per-customer VM. IaC is the interface between Core and Cloud; no snowflake servers.

---

## Deploy models

Expressed via `warehouse.mode` in the instance manifest — no topology enum.

| Business term | `warehouse.mode` | Deploys |
|---|---|---|
| Full Core instance | `local` | Postgres + ingestion + transform + semantic layer + agent API |
| Semantic layer attach | `external` | Transform + semantic layer + API against customer warehouse |

Compose paths: `compose/local-warehouse/`, `compose/external-warehouse/`. Conceptual names live in docs only.

---

## Instance manifest (config commit)

One declarative manifest per tenant. Carries:

- `tenant_id` — stable runtime slug (not repo name)
- `warehouse` — mode, provider, backup (local), `external_dsn_ref` (external)
- `semantics_ref` — git ref of private semantics repo
- `enabled_pipelines`, `allowlist_profile`, `principals`
- `provider_mode` (M0–M3), `telemetry_grants` (default `[]`)
- `control_plane` (optional phone-home)

Generic example in core: `manifest/examples/example-local-warehouse.yaml`. Tenant manifests live in private semantics repos (`deploy/manifest.yaml`).

---

## Green-check (deploy success)

1. `pre-deploy-snapshot.sh` — pins, manifest hash, optional pg_dump ref
2. Clone semantics at `semantics_ref`
3. Pipelines → `dbt seed && dbt run && dbt parse`
4. Allowlist gate (fail names model)
5. ACL smoke per principal
6. Tie-out validators
7. Smoke `mf query`
8. Write `active-manifest.json` on VM
9. On failure: `rollback.sh` (auto unless `--no-auto-rollback`)

`destroy.sh` and `restore.sh` are first-class — restore demonstrated before warehouse-hosting decision closes.

---

## Repo roles

| Artifact | Location | OSS? |
|---|---|---|
| Deploy scripts, compose, manifest schema, ACL framework | `narrowstack-core` | Yes |
| Semantics templates | `narrowstack-core/semantics/` | Yes |
| Tenant manifest, proprietary models | Private semantics repo | No |

At deploy: git clone semantics at pinned ref (v1). Signed OCI bundle deferred to v2.

---

## Fleet upgrades

Three versioned interfaces move independently: tool contract, semantic contract, telemetry protocol. Upgrades are **proposed to the instance, not pushed**. Every upgrade runs the same green-check against that customer's data. Rollback reuses snapshot path.

---

## Secrets

Per-role warehouse credentials (dlt, dbt, MetricFlow, app reader, agent) via `.env.tpl` + `op://` references. Never baked into images or manifest plaintext.

---

## Volume ceiling

Internal build uses full-refresh. Manifest may document `volume_ceiling_gb` until incremental loading exists — honest limit, not silent failure.

---

## Acceptance criteria

1. Second instance from config commit, zero manual steps
2. Re-deploy idempotent
3. Unlisted model fails deploy with model name
4. Destroy + restore returns verified state
5. External warehouse provisions without Core-created Postgres
6. No NS payroll, bonus, company-split, or demo models in customer instance
