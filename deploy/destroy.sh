#!/usr/bin/env bash
# destroy.sh — stop the compose stack, optionally wipe the volume per manifest
# flag, and write an audit-log entry.
#
# Wave 0 status: skeleton. Wired against compose in W2/W3.
set -euo pipefail

usage() {
  echo "Usage: ${0##*/} <manifest.yaml>" >&2
  exit 2
}

main() {
  local manifest="${1:-}"
  [ -n "${manifest}" ] || usage

  echo "destroy: TODO (W2) docker compose down for the tenant stack"
  echo "destroy: TODO (W3) optional volume wipe per manifest flag"
  echo "destroy: TODO (W3) append audit-log entry"
  echo "destroy: skeleton pass."
}

main "$@"
