#!/usr/bin/env bash
# green-check.sh — orchestrate the ordered green deploy checklist for one instance.
#
# Ordered gate (packaging spec §7):
#   1. Provision VM (Cloud) — out of repo scope; manifest records result
#   2. Build stack from manifest
#   3. Load enabled sources -> dbt seed/run/parse
#   4. Allowlist check — fail with model name on violation
#   5. Tie-out run — all shipped metrics with validators
#   6. Smoke query — mf query + one chat path
#   7. Telemetry T0 — no grants active; verifiable
#
# Wave 0 status: skeleton. Steps beyond manifest lint are stubbed and clearly
# marked TODO so CI (shellcheck) and the deploy contract exist before wiring.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
  echo "Usage: ${0##*/} <manifest.yaml>" >&2
  exit 2
}

main() {
  local manifest="${1:-}"
  [ -n "${manifest}" ] || usage
  [ -f "${manifest}" ] || {
    echo "green-check: manifest not found: ${manifest}" >&2
    exit 1
  }

  echo "==> [1/7] Provision VM: recorded by Cloud (out of repo scope)"

  echo "==> [2/7] Validate manifest against schema"
  node "${REPO_ROOT}/scripts/lint-manifest.mjs" "${manifest}"

  echo "==> [3/7] Load enabled sources -> dbt seed/run/parse  (TODO: W2)"
  echo "==> [4/7] Allowlist check                             (delegates to allowlist-gate.sh, W1)"
  "${SCRIPT_DIR}/allowlist-gate.sh" "${manifest}" || {
    echo "green-check: allowlist gate failed" >&2
    exit 1
  }
  echo "==> [5/7] Tie-out run                                 (TODO: W3)"
  echo "==> [6/7] Smoke query                                 (delegates to smoke-query.sh, W3)"
  "${SCRIPT_DIR}/smoke-query.sh" "${manifest}"
  echo "==> [7/7] Telemetry T0: verifying no grants active    (TODO: W3)"

  echo "green-check: manifest is valid; runtime gates are stubbed pending later waves."
}

main "$@"
