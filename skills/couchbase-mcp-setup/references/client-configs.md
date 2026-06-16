# Per-client configuration

How to register the Couchbase MCP server in each harness, plus launch alternatives. The default launch command pins to the current minor version: `uvx --from 'couchbase-mcp-server>=0.8.0,<0.9.0' couchbase-mcp-server` — it picks up `0.8.x` patches but not a potentially breaking `0.9`. (When the server reaches `1.0`, widen this to `>=1.0.0,<2.0.0`.)

## Claude Code

### With the Couchbase plugin installed (recommended)

The plugin's bundled `mcp.json` already defines the `couchbase` server and reads `${CB_*}` from your environment. Just set the values persistently in your shell profile:

```bash
# ~/.zshrc (or ~/.bashrc) — then: source ~/.zshrc && restart Claude Code
export CB_CONNECTION_STRING="couchbases://cb.abc.cloud.couchbase.com"
export CB_USERNAME="app_user"
export CB_PASSWORD="…"
```

This keeps secrets out of any committed/config file. Apply with `/reload-plugins` or by restarting.

### Manual (no plugin)

Register the server directly (values are stored in `~/.claude.json`):

```bash
claude mcp add couchbase --scope user \
  -e CB_CONNECTION_STRING="couchbases://cb.abc.cloud.couchbase.com" \
  -e CB_USERNAME="app_user" \
  -e CB_PASSWORD="…" \
  -- uvx --from 'couchbase-mcp-server>=0.8.0,<0.9.0' couchbase-mcp-server
```

Check it with `claude mcp list` / `claude mcp get couchbase`. Scopes: `--scope user` (all projects), `project` (writes `.mcp.json`, shared), `local` (default, this project only).

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

## Multiple clusters (named connections)

One server instance connects to a single cluster (all of its buckets are reachable), so to work with multiple **clusters** register **distinct named servers** and address them by name:

```bash
claude mcp add couchbase-prod    --scope user -e CB_CONNECTION_STRING="couchbases://prod…"    -e CB_USERNAME="…" -e CB_PASSWORD="…" -- uvx --from 'couchbase-mcp-server>=0.8.0,<0.9.0' couchbase-mcp-server
claude mcp add couchbase-staging --scope user -e CB_CONNECTION_STRING="couchbases://staging…" -e CB_USERNAME="…" -e CB_PASSWORD="…" -- uvx --from 'couchbase-mcp-server>=0.8.0,<0.9.0' couchbase-mcp-server
```

(The same idea applies in `config.toml`/JSON — use a distinct key per cluster.)

## Launch alternatives

Swap the `command`/`args` in any of the blocks above.

**Docker** (no Python toolchain needed). Docker tags can't express a range, so pin to an exact version (e.g. `:0.8.0`). For a **local** cluster, use `host.docker.internal` in the connection string:

```json
{
  "command": "docker",
  "args": ["run", "--rm", "-i",
    "-e", "CB_CONNECTION_STRING=couchbase://host.docker.internal",
    "-e", "CB_USERNAME=Administrator",
    "-e", "CB_PASSWORD=…",
    "couchbaseecosystem/mcp-server-couchbase:0.8.0"]
}
```

**From source** (handy while developing the server):

```json
{
  "command": "uv",
  "args": ["--directory", "/path/to/mcp-server-couchbase/", "run", "src/mcp_server.py"]
}
```

## Useful checks

- Version: `uvx couchbase-mcp-server --version`
- Read-only toggle: set `CB_MCP_READ_ONLY_MODE` to `"false"` in the `env` block to allow writes (default `"true"`).
- Transport defaults to `stdio` (what coding agents use); `http` (Streamable HTTP) is for networked deployments. The legacy `sse` transport is deprecated — use `http` instead.
