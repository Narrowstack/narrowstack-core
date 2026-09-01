---
kind: research
slug: core-architecture-critique
date: 2026-08-31
status: draft
verified: 2026-08-31
refs:
  - docs/plans/narrowstack-core-architecture-20260831.md
  - operating system/docs/rfc/rfc-004-semantics-delivery.md
  - operating system/docs/rfc/rfc-005-metric-acl-phone-home.md
  - operating system/docs/rfc/rfc-006-headless-surface.md
  - ADR-001
  - ADR-003
---

# Core architecture — frontier adversarial critique

**Executive verdict:** The Phase G architecture (core as OSS IaC shell, per-tenant private semantics repo, `semantics_ref` pin, three-layer ACL, headless v1 surface, one VM per customer) is **directionally sound** and matches ADR-003, the packaging spec, and working dogfood evidence. **Ship v1 with git clone at deploy** — lowest cost, honest rollback, sufficient for fleet sizes under ~20 instances. **Do not** treat clone-at-deploy as permanent; define the v2 artifact trigger now. **Repo ownership default (Narrowstack-owned private semantics)** is correct for MSP; document enterprise escape hatches without building them in W0–W3. **Legacy Airbyte sites stay on a parallel track** until W4 dogfood passes; sufficiency probe is evidence, not migration commitment.

**Linear:** NS-2 Core · **RFCs:** RFC-004, RFC-005, RFC-006 (draft)

---

## Primary question — semantics delivery at deploy

### What the spec proposes

At deploy, `green-check.sh` clones the tenant's private semantics repo at `manifest.semantics_ref` (tag or SHA). Rollback = revert ref + re-run green-check. v2 defers signed OCI / immutable bundles until fleet scale warrants.

### Praise

- **Honest v1.** The manual rebuild recipe in the packaging spec already says "clone the pipelines repo." Automating that is the smallest honest step — no pretend supply-chain maturity on day one.
- **Rollback symmetry.** `semantics_ref` is the same knob for deploy and rollback; `pre-deploy-snapshot.sh` can record it beside `core_ref` without a second artifact format.
- **CI stays in the semantics repo.** Allowlist + ACL regression + `dbt parse` run where the models live; deploy only consumes a ref that passed CI.
- **Proprietary boundary is clear.** OSS core holds templates; tenant repos hold payroll, bonus, company-split, and live connectors. The pin is the contract, not the core tree.

### Adversarial concerns

| Concern | Severity | Why it bites |
|---|---|---|
| **Deploy-time git dependency** | High | Green-check needs outbound GitHub (or mirror) access, valid deploy credentials, and a reachable ref. Air-gapped or credential-rotated VMs fail deploy even when the last bundle was fine. |
| **Ref ≠ immutable artifact** | Medium | A tag can move (force-push on tenant repo). SHA pins are safe but opaque to operators; tags are readable but mutable unless protected. |
| **No signed provenance** | Medium | Clone trusts git host + credential chain. A compromised semantics repo or token ships bad models until allowlist catches them — defense in depth wants signature at the artifact boundary. |
| **Clone cost on every deploy** | Low–Med | Full repo history on each green-check is wasteful; shallow clone + sparse checkout must be explicit in `clone-semantics.sh`. |
| **Submodule/registry alternatives rejected early** | Low | D5 says no submodule — correct for MSP ops, but submodules would couple core and semantics versions in one commit; registry would front-load build infra. |

### Recommended changes

1. **Manifest requires SHA or annotated tag** — schema documents that floating branch refs are invalid in production manifests; CI lints manifest before deploy.
2. **`clone-semantics.sh` — shallow, no history** — `--depth 1` at pinned ref; document offline mirror path for enterprise (deferred build).
3. **Record `semantics_template_version`** in manifest (already in spec) and fail green-check on major template drift without explicit override.
4. **Define v2 trigger in RFC-004** — e.g. fleet >15 instances, first enterprise air-gap requirement, or first failed deploy attributable to git host outage. Do not defer the trigger definition.
5. **Protect tenant repo tags** — branch protection on `v*` tags in Narrowstack-owned semantics repos; customer-owned repos get a checklist item, not enforcement code.

---

## MSP semantics repo ownership

### Models on the table

| Model | When | Praise | Adversarial |
|---|---|---|---|
| **Narrowstack-owned private repo per tenant** (`customer-{slug}-semantics`) | Default MSP | IP retention, uniform upgrades, one playbook for fleet ops, NS can run CI and allowlist gates before customer sees deploy | Customer may perceive lock-in; offboarding needs export story; NS becomes git custodian for all tenant IP |
| **Customer-owned repo** | Enterprise / compliance | Customer holds keys; easier procurement narrative; offboarding is a fork | NS loses upgrade leverage; drift across fleet; harder to enforce allowlist before deploy; support needs read access grants |
| **Per-customer git org for all source** | Not recommended at MVP | Clean isolation story for largest enterprises | Operational nightmare at 7–20 tenants; duplicates Cloud/identity work; plan already excludes (D10) |

### Verdict

**Keep Narrowstack-owned as default (D10).** It is the only model that makes fleet-wide allowlist enforcement and MSP upgrade proposals ("bump `semantics_ref` after CI green") tractable.

### Recommended changes

1. **Offboarding clause in commercial docs** — full repo export + last `semantics_ref` + manifest snapshot; not implemented in W0, specified in G4 semantics feature spec.
2. **Enterprise exception path** — document customer-owned repo as RFC follow-up (not blocking W3); require NS CI webhook or signed bundle v2 for customer-owned repos so deploy gate stays enforceable.
3. **Naming** — `customer-{slug}-semantics` under `Narrowstack` org, not mixed into `narrowstack-semantics` (dogfood stays separate).

---

## Legacy customer upgrade path — seven Airbyte sites

### Current state

Seven live bespoke implementations — predominantly **Airbyte + dbt + Postgres** (Snowflake/ClickHouse exceptions per site). These are **client-delivery**, not dogfood Core. RFC-002 (Airbyte vs dlt) remains open. Linear Stackflow still tracks connector backlog that does not map to this IaC architecture.

### Praise (for the deferred probe design)

- **Correct non-goal** — full migration of all seven in v1 would collapse Phase G into a services project.
- **Sufficiency assessment before commitment** — inventory → gap matrix → fit probe on 1–2 sites → per-customer verdict (migrate / coexist / retain) is the right evidence shape.
- **Semantic layer attach precedent** — `warehouse.mode: external` matches sites that already own Snowflake/ClickHouse; does not force rip-and-replace ingestion on day one.

### Adversarial concerns

| Concern | Severity | Notes |
|---|---|---|
| **Two "Core" products in market** | Critical | Airbyte client-delivery vs dlt dogfood; OS-338 and Stackflow misdirect engineering if not split in Linear (plan G7). |
| **Ingestion mismatch** | High | Dogfood is dlt; six of seven sites are Airbyte. Core v1 does not include Airbyte in `narrowstack-core`. |
| **Warehouse heterogeneity** | Medium | Ally (Snowflake + N8N for ADP), Bulldog (ClickHouse) — external warehouse adapters deferred W6+. |
| **Max as single maintainer** | High | Fleet ops burden if every site migrates; probe must include operational cost, not just technical fit. |
| **Commercial promise risk** | Medium | Semantic layer attach sold once; assuming all seven can attach semantics without ingestion change is unproven. |

### Recommended changes

1. **G7 Linear split** — dogfood epics W0–W5 vs "Legacy client delivery" label; OS-338 reparented or sibling issue for Airbyte demo.
2. **Probe order** — Postgres-warehouse sites first (lowest gap); Snowflake/ClickHouse as external-warehouse fit probes in W6.
3. **Default verdict bias** — **coexist or retain** until W4 NS instance proves green-check; migrate only where gap matrix shows no blockers.
4. **Do not block dogfood on legacy** — legacy inventory is W6 research; G4 `legacy-client-fit.md` spec only.

---

## Proprietary yet futureproof semantics

### Praise

- **Template/fork split** — OSS `semantics/` patterns without NS payroll; fork carries proprietary models. Matches packaging spec allowlist philosophy.
- **Semver tags + `semantics_template_version`** — gives fleet a language for "template moved under you."
- **Three-layer ACL** — warehouse + semantic + API; not optional in W1.
- **Default-deny allowlist** — sharpest blocker from packaging spec; architecture places it in both semantics CI and deploy gate.

### Adversarial concerns

| Concern | Severity | Notes |
|---|---|---|
| **Fork drift** | High | Tenants stop merging template fixes; security patches in OSS template do not flow automatically. |
| **Allowlist bypass via macro/jinja** | Medium | Adversarial dbt can hide models; need static analysis beyond model name list. |
| **Metric ACL without per-role warehouse creds** | Critical | Bounded API is theater if one Postgres password backs all roles (known gap in current-state secrets). |
| **Phone-home ACL push** | Medium | Remote policy is convenient for MSP; local kill-switch must win (spec says so — RFC-005 must harden). |
| **OSS boundary creep** | Medium | Pressure to ship "one more example" that leaks bonus patterns into template. |

### Recommended changes

1. **W1 gate: per-role warehouse credentials** — non-negotiable before any external deploy; blocks metric ACL value.
2. **Template merge tooling (W3+)** — `semantics_template_version` bump workflow documented; optional `ns-core template diff` stub in roadmap.
3. **Allowlist v1 scope** — models + seeds + dashboard tables (packaging spec); document macro audit as W2+ hardening.
4. **No proprietary seeds in OSS tree** — even synthetic; use obviously fake `example_*` identifiers only.

---

## Delivery model scorecard

Criteria drawn from the architecture spec (deploy pipeline, rollback, fleet ops, proprietary boundary, ADR-003 constraints).

| Criterion | Weight | Git clone @ ref (v1) | Git submodule | Private OCI / signed bundle | Generic container registry (unsigned) |
|---|---:|---:|---:|---:|---:|
| MVP build cost | 20% | **5** | 3 | 2 | 3 |
| Rollback simplicity | 15% | **5** | 2 | 4 | 3 |
| Immutability / supply chain | 15% | 2 | 3 | **5** | 2 |
| Offline / air-gap deploy | 10% | 2 | 2 | **4** | 3 |
| Operator mental model | 10% | **5** | 2 | 3 | 3 |
| Fleet upgrade uniformity | 15% | 4 | 2 | **5** | 4 |
| Proprietary IP separation | 10% | **5** | 4 | 5 | 4 |
| CI integration (semantics repo) | 5% | **5** | 3 | 4 | 3 |
| **Weighted total** | 100% | **4.15** | 2.55 | 3.95 | 2.95 |

**Scale:** 1 = poor fit, 5 = excellent fit.

**Interpretation:** Git clone wins v1 on cost and rollback. Signed OCI closes the gap on immutability and fleet push — adopt as v2 when trigger fires (RFC-004). Submodules and unsigned registry images are worse than clone for this architecture; submodules violate D5 and couple repos; unsigned registry adds infra without provenance.

---

## Cross-cutting strengths (keep)

1. **ADR-003 alignment** — one VM per customer removes shared-warehouse multi-tenancy from Core scope.
2. **Manifest as config commit** — `warehouse.mode` instead of topology enums (D9); honest IaC interface to Cloud.
3. **Rollback-first deploy** — snapshot + auto-rollback (D11) matches buyer trust claims.
4. **Headless v1** — deprecating `narrowstack-core-app` (D8) reduces drift surface; modeling API + `ns-core` CLI are the right product boundary.
5. **Coolify on Hetzner** — matches Cloud project reality (RFC-003 direction).
6. **Govern-before-build (D13)** — this critique is evidence Phase G is working.

---

## Cross-cutting risks (mitigate before W2 external deploy)

| Risk | Mitigation | Wave |
|---|---|---|
| No allowlist in production path | Default-deny YAML + deploy gate | W1 |
| Single warehouse credential | Per-role creds via `op://` | W1 |
| OS-338 / Stackflow misalignment | G7 Linear reconcile; split dogfood vs client-delivery | G7 |
| NRWSTK-945 core webapp | Cancel or reparent; replace with modeling API (W5) per RFC-006 | G7 |
| Tag mutability | SHA or protected tags in manifest | W0 schema |
| Git host dependency at deploy | Shallow clone; v2 artifact trigger | W0 / RFC-004 |
| Semantics fork drift | `semantics_template_version` + merge workflow (W3+) | W3 |
| Entity layer / company-split in dogfood | Skeleton scope per PRD; not architecture blocker | W4 |

---

## RFC handoff

| Topic | RFC | Status |
|---|---|---|
| Semantics delivery (clone vs artifact) | `operating system/docs/rfc/rfc-004-semantics-delivery.md` | Draft |
| Metric ACL + phone-home remote policy | `operating system/docs/rfc/rfc-005-metric-acl-phone-home.md` | Draft |
| Headless surface / deprecate core-app | `operating system/docs/rfc/rfc-006-headless-surface.md` | Draft |
| Semantics repo ownership | Covered in this critique; optional RFC if enterprise customers appear before W3 | Deferred |

---

## Discussion log

| Date | Author | Note |
|---|---|---|
| 2026-08-31 | agent | Initial frontier critique from Phase G plan; scoring matrix applied; no human acceptance yet |
