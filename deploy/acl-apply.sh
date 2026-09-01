#!/usr/bin/env bash
# acl-apply.sh — apply ACL policy from local manifest or phone-home signed bundle.
set -euo pipefail

usage() {
  echo "Usage: ${0##*/} [--dry-run] [--source local|phone_home]" >&2
  exit 2
}

main() {
  local dry_run=0 source="local"
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run) dry_run=1; shift ;;
      --source) source="$2"; shift 2 ;;
      -h|--help) usage ;;
      *) echo "acl-apply: unknown arg: $1" >&2; exit 2 ;;
    esac
  done

  echo "acl-apply: stub (W3) — source=${source} dry_run=${dry_run}"
  echo "acl-apply: local kill-switch overrides any remote policy (RFC-005)"
}

main "$@"
