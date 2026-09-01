#!/usr/bin/env bash
# acl-smoke.sh — verify each manifest principal sees only permitted metrics.
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
  python3 "${REPO_ROOT}/semantics/scripts/smoke_test.py" "${manifest}"
}

main "$@"
