---
kind: process
slug: wave-review-gate
date: 2026-08-31
status: draft
verified: 2026-08-31
---

# Wave review gate

Every build wave (W0–W6) and Phase G sign-off (G8) requires a written review before the next wave opens.

## When

| Trigger | Review artifact |
|---|---|
| Phase G complete (G8) | `docs/reviews/wave-0-govern-review.md` |
| End of WN | `docs/reviews/wave-N-YYYYMMDD.md` (from [wave-build-review-template.md](../reviews/wave-build-review-template.md)) |

## Process

1. **Frontier review** — architecture/security/product pass on wave deliverables
2. **Fill review template** — verdict, gaps, sign-off table
3. **visual-recap** (optional) — shipped diff summary for operator
4. **Operator sign-off** — explicit authorization for next wave in review doc
5. **Linear** — close wave epic sub-tickets; move next epic to To-do

## Verdict options

- **Authorize next wave** — no blockers; proceed to TASK list for N+1
- **Defer** — named gaps must close before build continues
- **Reshape** — update roadmap/Linear; no code until docs reflect new scope

## Hard rules

- Phase B blocked until G8 sign-off (architecture D13)
- W6 explicitly deferrable until W4 gate passes
- No `build-loop` on a wave without its feature specs marked done in review checklist

## References

- Architecture plan § Implementation waves
- Roadmap: `docs/product/roadmap.md`
- G8 checklist: `docs/reviews/wave-0-govern-review.md`
