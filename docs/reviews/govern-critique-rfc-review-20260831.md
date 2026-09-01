---
kind: review
slug: govern-critique-rfc-review
date: 2026-08-31
status: complete
verified: 2026-08-31
phase: G2 + G5
---

# Review — G2 architecture critique + G5 RFCs

**Verdict: PASS** (after fixes in this review). Critique and RFC drafts accurately reflect the Phase G architecture plan. Human acceptance of RFC recommendations remains open before W1 build.

**Reviewed:**
- `docs/product/research/core-architecture-critique-20260831/review.md` (G2)
- `operating system/docs/rfc/rfc-004-semantics-delivery.md`
- `operating system/docs/rfc/rfc-005-metric-acl-phone-home.md`
- `operating system/docs/rfc/rfc-006-headless-surface.md`
- Plan: `narrowstack-core-architecture-20260831.md` (canonical; not stale `narrowstack-core-iac-spec-20260831.md`)

---

## Risk coverage (plan → critique → RFC)

| Plan risk | G2 critique | G5 RFC | Status |
|---|---|---|---|
| Semantics fork drift | § Proprietary — High; `semantics_template_version` + merge workflow | RFC-004 open Q on SHA vs tag; critique W3 merge tooling | Covered |
| ACL phone-home | § Proprietary — Medium; kill-switch must win | RFC-005 option 2; local authoritative at deploy | Covered |
| Legacy Airbyte divergence | § Legacy seven sites; two-Core-products Critical | RFC-006 option 4 (split demo track) | Covered |
| NRWSTK-945 core-app | Added cross-cutting risk row (was missing) | RFC-006 Problem + Recommendation | Fixed |
| OS-338 demo conflict | § Legacy + cross-cutting risks | RFC-006; G7 Linear (no separate RFC — per plan) | Covered |

---

## Findings and fixes applied

### Fail → fixed

| Issue | Fix |
|---|---|
| Critique cited RFC-005/006/007; actual files are RFC-004/005/006 | Renumbered all refs, handoff table, and inline mentions in critique |
| RFC-004 v2 trigger said fleet >10; critique said >15 | Aligned RFC-004 to >15 instances |
| RFC evidence links used nonexistent "Attack surface N" sections | Pointed to actual critique section headings |
| NRWSTK-945 absent from critique risk table | Added row under cross-cutting risks |
| Fork drift not in cross-cutting risks table | Added row (was only in proprietary section) |

### Pass (no change)

- No stale `topology` enum or `app_ref` in critique or RFCs; `warehouse.mode` only (D9)
- DRY: RFCs link to critique + feature specs; critique handoff table is single RFC index
- Semantics delivery scorecard and MSP ownership analysis match plan decisions D1, D5, D10
- Headless deprecation (D8) consistent with PRD non-goals

### Deferred (not blockers)

| Item | Owner | When |
|---|---|---|
| RFC human accept → ADR promotion | Operator + team | Before W1 (ACL) / W3 (semantics cut) |
| OS-338 Linear reconcile | G7 | No RFC — plan assigns to Linear only |
| Semantics repo ownership RFC | Optional | Enterprise customer before W3 |
| Stale `docs/plans/narrowstack-core-iac-spec-20260831.md` (T1/T2, `app_ref`) | G3/docs-gardener | Archive or supersede banner — out of G2/G5 scope |

---

## Per-artifact verdict

| Artifact | Verdict | Notes |
|---|---|---|
| G2 critique | **PASS** | Frontier adversarial coverage complete; discussion log notes no human acceptance yet |
| RFC-004 semantics delivery | **PASS** | v1 clone accepted; v2 trigger defined |
| RFC-005 metric ACL + phone-home | **PASS** | Three-layer model + consent-gated remote push; W1 stubs / W3+ functional |
| RFC-006 headless surface | **PASS** | D8 + NRWSTK-945/OS-338 split explicit |

---

## Sign-off gate

G2 + G5 docs are **ready for G6/G7**. Blockers for G8 remain: human RFC acceptance, Linear population, operator sign-off per `docs/reviews/wave-0-govern-review.md`.
