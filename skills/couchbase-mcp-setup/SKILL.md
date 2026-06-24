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
| Username | `CB_USERNAME` | a **database** user — on Capella this is the **Cluster Access Name** (not the UI login) |
| Password | `CB_PASSWORD` | the database user's password |

Optional: `CB_MCP_READ_ONLY_MODE` (default `true`), `CB_MCP_DISABLED_TOOLS` / `CB_MCP_CONFIRMATION_REQUIRED_TOOLS` (fine-grained tool safety), `CB_MCP_TRANSPORT` (default `stdio`).

> **One server instance connects to one cluster**, fixed at startup (all of that cluster's buckets are reachable through the tools). There is no tool to switch clusters at runtime — to use a different cluster, update `CB_CONNECTION_STRING` and credentials and restart the client (see Step 5).

Work through the steps in order. Be imperative and never print secret values back to the user.

## Step 0 — Detect the environment

Determine two things before configuring anything:

1. **Which harness** is the user in — Claude Code (most common), Codex, Cursor, Windsurf, or Claude Desktop? Hints: `env | grep '^CODEX_'` (non-empty → Codex); in Claude Code, `claude mcp list` works.
2. **How they installed** — via the Couchbase **plugin** (a bundled `mcp.json` already defines the `couchbase` server with `${CB_*}` placeholders) or **manually** (no server registered yet). Context only: Step 5's recommended `local`-scoped `claude mcp add` works either way (it overrides the plugin's definition if one is present).

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
- For a stronger guarantee, have the user create a **least-privilege credential** with only **Read** access scoped to the bucket(s)/scope(s) you want readable, instead of reusing an admin account — on Capella this is a **Basic Cluster Access credential** (available on all tiers; role-based fine-grained privileges like `data_reader` / `query_select` are an Advanced, **paid-plan** option). See the reference for the chosen deployment.
- Set `CB_MCP_READ_ONLY_MODE=false` only when the user explicitly chose read-write access above — and confirm once more before generating it.
- **Fine-grained tool control (optional):** `CB_MCP_DISABLED_TOOLS` takes a comma-separated list of tool names (or a file path) to drop specific tools; `CB_MCP_CONFIRMATION_REQUIRED_TOOLS` makes the listed tools require explicit confirmation before they run (client-dependent). Note: disabling tools is **not** a security boundary — the database user's RBAC permissions are the authoritative control.

## Step 5 — Write the credentials into your client

Pick the user's harness. There are two equivalent ways to register the server — use whichever fits the environment:

- **Edit the client's MCP config file** (JSON or TOML) directly — works in any harness, no shell needed.
- **Run the client's CLI** (e.g. `claude mcp add`) where one is available.

Full config blocks (including Docker/source/Streamable-HTTP launch alternatives and how to switch clusters) are in [`references/client-setup.md`](references/client-setup.md).

- **Claude Code (recommended):** register the server with `claude mcp add` at **`--scope local`**. The credentials are stored in Claude Code's own per-project config (`~/.claude.json`, *not* your repo), injected only into the server process, and **never exported to your shell** — so they can't leak into other shells, tools, or projects:
  ```bash
  claude mcp add couchbase --scope local \
    -e CB_CONNECTION_STRING="…" -e CB_USERNAME="…" \
    -e CB_PASSWORD="…" \
    -- uvx --from "couchbase-mcp-server>=0.8.0,<0.9.0" couchbase-mcp-server
  ```
  A `local`-scoped server outranks the plugin's bundled definition (precedence: `local` > `project` > `user` > plugin), so **this works whether or not the plugin is installed** and needs no `${CB_*}` shell exports. Pass safety vars the same way (e.g. `-e CB_MCP_READ_ONLY_MODE="false"`). Use `--scope user` only to share this cluster across *all* your Claude Code projects, and avoid `--scope project`, which writes the credentials into a committed `.mcp.json`.
- **Claude Code, via the plugin's bundled template (alternative):** the bundled `mcp.json` reads `${CB_*}` from the environment Claude Code is launched in. If you use this route, **scope those vars to the project** — e.g. a git-ignored `.envrc` loaded by `direnv` — rather than a global `~/.zshrc` export, which is visible to every shell, subprocess, and project and persists indefinitely.
- **Codex:** add an `[mcp_servers.couchbase]` block (with `[mcp_servers.couchbase.env]`) to `~/.codex/config.toml`.
- **Cursor / Windsurf / Claude Desktop:** add a `mcpServers.couchbase` JSON block in that client's MCP settings.

**Safety vars:** pass `CB_MCP_READ_ONLY_MODE`, `CB_MCP_DISABLED_TOOLS`, and `CB_MCP_CONFIRMATION_REQUIRED_TOOLS` like the connection values — `-e` on `claude mcp add` (recommended), or as scoped exports if you use the bundled template (which passes them through). **Don't edit the plugin's bundled `mcp.json`:** per-user changes there don't apply to the installed (cached) copy and are overwritten on plugin update.

**Switching clusters:** a server connects to one cluster, fixed at startup — there is no runtime switch. To point it at a different cluster, update `CB_CONNECTION_STRING` and credentials and restart the client.

**Secret hygiene:** never commit credentials; don't hardcode secrets into version-controlled files (including a `project`-scoped `.mcp.json`). The recommended `--scope local` route keeps them in `~/.claude.json`, outside your repo. If you instead use the bundled template's `${CB_*}` vars, `chmod 600` and **git-ignore** the file holding them (e.g. `.envrc`) and avoid global `~/.zshrc` exports, which leak into other shells and projects.

## Step 6 — Restart and verify

1. Apply the config: run `/reload-plugins` to pick up the server without losing your session. If the tools don't appear, restart Claude Code — a full restart is the guaranteed fallback for any registration route. (Bundled-template route only: the server reads `${CB_*}` from Claude Code's launch environment, so if you set those vars *after* launching — e.g. just ran `direnv allow` / `source ~/.zshrc` — you must restart, not just reload, for the new env to apply.)
2. Verify by asking the agent to call a Couchbase MCP tool — *"list my buckets"* (`get_buckets_in_cluster`) or *"run `SELECT 'ok' AS status`"*. A real result means you're connected.
3. If it fails, re-run the masked check from Step 1 and see Troubleshooting.

### Setup verification checklist

- [ ] `CB_CONNECTION_STRING`, `CB_USERNAME`, `CB_PASSWORD` are all set (masked check from Step 1)
- [ ] Scheme matches the deployment — `couchbases://` for Capella, `couchbase://` for local
- [ ] Username is a **database / Cluster Access** credential, not the Capella **UI login**
- [ ] (Capella) your IP is in the **Allowed IP** list
- [ ] Access level is intentional — read-only (`CB_MCP_READ_ONLY_MODE=true`) unless write was explicitly chosen
- [ ] Client reloaded/restarted so the server picked up the config
- [ ] A real tool call succeeds — `test_cluster_connection` / `get_buckets_in_cluster`

## Troubleshooting

| Symptom | Likely cause / fix |
|---------|--------------------|
| Connection **times out** | Capella: your IP isn't in the **Allowed IP** list; or you used `couchbase://` instead of `couchbases://`. Network: cluster unreachable. |
| **Auth fails** | You used the Capella **UI login** instead of a **Cluster Access** credential; or the password's case is wrong (passwords are case-sensitive). |
| **"bucket not found"** | The bucket name passed to a tool is wrong or **case-sensitive**; confirm the bucket exists in the cluster. |
| `couchbase://` **rejected** | Capella requires TLS — use `couchbases://`. |
| **TLS cert rejected** (self-signed / untrusted) | Set `CB_CA_CERT_PATH` to the CA root cert. Not needed for Capella (bundled CA used automatically). |
| `uvx: command not found` | Install `uv` (`brew install uv` or `curl -LsSf https://astral.sh/uv/install.sh \| sh`). |
| MCP server in **Docker** can't reach a local cluster | Use `couchbase://host.docker.internal`, not `localhost`. |
| Server starts but **no tools appear** | Ensure transport is `stdio`; run `/reload-plugins`, then fully restart if they still don't appear. |
| HTTP transport **port in use** | Change `CB_MCP_PORT` (default `8000`). |
| **Writes are blocked** | Expected — `CB_MCP_READ_ONLY_MODE` is `true` by default. Set it to `false` only if the user wants writes. |

## References

Load the one that matches what you're doing — each is self-contained.

**Deployment** (Steps 2–3, get connection string + credentials):

- [`references/capella-setup.md`](references/capella-setup.md) — Capella: connection string, Cluster Access credentials, Allowed IP, sample bucket.
- [`references/local-setup.md`](references/local-setup.md) — local Couchbase Server: Docker, default credentials, `couchbase://localhost`.

**Wiring & server reference:**

- [`references/client-setup.md`](references/client-setup.md) — *how each client registers the server*: per-harness config blocks + Docker/source/Streamable-HTTP launch alternatives + cluster switching (Step 5).
- [`references/configuration.md`](references/configuration.md) — *the server's own knobs*: full `CB_*` env var table (+ CLI args), authentication modes (basic/mTLS/TLS CA), transport, version/package requirements.
- [`references/safety.md`](references/safety.md) — read-only mode (truth table + gated tools), disabling tools, confirmation prompts, RBAC (Step 4).
- [`references/tools.md`](references/tools.md) — the MCP tool catalog (exact tool names) for verification and disable/confirm lists.
