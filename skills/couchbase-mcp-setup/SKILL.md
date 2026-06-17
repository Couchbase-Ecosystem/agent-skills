---
name: couchbase-mcp-setup
description: >-
  Guide a user through configuring the Couchbase MCP server in their coding
  agent. Use this skill when the Couchbase MCP server is installed but its
  connection fails or the CB_* environment variables aren't set, or when the
  user asks to connect to Couchbase or Capella and doesn't yet have a connection
  string and credentials configured. Does NOT tune your application's SDK
  connection or run data queries (use couchbase-natural-language-querying).
license: Apache-2.0
metadata:
  version: "0.1.0"
allowed-tools: Bash, Read, Edit, Write
---

# Couchbase MCP Server Setup

This skill connects the [Couchbase MCP server](https://github.com/couchbase/mcp-server-couchbase) to a live cluster so the other Couchbase skills and tools can actually query and inspect data. It runs *before* the connection works, so it's driven by editing the client's MCP config file (or running its CLI where one exists), ending with a verification that calls a Couchbase MCP tool.

**The server needs three required values:**

| Value | Env var | Example |
|-------|---------|---------|
| Connection string | `CB_CONNECTION_STRING` | `couchbases://cb.abc.cloud.couchbase.com` (Capella) · `couchbase://localhost` (local) |
| Username | `CB_USERNAME` | a **database** user (not the Capella UI login) |
| Password | `CB_PASSWORD` | the database user's password |

Optional: `CB_MCP_READ_ONLY_MODE` (default `true`), `CB_MCP_DISABLED_TOOLS` / `CB_MCP_CONFIRMATION_REQUIRED_TOOLS` (fine-grained tool safety), `CB_MCP_TRANSPORT` (default `stdio`).

> **One server instance connects to one cluster**, fixed at startup (all of that cluster's buckets are reachable through the tools). There is no tool to switch clusters at runtime — to use a different cluster, update `CB_CONNECTION_STRING` and credentials and restart the client (see Step 5).

Work through the steps in order. Be imperative and never print secret values back to the user.

## Step 0 — Detect the environment

Determine two things before configuring anything:

1. **Which harness** is the user in — Claude Code (most common), Codex, Cursor, Windsurf, or Claude Desktop? Hints: `env | grep '^CODEX_'` (non-empty → Codex); in Claude Code, `claude mcp list` works.
2. **How they installed** — via the Couchbase **plugin** (a bundled `mcp.json` already defines the `couchbase` server with `${CB_*}` placeholders) or **manually** (no server registered yet). This decides where credentials go in Step 5.

## Step 1 — Check existing configuration (never reveal secrets)

Find which `CB_*` values are already set — they live either in your shell environment or in the client's MCP config file, depending on how the server was registered:

- **Shell environment** (plugin / `${CB_*}` setups): `env | grep '^CB_' | sed 's/=.*/=<set>/'`.
- **Client MCP config file**: inspect it and mask values — `claude mcp list` then `claude mcp get couchbase` (Claude Code), the `[mcp_servers.couchbase]` block in `~/.codex/config.toml` (Codex), or the `mcpServers.couchbase` entry in the client's MCP settings JSON (Cursor / Windsurf / Claude Desktop).

If all three values are present and a tool call already works, skip to **Step 6** to verify. Otherwise continue.

## Step 2 — Choose where Couchbase lives

Ask the user which applies; each path produces the three values above:

- **A) Capella** (managed cloud) → follow [`references/capella-setup.md`](references/capella-setup.md)
- **B) Local Couchbase Server** (Docker / dev machine) → follow [`references/local-setup.md`](references/local-setup.md)
- **C) Self-managed / remote cluster** → the user already has a connection string and a database user; continue with those.

## Step 3 — Get your connection details

Use the reference for the chosen deployment to collect `CB_CONNECTION_STRING`, `CB_USERNAME`, and `CB_PASSWORD`.

**Connection-string scheme matters:**
- `couchbase://…` — non-TLS, for local/self-managed dev clusters.
- `couchbases://…` — **TLS, required for Capella**. Plain `couchbase://` is rejected by Capella.

## Step 4 — Decide the access level (default: read-only)

**Ask the user before generating any config:** should the agent have **read-only** access (the safe default) or **read-write** access? Default to read-only unless they explicitly ask for write.

- `CB_MCP_READ_ONLY_MODE` defaults to **`true`**, which blocks all writes — KV mutations and data-modifying SQL++ (write tools are not even loaded). **Keep it `true`** for exploration and for safety — most skills only read.
- For a stronger guarantee, have the user create a **least-privilege database user** (`data_reader` + `query_select`, scoped to the bucket(s) you want readable) instead of reusing an admin account. See the reference for the chosen deployment.
- Set `CB_MCP_READ_ONLY_MODE=false` only when the user explicitly chose read-write access above — and confirm once more before generating it.
- **Fine-grained tool control (optional):** `CB_MCP_DISABLED_TOOLS` takes a comma-separated list of tool names (or a file path) to drop specific tools; `CB_MCP_CONFIRMATION_REQUIRED_TOOLS` makes the listed tools require explicit confirmation before they run (client-dependent). Note: disabling tools is **not** a security boundary — the database user's RBAC permissions are the authoritative control.

## Step 5 — Write the credentials into your client

Pick the user's harness. There are two equivalent ways to register the server — use whichever fits the environment:

- **Edit the client's MCP config file** (JSON or TOML) directly — works in any harness, no shell needed.
- **Run the client's CLI** (e.g. `claude mcp add`) where one is available.

Full config blocks (including Docker/source/Streamable-HTTP launch alternatives and how to switch clusters) are in [`references/client-configs.md`](references/client-configs.md).

- **Claude Code + plugin installed:** the bundled `mcp.json` already launches the server and reads `${CB_*}` from your environment, so just add persistent exports to your shell profile:
  ```bash
  # ~/.zshrc (or ~/.bashrc)
  export CB_CONNECTION_STRING="couchbases://cb.abc.cloud.couchbase.com"
  export CB_USERNAME="app_user"
  export CB_PASSWORD="…"
  # optional — the bundled mcp.json passes these through if set:
  # export CB_MCP_READ_ONLY_MODE="false"               # allow writes (default: true)
  # export CB_MCP_DISABLED_TOOLS="tool_a,tool_b"        # drop specific tools
  # export CB_MCP_CONFIRMATION_REQUIRED_TOOLS="tool_c"  # require confirmation before running
  ```
- **Claude Code, manual (no plugin):** register the server yourself (values stored in `~/.claude.json`):
  ```bash
  claude mcp add couchbase --scope user \
    -e CB_CONNECTION_STRING="…" -e CB_USERNAME="…" \
    -e CB_PASSWORD="…" \
    -- uvx --from "couchbase-mcp-server>=0.8.0,<0.9.0" couchbase-mcp-server
  ```
- **Codex:** add an `[mcp_servers.couchbase]` block (with `[mcp_servers.couchbase.env]`) to `~/.codex/config.toml`.
- **Cursor / Windsurf / Claude Desktop:** add a `mcpServers.couchbase` JSON block in that client's MCP settings.

**Safety vars without editing the plugin:** the bundled `mcp.json` already passes `CB_MCP_READ_ONLY_MODE`, `CB_MCP_DISABLED_TOOLS`, and `CB_MCP_CONFIRMATION_REQUIRED_TOOLS` through from your environment — set them like the connection values (an `export`, or `-e` on `claude mcp add`). **Don't edit the plugin's bundled `mcp.json`:** per-user changes there don't apply to the installed (cached) copy and are overwritten on plugin update.

**Switching clusters:** a server connects to one cluster, fixed at startup — there is no runtime switch. To point it at a different cluster, update `CB_CONNECTION_STRING` and credentials and restart the client.

**Secret hygiene:** never commit credentials; don't hardcode secrets into version-controlled files; `chmod 600` any env file holding them.

## Step 6 — Restart and verify

1. Apply the config: restart the client, or in Claude Code run `/reload-plugins` (or `source ~/.zshrc` and reopen).
2. Verify by asking the agent to call a Couchbase MCP tool — *"list my buckets"* (`get_buckets_in_cluster`) or *"run `SELECT 'ok' AS status`"*. A real result means you're connected.
3. If it fails, re-run the masked check from Step 1 and see Troubleshooting.

## Troubleshooting

| Symptom | Likely cause / fix |
|---------|--------------------|
| Connection **times out** | Capella: your IP isn't in the **Allowed IP** list; or you used `couchbase://` instead of `couchbases://`. Network: cluster unreachable. |
| **Auth fails** | You used the Capella **UI login** instead of a **Database Access** credential; or the password's case is wrong (passwords are case-sensitive). |
| **"bucket not found"** | The bucket name passed to a tool is wrong or **case-sensitive**; confirm the bucket exists in the cluster. |
| `couchbase://` **rejected** | Capella requires TLS — use `couchbases://`. |
| `uvx: command not found` | Install `uv` (`brew install uv` or `curl -LsSf https://astral.sh/uv/install.sh \| sh`). |
| MCP server in **Docker** can't reach a local cluster | Use `couchbase://host.docker.internal`, not `localhost`. |
| Server starts but **no tools appear** | Ensure transport is `stdio`; fully restart / `/reload-plugins`. |
| **Writes are blocked** | Expected — `CB_MCP_READ_ONLY_MODE` is `true` by default. Set it to `false` only if the user wants writes. |

## References

- [`references/capella-setup.md`](references/capella-setup.md) — Capella: connection string, Database Access credentials, Allowed IP, sample bucket.
- [`references/local-setup.md`](references/local-setup.md) — local Couchbase Server: Docker, default credentials, `couchbase://localhost`.
- [`references/client-configs.md`](references/client-configs.md) — per-harness config blocks + Docker/source/Streamable-HTTP launch alternatives + cluster switching.
