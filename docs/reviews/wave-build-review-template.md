---
kind: review
slug: wave-build-review-template
date: 2026-08-31
status: template
wave: N
---

# Wave review — WN build

_Copy to `docs/reviews/wave-N-YYYYMMDD.md` at end of each build wave._

## Scope reviewed

- [ ] Wave deliverables from `docs/product/roadmap.md` §WN
- [ ] Feature specs for this wave marked implemented or stubbed per acceptance
- [ ] `npm test` + `npm run lint:manifest` pass
- [ ] `green-check.sh` on example manifest (or tenant manifest when applicable)
- [ ] Security review on auth/secrets touch (W1, W4)
- [ ] No topology enum / `app_ref` in manifest or examples

## Verdict

| Option | Selected |
|---|---|
| **Authorize next wave** | ☐ |
| **Defer — gaps listed below** | ☐ |
| **Reshape scope — roadmap/Linear update required** | ☐ |

## Gaps / blockers

_List open items before WN+1 opens._

## Sign-off

| Role | Name | Date |
|---|---|---|
| Operator | | |
| Engineering | | |

## Next authorized wave

☐ W(N+1) · ☐ Other: _____

**Gate doc:** [wave-review-gate.md](../process/wave-review-gate.md)
