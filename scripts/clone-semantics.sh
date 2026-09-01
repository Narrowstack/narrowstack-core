#!/usr/bin/env bash
# clone-semantics.sh — clone narrowstack-semantics at the ref pinned in the
# manifest so the deploy gate can run the allowlist verifier and dbt/MetricFlow
# against the pinned data contract.
#
# Wave 0 status: skeleton. The clone target is documented; wiring lands in W2.
set -euo pipefail

SEMANTICS_REPO="${SEMANTICS_REPO:-https://github.com/narrowstack/narrowstack-semantics.git}"

usage() {
  echo "Usage: ${0##*/} <manifest.yaml> [dest_dir]" >&2
  exit 2
}

main() {
  local manifest="${1:-}"
  local dest="${2:-.semantics}"
  [ -n "${manifest}" ] || usage
  [ -f "${manifest}" ] || {
    echo "clone-semantics: manifest not found: ${manifest}" >&2
    exit 1
  }

  local ref
  ref="$(grep -E '^semantics_ref:' "${manifest}" | head -n1 | awk '{print $2}')"
  [ -n "${ref}" ] || {
    echo "clone-semantics: semantics_ref not set in ${manifest}" >&2
    exit 1
  }

  echo "clone-semantics: TODO (W2) git clone ${SEMANTICS_REPO} -> ${dest} @ ${ref}"
  echo "clone-semantics: skeleton pass (ref=${ref})."
}

main "$@"
