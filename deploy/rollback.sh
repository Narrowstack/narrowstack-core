#!/usr/bin/env bash
# rollback.sh — restore previous pins from latest pre-deploy snapshot.
# Default: invoked automatically by green-check on gate failure.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SNAPSHOT_DIR="${SNAPSHOT_DIR:-${REPO_ROOT}/.snapshots}"

usage() {
  echo "Usage: ${0##*/} [--snapshot <path>] [--dry-run]" >&2
  exit 2
}

latest_snapshot() {
  ls -1t "${SNAPSHOT_DIR}"/pre-deploy-*.json 2>/dev/null | head -1
}

main() {
  local snapshot="" dry_run=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --snapshot) snapshot="$2"; shift 2 ;;
      --dry-run) dry_run=1; shift ;;
      -h|--help) usage ;;
      *) echo "rollback: unknown arg: $1" >&2; exit 2 ;;
    esac
  done

  [ -n "${snapshot}" ] || snapshot="$(latest_snapshot || true)"
  [ -n "${snapshot}" ] || { echo "rollback: no snapshot found in ${SNAPSHOT_DIR}" >&2; exit 1; }
  [ -f "${snapshot}" ] || { echo "rollback: snapshot not found: ${snapshot}" >&2; exit 1; }

  echo "rollback: restoring from ${snapshot}"
  if [ "${dry_run}" -eq 1 ]; then
    cat "${snapshot}"
    echo "rollback: dry-run complete (W1 — re-run green-check on restored pins pending W2)"
    return 0
  fi

  # TODO (W2): restore semantics_ref pin, optional pg_dump, re-invoke green-check
  echo "rollback: stub complete — wire restore + green-check in W2"
}

main "$@"
