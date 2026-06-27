#!/usr/bin/env bash
# Thin POSIX wrapper over the Makefile so you don't have to remember to cd.
#   ./run.sh build
#   ./run.sh sandbox
#   ./run.sh sandbox-remote
#   ./run.sh sandbox-setup
#   ./run.sh smoke
#   ./run.sh clean
set -euo pipefail
cd "$(dirname "$0")"

cmd="${1:-help}"
shift || true

case "$cmd" in
  build|sandbox|sandbox-remote|sandbox-setup|sandbox-setup-remote|sandbox-setup-cold|smoke|clean|help)
    exec make "$cmd" "$@"
    ;;
  *)
    echo "usage: ./run.sh {build|sandbox|sandbox-remote|sandbox-setup|sandbox-setup-remote|sandbox-setup-cold|smoke|clean}" >&2
    exit 2
    ;;
esac
