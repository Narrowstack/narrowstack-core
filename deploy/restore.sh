#!/usr/bin/env bash
# restore.sh — pull the backup named in the manifest, replay green-check steps
# 3-6, and verify a known question returns a known number (PRD step 10).
#
# Wave 0 status: skeleton. Wired against a live stack + backup target in W3.
set -euo pipefail

usage() {
  echo "Usage: ${0##*/} <manifest.yaml>" >&2
  exit 2
}

main() {
  local manifest="${1:-}"
  [ -n "${manifest}" ] || usage

  echo "restore: TODO (W3) pull backup per manifest backup.target_ref"
  echo "restore: TODO (W3) replay green-check steps 3-6"
  echo "restore: TODO (W3) verify known question returns known number"
  echo "restore: skeleton pass."
}

main "$@"
