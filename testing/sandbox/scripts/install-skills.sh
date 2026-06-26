#!/usr/bin/env bash
# Install the skills into the fresh environment, from one of two sources:
#   local  (default) — copy skill dirs from the bind-mounted repo (/work/skills)
#                       into ~/.claude/skills so un-merged local edits are tested.
#   github           — install the published plugin from the marketplace.
set -euo pipefail

CFG="${CLAUDE_CONFIG_DIR:-/home/node/.claude}"   # match entrypoint.sh; container runs as non-root `node`
DEST="$CFG/skills"
MODE="${SKILL_INSTALL_MODE:-local}"
MARKETPLACE="${SKILLS_MARKETPLACE:-Couchbase-Ecosystem/agent-skills}"

case "$MODE" in
  local)
    mkdir -p "$DEST"
    shopt -s nullglob
    count=0
    for d in /work/skills/*/; do
      n="$(basename "$d")"
      case "$n" in _*) continue ;; esac          # skip _template etc.
      [ -f "$d/SKILL.md" ] || continue
      rm -rf "${DEST:?}/$n"
      cp -R "$d" "$DEST/$n"
      count=$((count + 1))
    done
    echo "[install-skills] mode=local — copied $count skill(s) into $DEST"
    [ "$count" -gt 0 ] || { echo "[install-skills] no skills found in /work/skills (is the repo mounted?)" >&2; exit 1; }
    ;;
  github)
    echo "[install-skills] mode=github — marketplace: $MARKETPLACE"
    # NOTE: the exact non-interactive plugin subcommand syntax can vary by CLI
    # version. Confirm with `claude plugin --help` and adjust if these fail.
    claude plugin marketplace add "$MARKETPLACE" </dev/null
    claude plugin install couchbase@couchbase-plugins --yes </dev/null
    echo "[install-skills] plugin 'couchbase' installed"
    ;;
  *)
    echo "[install-skills] unknown SKILL_INSTALL_MODE='$MODE' (use local|github)" >&2
    exit 2
    ;;
esac
