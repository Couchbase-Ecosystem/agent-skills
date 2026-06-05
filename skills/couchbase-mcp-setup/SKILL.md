---
name: couchbase-mcp-setup
description: >-
  Guide a user through configuring the Couchbase MCP server in their coding
  agent. Use this skill when the Couchbase MCP server is installed but its
  connection fails or the CB_* environment variables aren't set, or when the
  user asks to connect to Couchbase or Capella and doesn't yet have a connection
  string and credentials configured.
license: Apache-2.0
metadata:
  version: "0.1.0"
allowed-tools: Bash
---

# Couchbase MCP Server Setup

This skill connects the [Couchbase MCP server](https://github.com/Couchbase-Ecosystem/mcp-server-couchbase) to a live cluster so the other Couchbase skills and tools can actually query and inspect data. It runs *before* the connection works, so it is mostly shell- and instruction-driven, ending with a verification that calls a Couchbase MCP tool.

**The server needs four required values:**

| Value | Env var | Example |
|-------|---------|---------|
| Connection string | `CB_CONNECTION_STRING` | `couchbases://cb.abc.cloud.couchbase.com` (Capella) · `couchbase://localhost` (local) |
| Username | `CB_USERNAME` | a **database** user (not the Capella UI login) |
| Password | `CB_PASSWORD` | the database user's password |
| Bucket | `CB_BUCKET_NAME` | e.g. `travel-sample` |

Optional: `CB_MCP_READ_ONLY_QUERY_MODE` (default `true`), `CB_MCP_TRANSPORT` (default `stdio`).

> **One server instance = one cluster + one bucket.** There is no runtime "switch database" tool. To work with several databases, register multiple **named** servers (see Step 5).

Work through the steps in order. Be imperative and never print secret values back to the user.

## Step 0 — Detect the environment

Determine two things before configuring anything:

1. **Which harness** is the user in — Claude Code (most common), Codex, Cursor, Windsurf, or Claude Desktop? Hints: `env | grep '^CODEX_'` (non-empty → Codex); in Claude Code, `claude mcp list` works.
2. **How they installed** — via the Couchbase **plugin** (a bundled `mcp.json` already defines the `couchbase` server with `${CB_*}` placeholders) or **manually** (no server registered yet). This decides where credentials go in Step 5.

## Step 1 — Check existing configuration (never reveal secrets)

Show which values are already set, masked:

```bash
env | grep '^CB_' | sed 's/=.*/=<set>/'
```

In Claude Code, also check whether a server is registered: `claude mcp list`, then `claude mcp get couchbase`. In Codex, inspect `~/.codex/config.toml` for an `[mcp_servers.couchbase]` block (mask values).

If all four values are present and a tool call already works, skip to **Step 6** to verify. Otherwise continue.

## Step 2 — Choose where Couchbase lives

Ask the user which applies; each path produces the four values above:

- **A) Capella** (managed cloud) → follow [`references/capella-setup.md`](references/capella-setup.md)
- **B) Local Couchbase Server** (Docker / dev machine) → follow [`references/local-setup.md`](references/local-setup.md)
- **C) Self-managed / remote cluster** → the user already has a connection string and a database user; continue with those.

## Step 3 — Get your connection details

Use the reference for the chosen deployment to collect `CB_CONNECTION_STRING`, `CB_USERNAME`, `CB_PASSWORD`, and `CB_BUCKET_NAME`.

**Connection-string scheme matters:**
- `couchbase://…` — non-TLS, for local/self-managed dev clusters.
- `couchbases://…` — **TLS, required for Capella**. Plain `couchbase://` is rejected by Capella.

## Step 4 — Decide the access level (default: read-only)

- `CB_MCP_READ_ONLY_QUERY_MODE` defaults to **`true`**, which blocks data-modifying SQL++. **Keep it `true`** for exploration and for safety — most skills only read.
- For a stronger guarantee, have the user create a **least-privilege database user** (`data_reader` + `query_select`, scoped to the bucket) instead of reusing an admin account. See the reference for the chosen deployment.
- Only set `CB_MCP_READ_ONLY_QUERY_MODE=false` when the user explicitly wants the agent to write — and confirm first.

## Step 5 — Write the credentials into your client

Pick the user's harness. Full config blocks (including Docker/source launch alternatives and the named multi-connection pattern) are in [`references/client-configs.md`](references/client-configs.md).

- **Claude Code + plugin installed:** the bundled `mcp.json` already launches the server and reads `${CB_*}` from your environment, so just add persistent exports to your shell profile:
  ```bash
  # ~/.zshrc (or ~/.bashrc)
  export CB_CONNECTION_STRING="couchbases://cb.abc.cloud.couchbase.com"
  export CB_USERNAME="app_user"
  export CB_PASSWORD="…"
  export CB_BUCKET_NAME="travel-sample"
  ```
- **Claude Code, manual (no plugin):** register the server yourself (values stored in `~/.claude.json`):
  ```bash
  claude mcp add couchbase --scope user \
    -e CB_CONNECTION_STRING="…" -e CB_USERNAME="…" \
    -e CB_PASSWORD="…" -e CB_BUCKET_NAME="…" \
    -- uvx couchbase-mcp-server@0.8.0
  ```
- **Codex:** add an `[mcp_servers.couchbase]` block (with `[mcp_servers.couchbase.env]`) to `~/.codex/config.toml`.
- **Cursor / Windsurf / Claude Desktop:** add a `mcpServers.couchbase` JSON block in that client's MCP settings.

**Multiple databases:** register additional **named** servers — `couchbase-prod`, `couchbase-staging` — each with its own `CB_*`. Address them by name ("query staging").

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
| **"bucket not found"** | `CB_BUCKET_NAME` is required and **case-sensitive**; confirm the bucket exists. |
| `couchbase://` **rejected** | Capella requires TLS — use `couchbases://`. |
| `uvx: command not found` | Install `uv` (`brew install uv` or `curl -LsSf https://astral.sh/uv/install.sh \| sh`). |
| MCP server in **Docker** can't reach a local cluster | Use `couchbase://host.docker.internal`, not `localhost`. |
| Server starts but **no tools appear** | Ensure transport is `stdio`; fully restart / `/reload-plugins`. |
| **Writes are blocked** | Expected — `CB_MCP_READ_ONLY_QUERY_MODE` is `true` by default. Set it to `false` only if the user wants writes. |

## References

- [`references/capella-setup.md`](references/capella-setup.md) — Capella: connection string, Database Access credentials, Allowed IP, sample bucket.
- [`references/local-setup.md`](references/local-setup.md) — local Couchbase Server: Docker, default credentials, `couchbase://localhost`.
- [`references/client-configs.md`](references/client-configs.md) — per-harness config blocks + Docker/source launch alternatives + named multi-connections.
