#!/usr/bin/env bash
# allowlist-gate.sh — invoke the narrowstack-semantics allowlist verifier against
# the ref pinned in the manifest. Default-deny: shipping an unlisted model must
# abort the deploy.
#
# Wave 0 status: skeleton. The verifier lives in narrowstack-semantics
# (scripts/check-allowlist.py, W1). Here we only echo the intended invocation so
# the deploy contract and CI wiring exist first.
set -euo pipefail

usage() {
  echo "Usage: ${0##*/} <manifest.yaml>" >&2
  exit 2
}

main() {
  local manifest="${1:-}"
  [ -n "${manifest}" ] || usage

  local profile
  profile="$(grep -E '^allowlist_profile:' "${manifest}" | head -n1 | awk '{print $2}')"
  local semantics_ref
  semantics_ref="$(grep -E '^semantics_ref:' "${manifest}" | head -n1 | awk '{print $2}')"

  echo "allowlist-gate: profile=${profile:-<unset>} semantics_ref=${semantics_ref:-<unset>}"
  echo "allowlist-gate: TODO (W1) run narrowstack-semantics allowlist verifier:"
  echo "    python scripts/check-allowlist.py --profile ${profile:-customer-default}"
  echo "allowlist-gate: skeleton pass (no artifacts to check yet)."
}

main "$@"
