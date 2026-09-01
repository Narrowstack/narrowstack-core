# Feature — ns-core CLI (`ns-core-cli`)

_v0.1 · 2026-08-31 · mode: add · status: spec_
_Owner repo: narrowstack-core_

## Problem / job

**Operator persona** — PRD §Should S1. Headless v1 requires on-VM operations without SSH script archaeology. `narrowstack-core-app` deprecated; CLI is primary operator surface alongside modeling API.

## Proposal

`ns-core` CLI on VM with subcommands:

| Command | Scope | Wave |
|---|---|---|
| `status` | Instance health, pins, last green-check | W2 stub |
| `deploy` | Run green-check with manifest path | W4 functional |
| `rollback` | Invoke rollback.sh | W4 functional |
| `grants` | Telemetry grant management | W4 |
| `acl list` | Show effective principal permissions | W4 |
| `backup` / `restore` | Wrap backup scripts | W4 |

W2 ships stubs (`--help`, TODO output). W4 makes deploy/rollback/status functional.

## Non-goals

1. Remote CLI from outside VM in v1 — on-VM only
2. Chat or GUI subcommands
3. Replacing `op run` for secrets injection
4. Second contract parallel to modeling API for metrics

## Invariant checklist

| Invariant | How honored |
|---|---|
| Headless v1 (D8) | CLI replaces core-app operator flows |
| Rollback-first | `rollback` wraps same script as green-check failure path |
| Telemetry consent | `grants` follows phone-home protocol categories |
| Production feature gate | Stubs may ship in W2; functional commands only when verified |

## Data model / API delta

- `cli/ns-core` or `scripts/ns-core` entry point
- Reads `active-manifest.json` for status
- Delegates to `deploy/*.sh` — no duplicate deploy logic

## Verification plan

1. W2: `ns-core --help` lists all subcommands.
2. W4: `ns-core status` shows semantics_ref and last gate result.
3. W4: `ns-core deploy manifest.yaml` completes green-check successfully.
4. W4: `ns-core rollback` restores prior snapshot after induced failure.
5. W4: Non-builder completes deploy + rollback using CLI + guides only.

## Roadmap phase

W2 — TASK-018 (stubs); W5 — TASK-039 (functional). See `docs/product/roadmap.md`.

## Delta log

| Date | Change | Why |
|---|---|---|
| 2026-08-31 | Initial spec | Phase G4 |
