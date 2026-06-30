#!/usr/bin/env bash
# Container entrypoint. Guarantees a fresh Claude Code environment, installs the
# skills, wires the Couchbase MCP server, brings up / waits for the cluster, then
# launches an interactive sandbox REPL.
set -euo pipefail

# Clean room: drop any inherited observability/telemetry config so Claude Code
# doesn't trip the "managed settings require approval" gate in headless mode.
# (CLAUDE_CODE_ENABLE_TELEMETRY + OTEL_* are commonly set in corporate shells.)
for v in ${!OTEL_@}; do unset "$v"; done
unset CLAUDE_CODE_ENABLE_TELEMETRY 2>/dev/null || true
export CLAUDE_CODE_ENABLE_TELEMETRY=0

# Ensure the node-local npm bin (where `claude` lives) and uv are always found.
export PATH="/home/node/.npm-global/bin:/usr/local/bin:${PATH}"

CFG="${CLAUDE_CONFIG_DIR:-/home/node/.claude}"
MODE="${SKILL_INSTALL_MODE:-local}"
MCP_CONFIG=/tmp/harness-mcp.json     # node-writable; /opt/harness is root-owned

echo "==> Fresh Claude Code environment ($CFG)"
# Double-locked freshness: the container is ephemeral (--rm, no host ~/.claude
# mount) AND we wipe the config dir here, so no cached skills/config survive.
rm -rf "$CFG"
mkdir -p "$CFG"
# Auto-trust MCP servers so a headless run never blocks on a prompt.
# (--dangerously-skip-permissions covers tool-call permissions; this covers
# MCP-server trust.)
cat > "$CFG/settings.json" <<'JSON'
{
  "approveMcpJsonServers": true,
  "enableAllProjectMcpServers": true
}
JSON

# --- auth: prefer the OAuth token; fall back to an API key ---
# NOTE: headless `claude -p` reads CLAUDE_CODE_OAUTH_TOKEN from the env, but the
# INTERACTIVE REPL authenticates from $CFG/.credentials.json instead — so without
# seeding that file the sandbox would prompt for a manual /login on every run (the
# config dir is wiped above). We seed it from the same token so neither mode needs
# a login. Skills/config stay fully fresh; only auth state is re-seeded.
# (expiresAt is set far in the future: setup-token tokens are long-lived; if the
# token is ever revoked/expired you'll get an auth error — re-run `claude setup-token`.)
if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
  unset ANTHROPIC_API_KEY 2>/dev/null || true   # avoid precedence ambiguity
  jq -n --arg t "$CLAUDE_CODE_OAUTH_TOKEN" \
    '{claudeAiOauth:{accessToken:$t, refreshToken:"", expiresAt:4102444800000, scopes:["user:inference","user:profile"], subscriptionType:"max"}}' \
    > "$CFG/.credentials.json"
  chmod 600 "$CFG/.credentials.json"
  echo "==> Auth: CLAUDE_CODE_OAUTH_TOKEN (seeded $CFG/.credentials.json — no login needed)"
elif [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  echo "==> Auth: ANTHROPIC_API_KEY (fallback)"
else
  echo "FATAL: no credentials. Set CLAUDE_CODE_OAUTH_TOKEN (run 'claude setup-token'" >&2
  echo "       on your host) or ANTHROPIC_API_KEY in testing/sandbox/.env." >&2
  exit 2
fi

# Skip Claude Code's first-run wizard (onboarding + bypass-permissions warning) so
# the sandbox REPL drops straight in instead of prompting. Re-created fresh each
# run since the config dir was wiped above.
cat > "$CFG/.claude.json" <<'JSON'
{
  "hasCompletedOnboarding": true,
  "bypassPermissionsModeAccepted": true,
  "theme": "dark"
}
JSON

# --- skills (local copy or github plugin) ---
/opt/harness/scripts/install-skills.sh

# --- cluster coordinates ---
# In LOCAL mode the cluster coordinates are FIXED by the harness, overriding any
# inherited CB_* — so a dangling host/Capella value can never leak into the run.
# In REMOTE mode we use the CB_* supplied via .env as-is.
if [ "${CB_PROFILE:-local}" = "local" ]; then
  # CB_LOCAL_PASSWORD is the canonical name; CB_PASSWORD is accepted for existing .env files.
  _local_pw="${CB_LOCAL_PASSWORD:-${CB_PASSWORD:-}}"
  if [ -z "$_local_pw" ]; then
    echo "FATAL: no local password set. Add CB_LOCAL_PASSWORD to testing/sandbox/.env (see .env.example)." >&2
    exit 2
  fi
  export CB_CONNECTION_STRING="couchbase://couchbase"
  export CB_USERNAME="${CB_LOCAL_USERNAME:-tester}"
  export CB_PASSWORD="$_local_pw"
  export CB_MCP_READ_ONLY_MODE="${CB_MCP_READ_ONLY_MODE:-true}"
  export CB_ADMIN_USERNAME="${CB_ADMIN_USERNAME:-Administrator}"
  # CB_ADMIN_PASSWORD is only used by couchbase-init.sh to provision the local container;
  # defaults to the db password if not explicitly overridden.
  export CB_ADMIN_PASSWORD="${CB_ADMIN_PASSWORD:-$_local_pw}"
  echo "==> Local cluster: $CB_CONNECTION_STRING (db user: $CB_USERNAME)"
elif [ "${HARNESS_PREWIRE_MCP:-1}" = "0" ] && [ -z "${CB_CONNECTION_STRING:-}" ]; then
  # Remote setup-flow target with nothing preset: let the couchbase-mcp-setup skill
  # gather the Capella connection string + cluster-access creds itself (cold path).
  echo "==> Remote setup mode: no CB_CONNECTION_STRING preset — the couchbase-mcp-setup"
  echo "    skill will gather your Capella connection string + cluster-access creds."
else
  : "${CB_CONNECTION_STRING:?remote mode needs CB_CONNECTION_STRING — set it in .env}"
  echo "==> Remote cluster: $CB_CONNECTION_STRING"
fi

# --- MCP wiring ---
# Normally we PRE-WIRE the MCP server so the querying/optimizer skills work out of
# the box: render an absolute-path .mcp.json from the repo's mcp.json with the
# (now-finalized) CB_* resolved, passed via --mcp-config --strict-mcp-config.
#   github skills: the installed plugin supplies the MCP server config instead.
# HARNESS_PREWIRE_MCP=0 (the `*-setup` targets) SKIPS this entirely so the REPL
# starts with NO server connected — the state the couchbase-mcp-setup skill expects
# to drive `claude mcp add` / config edits itself.
PREWIRE="${HARNESS_PREWIRE_MCP:-1}"
# HARNESS_SEED_CB_ENV=0 (the `*-cold` target) additionally strips every CB_* from the
# session env just before launching the REPL, so the agent starts with no connection
# hints at all — a true first-time setup. The cluster is still provisioned; the values
# are only removed from what `claude` inherits (the skill re-supplies them).
SEED_CB_ENV="${HARNESS_SEED_CB_ENV:-1}"
MCP_ARGS=()
if [ "$PREWIRE" = "0" ]; then
  echo "==> MCP NOT pre-wired (setup-flow mode) — connect it via the couchbase-mcp-setup skill"
elif [ "$MODE" = "local" ]; then
  /opt/harness/scripts/mcp-config.gen.sh > "$MCP_CONFIG"
  echo "==> MCP config rendered to $MCP_CONFIG"
  MCP_ARGS=(--mcp-config "$MCP_CONFIG" --strict-mcp-config)
fi

# --- bring up / verify the local cluster ---
if [ "${CB_PROFILE:-local}" = "local" ]; then
  /opt/harness/scripts/wait-for-couchbase.sh
  /opt/harness/scripts/couchbase-init.sh
fi

# --- dispatch ---
case "${HARNESS_MODE:-sandbox}" in
  sandbox)
    if [ "$PREWIRE" = "0" ]; then
      echo "==> Sandbox (MCP SETUP mode): fresh REPL, NO MCP server pre-wired (Ctrl-D to exit)"
      echo "    \`claude mcp list\` shows nothing connected — the starting state the setup skill expects."
      echo "    To test it, ask:  \"Set up the Couchbase MCP server.\""
      if [ "$SEED_CB_ENV" = "0" ]; then
        echo "    FIRST-TIME mode: no CB_* in the environment either (\`env | grep CB_\` is empty)."
        echo "    The skill must gather every value from scratch, like a brand-new user."
        if [ "${CB_PROFILE:-local}" = "local" ]; then
          echo "    Your local cluster — give these to the skill when it asks:"
          echo "      connection string : couchbase://couchbase"
          echo "      database user     : ${CB_USERNAME:-tester}"
          echo "      password          : $CB_PASSWORD"
        else
          echo "    Target your Capella cluster; the skill will gather the connection string + creds."
        fi
      elif [ "${CB_PROFILE:-local}" = "local" ]; then
        echo "    Target the bundled local cluster: couchbase://couchbase  (db creds are pre-set in the env)."
      else
        echo "    Target your Capella cluster (the skill will use/gather the connection string + creds)."
      fi
      echo "    Tip: after the skill runs \`claude mcp add\`, use \`/mcp\` (or restart) to load the server."
      # First-time mode: strip every CB_* so the session truly starts blind. These were
      # only needed to provision the cluster above; the skill re-supplies them via
      # `claude mcp add -e CB_...`, independent of the session env.
      if [ "$SEED_CB_ENV" = "0" ]; then
        for v in ${!CB_@}; do unset "$v"; done
      fi
    else
      echo "==> Sandbox: fresh interactive Claude Code REPL (Ctrl-D to exit)"
      echo "    Try: \"How many airports are in France? Use travel-sample.\""
    fi
    exec claude "${MCP_ARGS[@]}" --dangerously-skip-permissions
    ;;
  test)
    # Headless tests: drive `claude -p` across the curated eval cases and score
    # skill-triggering + MCP tool calls + the answer. All setup (skills, MCP
    # render, cluster init) already ran above; just forward the MCP config the
    # same way the sandbox REPL receives it.
    #   HARNESS_TEST_SELECT=smoke      (default) — the one-per-skill gate
    #   HARNESS_TEST_SELECT=scenarios            — the broader curated set
    #   HARNESS_TEST_SELECT=all                  — every case in the tier range
    RUNNER_ARGS=(--repo /work)
    case "${HARNESS_TEST_SELECT:-smoke}" in
      smoke)     RUNNER_ARGS+=(--smoke) ;;
      scenarios) RUNNER_ARGS+=(--scenarios) ;;
      all)       : ;;   # tier-based default in run-tests.py
      *) echo "WARN: unknown HARNESS_TEST_SELECT='${HARNESS_TEST_SELECT}', using smoke" >&2
         RUNNER_ARGS+=(--smoke) ;;
    esac
    if [ "$MODE" = "github" ]; then
      RUNNER_ARGS+=(--github)              # plugin supplies skills + MCP server
    elif [ "$PREWIRE" != "0" ] && [ "$MODE" = "local" ] && [ -f "$MCP_CONFIG" ]; then
      RUNNER_ARGS+=(--mcp-config "$MCP_CONFIG")
    fi
    if [ "${HARNESS_SHOW_STREAM:-0}" = "1" ]; then
      RUNNER_ARGS+=(--show-stream)         # dump raw stream-json to confirm event shapes
    fi
    if [ -n "${HARNESS_TEST_ARGS:-}" ]; then
      # Extra runner flags for ad-hoc runs, e.g. HARNESS_TEST_ARGS="--skill X --case Y".
      # Word-split intentionally so multiple flags pass through; disable globbing
      # (set -f) around the expansion so a literal * or ? in a flag isn't expanded
      # against the working directory's files. Restored with set +f immediately after.
      set -f
      # shellcheck disable=SC2206
      RUNNER_ARGS+=(${HARNESS_TEST_ARGS})
      set +f
    fi
    echo "==> Tests (${HARNESS_TEST_SELECT:-smoke}): headless \`claude -p\` across the curated eval cases"
    exec python3 /opt/harness/run-tests.py "${RUNNER_ARGS[@]}"
    ;;
  *)
    echo "FATAL: unknown HARNESS_MODE='${HARNESS_MODE:-}' (use 'sandbox' or 'test')" >&2
    exit 2
    ;;
esac
