---
kind: backlog-draft
slug: narrowstack-core-linear
date: 2026-08-31
status: draft
verified: 2026-08-31
note: Partial MCP create succeeded 2026-09-01; remaining issues — paste into Linear manually or re-run G7 with approval.
---

# Linear backlog draft — narrowstack-core Phase G7

**Project:** Narrowstack Core (Stackflow) · **Team:** NarrowstackOS

## Created via MCP (2026-09-01)

| ID | Title | URL |
|---|---|---|
| OS-414 | Epic: G — Govern (dry run) | https://linear.app/narrowstack/issue/OS-414 |
| OS-412 | Epic: W0 — Repo scaffold | https://linear.app/narrowstack/issue/OS-412 |
| OS-413 | Epic: W1 — Allowlist + ACL + rollback | https://linear.app/narrowstack/issue/OS-413 |
| OS-415 | Epic: W2 — Local-warehouse compose + green-check | https://linear.app/narrowstack/issue/OS-415 |
| OS-416 | Epic: W4 — NS instance (PRD skeleton) | https://linear.app/narrowstack/issue/OS-416 |
| OS-417 | Core — rollback-first deploy pipeline (parent OS-413) | https://linear.app/narrowstack/issue/OS-417 |
| OS-418 | Core — model-shipping allowlist (parent OS-413) | https://linear.app/narrowstack/issue/OS-418 |

## Epics to create

### Epic: W3 — Semantics refactor + private tenant manifest

**State:** Backlog · **Priority:** Medium

```markdown
narrowstack-semantics refactor; private tenant manifest; semantics template cut.

**Handoff:** docs/product/handoff-semantics-w3.md
**Roadmap:** TASK-013
**RFC:** RFC-004
```

### Epic: W5 — Full pipelines + modeling API

**State:** Backlog · **Priority:** Medium

```markdown
Full NS pipelines; instance #2 self-host; modeling API first slice.

**Spec:** docs/features/modeling-api.md
**Roadmap:** TASK-015
**Replaces:** NRWSTK-945 core webapp (deprecated)
```

### Epic: W6 — External warehouse + legacy client fit [deferred]

**State:** Backlog · **Priority:** Low

```markdown
External warehouse compose; legacy client sufficiency assessment.

**Deferred** until W4 gate passes.
**Spec:** docs/features/legacy-client-fit.md
**Roadmap:** TASK-016
```

## Issues to create (under epics)

### OS-412 / W0 — Core IaC — instance manifest schema + examples

```markdown
JSON Schema at manifest/schema.json — warehouse.mode only, no topology/app_ref.

**Spec:** docs/features/instance-manifest.md
**Acceptance:**
- lint passes example-local-warehouse.yaml
- invalid fixtures fail with field paths
- op:// enforced, no literal secrets
```

### OS-413 / W1 — Core — three-layer metric ACL framework

```markdown
Warehouse + semantic + API ACL; RFC-005 before build.

**Spec:** docs/features/metric-acl.md
**Acceptance:**
- ACL smoke in green-check names failing metric
- Per-role credentials via op://
- Local kill-switch overrides remote policy
```

### OS-415 / W2 — Core — local-warehouse compose on Coolify

```markdown
compose/local-warehouse/ + green-check end-to-end.

**Spec:** docs/features/local-warehouse-deploy.md
**Blocked by:** NRWSTK-901–909 (Cloud hcloud)
```

### OS-415 / W2 — Core — ns-core CLI stubs

```markdown
On-VM CLI: status, deploy, rollback, grants, acl list, backup, restore.

**Spec:** docs/features/ns-core-cli.md
```

### OS-416 / W4 — Core — NS tenant instance (second VM)

```markdown
PRD skeleton steps 1–10 on NS dogfood data.

**Reconcile OS-338:** comment linking W4 as dogfood path; split Airbyte demo track.
```

### W5 — Core — modeling API first slice

```markdown
list_metrics, get_manifest, mf_query with principal auth.

**Spec:** docs/features/modeling-api.md
```

### W6 — Core — legacy client sufficiency assessment

```markdown
Inventory + gap matrix + fit probe for seven client implementations.

**Spec:** docs/features/legacy-client-fit.md
```

### Cross-cutting — Telemetry phone-home Linear project

```markdown
New project or epic under Admin plane — outbound-only protocol receiver.

**Spec:** docs/architecture/telemetry-protocol.md
**When:** W3+ (Admin implements)
```

## OS-338 reconcile (comment on existing issue)

```markdown
Architecture Phase G retargets dogfood path to Epic W4 (OS-416).

OS-338 Airbyte → Metabase demo remains **client-delivery track** — do not drive narrowstack-core IaC scope.

Options:
1. Cancel OS-338 acceptance as dogfood OR
2. Open sibling "Client-delivery demo (Airbyte)" under engagements

**Plan:** docs/plans/narrowstack-core-architecture-20260831.md § Linear reconcile
```

## NRWSTK-945 (core webapp)

Cancel or reparent to deprecated narrowstack-core-app; replace with modeling API issue (W5). See RFC-006.
