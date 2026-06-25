# Per-client configuration

The Couchbase MCP server is a standard MCP server — it works with **any MCP-compatible client**, not only the ones below. Every client registers it the same way: a server entry with a `command` (`uvx`), `args`, and an `env` map holding `CB_CONNECTION_STRING` / `CB_USERNAME` / `CB_PASSWORD`. The blocks below differ only in *where* that entry lives and minor syntax (notably VS Code's top-level key). For a client not listed here, drop the same entry into its MCP config file.

How to register the Couchbase MCP server in each harness, plus launch alternatives. The default launch command is `uvx --from "couchbase-mcp-server>=0.8.0,<1.1.0" couchbase-mcp-server` — it accepts the current `0.8.x` line and the upcoming `1.0.x` release, but not a potentially breaking `1.1`. The range deliberately spans the `1.0` upgrade so the **same spec keeps working before and after `1.0` ships** (it resolves `0.8.x` today and rolls forward to `1.0.x` automatically). Note that `1.0` removes `CB_MCP_READ_ONLY_QUERY_MODE` and flips the `CB_MCP_READ_ONLY_MODE` default to `false` — so on the routes below **always set `CB_MCP_READ_ONLY_MODE` explicitly** rather than relying on the server default.

## Claude Code

### Recommended — `claude mcp add --scope local`

Register the server with its credentials in Claude Code's own per-project config. The values are stored in `~/.claude.json` (outside your repo) and injected only into the server process — they are **never exported to your shell**, so they can't leak into other shells, tools, or projects:

```bash
claude mcp add couchbase --scope local \
  -e CB_CONNECTION_STRING="couchbases://cb.abc.cloud.couchbase.com" \
  -e CB_USERNAME="app_user" \
  -e CB_PASSWORD="…" \
  -e CB_MCP_READ_ONLY_MODE="true" \
  -- uvx --from "couchbase-mcp-server>=0.8.0,<1.1.0" couchbase-mcp-server
```

Set `CB_MCP_READ_ONLY_MODE` **explicitly** as shown — don't omit it. The server's own default is `true` on `0.8.x` but flips to `false` on `1.0+`, and the version range above spans both, so relying on the default could silently enable writes. To enable writes instead, pass `-e CB_MCP_READ_ONLY_MODE="false"` (and on `0.8.x` also `-e CB_MCP_READ_ONLY_QUERY_MODE="false"` to clear the deprecated query-write block — harmless on `1.0+`, which has removed it). Check it with `claude mcp list` / `claude mcp get couchbase`.

**Scopes** (highest precedence first; a same-named server in a higher scope wins outright — entries are *not* merged): `local` (default, this project only — **recommended for credentials**) › `project` (writes a committed `.mcp.json` — **don't put secrets here**) › `user` (all your projects) › plugin-provided. Because `local` outranks the plugin, this registration overrides the plugin's bundled `couchbase` server, so it works the same whether or not the plugin is installed — and needs no `${CB_*}` shell exports.

### Alternative — the plugin's bundled template

If you installed the Couchbase plugin, its bundled `mcp.json` defines `couchbase` and pins the safety defaults; the server inherits `CB_CONNECTION_STRING`, `CB_USERNAME`, and `CB_PASSWORD` from the environment Claude Code is launched in. This route means the credentials live as environment variables, so **scope them to the project** — use a git-ignored `.envrc` loaded by `direnv` rather than a global `~/.zshrc` export:

```bash
# .envrc (git-ignored) — run `direnv allow` once, then restart Claude Code
export CB_CONNECTION_STRING="couchbases://cb.abc.cloud.couchbase.com"
export CB_USERNAME="app_user"
export CB_PASSWORD="…"
# optional — the bundled mcp.json passes these through if set:
# export CB_MCP_READ_ONLY_MODE="false"               # allow writes — the only switch you need here (default: true)
# export CB_MCP_DISABLED_TOOLS="tool_a,tool_b"        # drop specific tools
# export CB_MCP_CONFIRMATION_REQUIRED_TOOLS="tool_c"  # require confirmation before running
```

A global `~/.zshrc` export also works but is visible to every shell, subprocess, and project and persists indefinitely — keep it to throwaway local clusters, not Capella or production credentials. Apply with `/reload-plugins` or by restarting.

## Codex

Add to `~/.codex/config.toml` (Windows: `%USERPROFILE%\.codex\config.toml`):

```toml
[mcp_servers.couchbase]
command = "uvx"
args = ["--from", "couchbase-mcp-server>=0.8.0,<1.1.0", "couchbase-mcp-server"]

[mcp_servers.couchbase.env]
CB_CONNECTION_STRING = "couchbases://cb.abc.cloud.couchbase.com"
CB_USERNAME = "app_user"
CB_PASSWORD = "…"
CB_MCP_READ_ONLY_MODE = "true"
```

Fully quit and relaunch Codex to apply (it does not inherit your shell env when launched from a GUI). Set `CB_MCP_READ_ONLY_MODE` explicitly (as above) on every direct-config route — its server default flips from `true` to `false` across the `1.0` upgrade the version range spans.

## Cursor / Windsurf / Claude Desktop / JetBrains

Add this JSON `mcpServers` entry in the client's MCP settings:

```json
{
  "mcpServers": {
    "couchbase": {
      "command": "uvx",
      "args": ["--from", "couchbase-mcp-server>=0.8.0,<1.1.0", "couchbase-mcp-server"],
      "env": {
        "CB_CONNECTION_STRING": "couchbases://cb.abc.cloud.couchbase.com",
        "CB_USERNAME": "app_user",
        "CB_PASSWORD": "…",
        "CB_MCP_READ_ONLY_MODE": "true"
      }
    }
  }
}
```

Where to put it:
- **Cursor:** Settings → Tools & Integrations → MCP Tools.
- **Windsurf:** Command Palette → Windsurf MCP Configuration (or Settings → Advanced → Cascade → MCP Servers).
- **Claude Desktop:** `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) / `%APPDATA%\Claude\claude_desktop_config.json` (Windows).
- **JetBrains** (IntelliJ, PyCharm, etc.): Settings → Tools → AI Assistant (or Junie) → MCP Server → **+**. Requires the AI Assistant or Junie plugin.

## VS Code

VS Code (MCP support via GitHub Copilot) registers the server the same way, with **two differences** from the JSON block above:

1. The top-level key is **`servers`**, not `mcpServers`.
2. The config lives in `.vscode/mcp.json` (workspace scope) or the user config — open the latter with **MCP: Open User Configuration** from the Command Palette (on macOS it's `~/Library/Application Support/Code/User/mcp.json`).

```json
{
  "servers": {
    "couchbase": {
      "command": "uvx",
      "args": ["--from", "couchbase-mcp-server>=0.8.0,<1.1.0", "couchbase-mcp-server"],
      "env": {
        "CB_CONNECTION_STRING": "couchbases://cb.abc.cloud.couchbase.com",
        "CB_USERNAME": "app_user",
        "CB_PASSWORD": "…",
        "CB_MCP_READ_ONLY_MODE": "true"
      }
    }
  }
}
```

Manage and inspect it with **MCP: List Servers** in the Command Palette (→ Show Output for logs). See the [VS Code MCP docs](https://code.visualstudio.com/docs/copilot/chat/mcp-servers).

**Shortcut — Couchbase VS Code Extension:** the [Couchbase extension](https://marketplace.visualstudio.com/items?itemName=Couchbase.vscode-couchbase) (v3.0.0+) bundles the MCP server and prompts to start it (stdio) when you connect to a cluster — no manual `mcp.json` needed. Command Palette: `Couchbase: Start MCP Server`, `Couchbase: Get MCP Server Config`, `Couchbase: MCP Server Settings` (disabled tools, read-only mode, elicitation, export paths, etc.).

## Factory and other MCP clients

- **Factory:** `droid mcp add couchbase-mcp 'uvx couchbase-mcp-server …' --type stdio` (Droid CLI), or add the `mcpServers.couchbase` block to `~/.factory/mcp.json`.
- **Any other MCP-compatible client:** use the same `mcpServers` entry (command `uvx`, the pinned `--from` args, and the `CB_*` env map) in that client's MCP config file. The only common variant is VS Code's top-level `servers` key (above). Where a client launches from a GUI and doesn't inherit your shell environment, set the `CB_*` values in the entry's `env` map rather than relying on exported shell vars.

## Switching clusters

One server instance connects to a single cluster, fixed at startup via `CB_CONNECTION_STRING` — there is no tool to switch clusters at runtime. To point the server at a different cluster, update `CB_CONNECTION_STRING` and the credentials in the config above and restart the client.

## Launch alternatives

Swap the `command`/`args` in any of the blocks above.

**Docker** (no Python toolchain needed). Docker tags can't express a range, so pick the floating minor tag for the line you want: `:0.8` tracks `0.8.x`, and `:1.0` tracks the `1.0.x` line (once released) — the uvx range above spans both. For a **local** cluster, use `host.docker.internal` in the connection string:

```json
{
  "command": "docker",
  "args": ["run", "--rm", "-i",
    "-e", "CB_CONNECTION_STRING=couchbase://host.docker.internal",
    "-e", "CB_USERNAME=Administrator",
    "-e", "CB_PASSWORD=…",
    "-e", "CB_MCP_READ_ONLY_MODE=true",
    "couchbaseecosystem/mcp-server-couchbase:0.8"]
}
```

(Set `CB_MCP_READ_ONLY_MODE` explicitly here too: on the `:1.0` tag the server default is `false`, so omitting it would enable writes.)

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
uvx --from "couchbase-mcp-server>=0.8.0,<1.1.0" couchbase-mcp-server
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
- Access safety (read-only mode, disabling tools, confirmation prompts): [`safety.md`](safety.md).
- Full env var / auth / transport reference: [`configuration.md`](configuration.md).
