#!/usr/bin/env bash
# pre-deploy-snapshot.sh — record active pins before green-check mutates state.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SNAPSHOT_DIR="${SNAPSHOT_DIR:-${REPO_ROOT}/.snapshots}"
SNAPSHOT_FILE="${SNAPSHOT_DIR}/pre-deploy-$(date +%Y%m%dT%H%M%S).json"

usage() {
  echo "Usage: ${0##*/} <manifest.yaml>" >&2
  exit 2
}

main() {
  local manifest="${1:-}"
  [ -n "${manifest}" ] || usage
  [ -f "${manifest}" ] || { echo "snapshot: manifest not found: ${manifest}" >&2; exit 1; }

  mkdir -p "${SNAPSHOT_DIR}"
  local manifest_hash
  manifest_hash="$(sha256sum "${manifest}" | awk '{print $1}')"

  cat > "${SNAPSHOT_FILE}" <<EOF
{
  "recorded_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "core_ref": "$(git -C "${REPO_ROOT}" rev-parse HEAD 2>/dev/null || echo unknown)",
  "semantics_ref": "(read from manifest at deploy time)",
  "manifest_path": "${manifest}",
  "manifest_hash": "${manifest_hash}",
  "pg_dump_ref": null
}
EOF
  echo "pre-deploy-snapshot: wrote ${SNAPSHOT_FILE}"
  echo "${SNAPSHOT_FILE}"
}

main "$@"
