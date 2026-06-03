#!/usr/bin/env bash
# CI wrapper — delegates to the repo's validator.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$ROOT/tools/validate-skills.sh"
