#!/usr/bin/env bash
# Render an absolute-path, fully-resolved MCP config to stdout, derived from the
# repo's mcp.json. We resolve `uvx` to an absolute path and substitute the live
# CB_* values into the env block — so we don't depend on whether `--mcp-config`
# expands ${VAR} placeholders (it may not).
set -euo pipefail

SRC="${MCP_SOURCE:-/work/mcp.json}"
[ -f "$SRC" ] || { echo "mcp-config.gen: $SRC not found" >&2; exit 1; }

UVX_BIN="$(command -v uvx || true)"
[ -n "$UVX_BIN" ] || { echo "mcp-config.gen: uvx not on PATH" >&2; exit 1; }

jq \
  --arg cmd "$UVX_BIN" \
  --arg cs "${CB_CONNECTION_STRING:-}" \
  --arg user "${CB_USERNAME:-}" \
  --arg pass "${CB_PASSWORD:-}" \
  --arg ro "${CB_MCP_READ_ONLY_MODE:-true}" \
  --arg disabled "${CB_MCP_DISABLED_TOOLS:-}" \
  --arg confirm "${CB_MCP_CONFIRMATION_REQUIRED_TOOLS:-}" \
  '
  .mcpServers.couchbase.command = $cmd
  | .mcpServers.couchbase.env = {
      "CB_CONNECTION_STRING": $cs,
      "CB_USERNAME": $user,
      "CB_PASSWORD": $pass,
      "CB_MCP_READ_ONLY_MODE": $ro,
      "CB_MCP_DISABLED_TOOLS": $disabled,
      "CB_MCP_CONFIRMATION_REQUIRED_TOOLS": $confirm
    }
  ' "$SRC"
