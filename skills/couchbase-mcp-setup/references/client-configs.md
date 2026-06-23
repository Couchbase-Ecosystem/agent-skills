# Per-client configuration

How to register the Couchbase MCP server in each harness, plus launch alternatives. The default launch command pins to the current minor version: `uvx --from "couchbase-mcp-server>=0.8.0,<0.9.0" couchbase-mcp-server` — it picks up `0.8.x` patches but not a potentially breaking `0.9`. (When the server reaches `1.0`, widen this to `>=1.0.0,<2.0.0`.)

## Claude Code

### Recommended — `claude mcp add --scope local`

Register the server with its credentials in Claude Code's own per-project config. The values are stored in `~/.claude.json` (outside your repo) and injected only into the server process — they are **never exported to your shell**, so they can't leak into other shells, tools, or projects:

```bash
claude mcp add couchbase --scope local \
  -e CB_CONNECTION_STRING="couchbases://cb.abc.cloud.couchbase.com" \
  -e CB_USERNAME="app_user" \
  -e CB_PASSWORD="…" \
  -- uvx --from "couchbase-mcp-server>=0.8.0,<0.9.0" couchbase-mcp-server
```

Add the optional safety vars the same way, e.g. `-e CB_MCP_READ_ONLY_MODE="false"`. Check it with `claude mcp list` / `claude mcp get couchbase`.

**Scopes** (highest precedence first; a same-named server in a higher scope wins outright — entries are *not* merged): `local` (default, this project only — **recommended for credentials**) › `project` (writes a committed `.mcp.json` — **don't put secrets here**) › `user` (all your projects) › plugin-provided. Because `local` outranks the plugin, this registration overrides the plugin's bundled `couchbase` server, so it works the same whether or not the plugin is installed — and needs no `${CB_*}` shell exports.

### Alternative — the plugin's bundled template

If you installed the Couchbase plugin, its bundled `mcp.json` defines `couchbase` and reads `${CB_*}` from the environment Claude Code is launched in. This route means the values live as environment variables, so **scope them to the project** — use a git-ignored `.envrc` loaded by `direnv` rather than a global `~/.zshrc` export:

```bash
# .envrc (git-ignored) — run `direnv allow` once, then restart Claude Code
export CB_CONNECTION_STRING="couchbases://cb.abc.cloud.couchbase.com"
export CB_USERNAME="app_user"
export CB_PASSWORD="…"
# optional — the bundled mcp.json passes these through if set:
# export CB_MCP_READ_ONLY_MODE="false"               # allow writes (default: true)
# export CB_MCP_DISABLED_TOOLS="tool_a,tool_b"        # drop specific tools
# export CB_MCP_CONFIRMATION_REQUIRED_TOOLS="tool_c"  # require confirmation before running
```

A global `~/.zshrc` export also works but is visible to every shell, subprocess, and project and persists indefinitely — keep it to throwaway local clusters, not Capella or production credentials. Apply with `/reload-plugins` or by restarting.

## Codex

Add to `~/.codex/config.toml` (Windows: `%USERPROFILE%\.codex\config.toml`):

```toml
[mcp_servers.couchbase]
command = "uvx"
args = ["--from", "couchbase-mcp-server>=0.8.0,<0.9.0", "couchbase-mcp-server"]

[mcp_servers.couchbase.env]
CB_CONNECTION_STRING = "couchbases://cb.abc.cloud.couchbase.com"
CB_USERNAME = "app_user"
CB_PASSWORD = "…"
```

Fully quit and relaunch Codex to apply (it does not inherit your shell env when launched from a GUI).

## Cursor / Windsurf / Claude Desktop

Add this JSON `mcpServers` entry in the client's MCP settings:

```json
{
  "mcpServers": {
    "couchbase": {
      "command": "uvx",
      "args": ["--from", "couchbase-mcp-server>=0.8.0,<0.9.0", "couchbase-mcp-server"],
      "env": {
        "CB_CONNECTION_STRING": "couchbases://cb.abc.cloud.couchbase.com",
        "CB_USERNAME": "app_user",
        "CB_PASSWORD": "…"
      }
    }
  }
}
```

Where to put it:
- **Cursor:** Settings → Tools & Integrations → MCP Tools.
- **Windsurf:** Command Palette → Windsurf MCP Configuration (or Settings → Advanced → Cascade → MCP Servers).
- **Claude Desktop:** `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) / `%APPDATA%\Claude\claude_desktop_config.json` (Windows).

## Switching clusters

One server instance connects to a single cluster, fixed at startup via `CB_CONNECTION_STRING` — there is no tool to switch clusters at runtime. To point the server at a different cluster, update `CB_CONNECTION_STRING` and the credentials in the config above and restart the client.

## Launch alternatives

Swap the `command`/`args` in any of the blocks above.

**Docker** (no Python toolchain needed). Docker tags can't express a range, so use the floating minor tag `:0.8` to track `0.8.x` patches (matching the uvx range above). For a **local** cluster, use `host.docker.internal` in the connection string:

```json
{
  "command": "docker",
  "args": ["run", "--rm", "-i",
    "-e", "CB_CONNECTION_STRING=couchbase://host.docker.internal",
    "-e", "CB_USERNAME=Administrator",
    "-e", "CB_PASSWORD=…",
    "couchbaseecosystem/mcp-server-couchbase:0.8"]
}
```

**From source** (handy while developing the server):

```json
{
  "command": "uv",
  "args": ["--directory", "/path/to/mcp-server-couchbase/", "run", "src/mcp_server.py"]
}
```

## Streamable HTTP transport

By default the server uses `stdio` — the local transport coding agents launch directly. To run it instead as a long-lived networked server that multiple clients can share, start it with the `http` (Streamable HTTP) transport:

```bash
CB_CONNECTION_STRING="couchbases://cb.abc.cloud.couchbase.com" \
CB_USERNAME="app_user" CB_PASSWORD="…" \
CB_MCP_READ_ONLY_MODE="true" \
CB_MCP_TRANSPORT="http" CB_MCP_HOST="127.0.0.1" CB_MCP_PORT="8000" \
uvx --from "couchbase-mcp-server>=0.8.0,<0.9.0" couchbase-mcp-server
```

- `CB_MCP_TRANSPORT=http` selects Streamable HTTP (the legacy `sse` transport is deprecated).
- `CB_MCP_HOST` (default `127.0.0.1`) and `CB_MCP_PORT` (default `8000`) set the bind address; the endpoint is `http://<host>:<port>/mcp`.
- This mode has **no authorization support** — bind it to localhost or a trusted network only.

Then point a client at the URL instead of giving it a launch command:

```json
{
  "mcpServers": {
    "couchbase-http": {
      "url": "http://localhost:8000/mcp"
    }
  }
}
```

(Claude Code: `claude mcp add --transport http couchbase-http http://localhost:8000/mcp`.)

## Useful checks

- Version: `uvx couchbase-mcp-server --version`
- Read-only toggle: set `CB_MCP_READ_ONLY_MODE` to `"false"` in the `env` block to allow writes (default `"true"`).
- Disable tools / require confirmation: set `CB_MCP_DISABLED_TOOLS` and/or `CB_MCP_CONFIRMATION_REQUIRED_TOOLS` to comma-separated tool names (or a file path); empty means none.
- Transport defaults to `stdio` (what coding agents use); `http` (Streamable HTTP) is for networked deployments. The legacy `sse` transport is deprecated — use `http` instead.
