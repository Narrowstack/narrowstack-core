#!/usr/bin/env bash
# smoke-query.sh — run a MetricFlow smoke query (and optionally one chat path)
# to confirm the instance answers a known question with a known number.
#
# Wave 0 status: skeleton. Wired against a live stack in W3.
set -euo pipefail

usage() {
  echo "Usage: ${0##*/} <manifest.yaml>" >&2
  exit 2
}

main() {
  local manifest="${1:-}"
  [ -n "${manifest}" ] || usage

  echo "smoke-query: TODO (W3) run 'mf query' against the deployed warehouse"
  echo "smoke-query: TODO (W3) exercise one chat path via narrowstack-core-app"
  echo "smoke-query: skeleton pass."
}

main "$@"
