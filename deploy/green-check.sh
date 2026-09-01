#!/usr/bin/env bash
# green-check.sh — orchestrate rollback-first green deploy checklist.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
AUTO_ROLLBACK="${AUTO_ROLLBACK:-1}"

usage() {
  echo "Usage: ${0##*/} [--no-auto-rollback] <manifest.yaml>" >&2
  exit 2
}

run_gates() {
  local manifest="$1"
  echo "==> [1/9] Provision VM: Cloud substrate (out of repo scope)"
  echo "==> [2/9] pre-deploy-snapshot"
  "${SCRIPT_DIR}/pre-deploy-snapshot.sh" "${manifest}"
  echo "==> [3/9] Validate manifest"
  node "${REPO_ROOT}/scripts/lint-manifest.mjs" "${manifest}"
  echo "==> [4/9] Clone semantics at semantics_ref (TODO: W2)"
  echo "==> [5/9] Pipelines + dbt seed/run/parse (TODO: W2)"
  echo "==> [6/9] Allowlist gate"
  "${SCRIPT_DIR}/allowlist-gate.sh" "${manifest}"
  echo "==> [7/9] ACL smoke"
  "${SCRIPT_DIR}/acl-smoke.sh" "${manifest}"
  echo "==> [8/9] Tie-out + smoke query (TODO: W3/W4)"
  "${SCRIPT_DIR}/smoke-query.sh" "${manifest}"
  echo "==> [9/9] Telemetry T0 verify (TODO: W3)"
  echo "green-check: gates passed (runtime stubs through W2/W3)"
}

main() {
  local manifest="" no_auto=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-auto-rollback) no_auto=1; shift ;;
      -h|--help) usage ;;
      *)
        manifest="$1"
        shift
        ;;
    esac
  done
  [ -n "${manifest}" ] || usage
  [ -f "${manifest}" ] || { echo "green-check: manifest not found: ${manifest}" >&2; exit 1; }

  if run_gates "${manifest}"; then
    echo "green-check: success"
  else
    local rc=$?
    if [ "${no_auto}" -eq 0 ] && [ "${AUTO_ROLLBACK}" -eq 1 ]; then
      echo "green-check: failure — invoking rollback.sh" >&2
      "${SCRIPT_DIR}/rollback.sh" || true
    fi
    exit "${rc}"
  fi
}

main "$@"
