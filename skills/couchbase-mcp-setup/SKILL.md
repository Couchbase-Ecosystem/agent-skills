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
allowed-tools: Bash, Read, Edit, Write
---

# Couchbase MCP Server Setup

This skill connects the [Couchbase MCP server](https://github.com/couchbase/mcp-server-couchbase) to a live cluster so the other Couchbase skills and tools can actually query and inspect data. It runs *before* the connection works, so it's driven by editing the client's MCP config file (or running its CLI where one exists), ending with a verification that calls a Couchbase MCP tool.

> **It works with any MCP-compatible client.** The Couchbase MCP server is a standard MCP server, so it runs in any client that speaks MCP — Claude Code, Codex, Cursor, Windsurf, Claude Desktop, VS Code, JetBrains, Factory, and others. The per-client examples below are worked patterns, **not** a list of the only clients that work; every client registers the server the same way (a `command`/`args`/`env` entry), differing only in *where* that entry lives and minor syntax. Help with whichever client the user names, even if it isn't the one this skill is running in.

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

1. **Which harness** is the user in — Claude Code (most common), Codex, Cursor, Windsurf, Claude Desktop, VS Code, JetBrains, or any other MCP-compatible client? Hints: `env | grep '^CODEX_'` (non-empty → Codex); in Claude Code, `claude mcp list` works. A client not named here still works — see [`references/client-setup.md`](references/client-setup.md) for its config-file location and any per-client quirks.
2. **How they installed** — via the Couchbase **plugin** (a bundled `mcp.json` already defines the `couchbase` server and pins the safety defaults; credentials are supplied separately in Step 5) or **manually** (no server registered yet). Context only: Step 5's recommended `local`-scoped `claude mcp add` works either way (it overrides the plugin's definition if one is present).

## Step 1 — Check existing configuration (never reveal secrets)

Find which `CB_*` values are already set — they live either in your shell environment or in the client's MCP config file, depending on how the server was registered:

- **Shell environment** (bundled-template route, where the server inherits exported `CB_*`): `env | grep '^CB_' | sed 's/=.*/=<set>/'`.
- **Client MCP config file**: inspect it and mask values — `claude mcp list` then `claude mcp get couchbase` (Claude Code), the `[mcp_servers.couchbase]` block in `~/.codex/config.toml` (Codex), or the `mcpServers.couchbase` entry in the client's MCP settings JSON (Cursor / Windsurf / Claude Desktop / JetBrains; VS Code uses a top-level `servers` key instead — see [`references/client-setup.md`](references/client-setup.md)).

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
- Set `CB_MCP_READ_ONLY_MODE=false` only when the user explicitly chose read-write access above — and confirm once more before generating it. Treat `CB_MCP_READ_ONLY_MODE` as the **single write switch**: the bundled template also clears the deprecated `CB_MCP_READ_ONLY_QUERY_MODE` (which on the current server independently blocks query writes), so on the `claude mcp add` or direct-config routes pass `-e CB_MCP_READ_ONLY_QUERY_MODE="false"` alongside it when enabling writes.
- **Fine-grained tool control (optional):** `CB_MCP_DISABLED_TOOLS` takes a comma-separated list of tool names (or a file path) to drop specific tools; `CB_MCP_CONFIRMATION_REQUIRED_TOOLS` makes the listed tools require explicit confirmation before they run (client-dependent). Note: disabling tools is **not** a security boundary — the database user's RBAC permissions are the authoritative control.

## Step 5 — Write the credentials into your client

In **any** harness you have the same two-way choice: **apply the config for the user** (run their CLI or edit their MCP config file directly), or hand them the **command/config block to apply themselves** — which keeps their credentials out of the chat. Default to doing it for them; offer the self-apply path to anyone who'd rather not share secrets in the conversation. Claude Code below is the worked example.

**Claude Code (recommended):** use `claude mcp add --scope local`. It stores the credentials in `~/.claude.json` (outside your repo), injected only into the server process and never exported to your shell — so they can't leak into other shells, tools, or projects — and it outranks the plugin's bundled definition (precedence: `local` > `project` > `user` > plugin), so it works whether or not the plugin is installed.

Present both ways every time and let the user choose:

- **Paste your credentials and I'll configure it** *(simplest - requires pasting secrets in chat)*: the user gives you the connection string, username, and password, and you run the command for them. Fastest path, nothing for them to copy. (The values are entered in the chat, so briefly communicate the risk for those who'd rather keep secrets out of the transcript and steer them to the next option. Never repeat the password back in your replies.)
- **I'll run the command myself**: hand the user the ready-to-fill command below to paste into their **own terminal** (or via the `!` prefix). Their password stays local and never appears in the conversation.

```bash
claude mcp add couchbase --scope local \
  -e CB_CONNECTION_STRING="…" -e CB_USERNAME="…" \
  -e CB_PASSWORD="…" \
  -- uvx --from "couchbase-mcp-server>=0.8.0,<0.9.0" couchbase-mcp-server
```

Pass safety vars the same way; to enable writes pass both `-e CB_MCP_READ_ONLY_MODE="false" -e CB_MCP_READ_ONLY_QUERY_MODE="false"` (the second neutralizes the deprecated query-write block, keeping `CB_MCP_READ_ONLY_MODE` the only decider). Use `--scope user` only to share this cluster across *all* your Claude Code projects; avoid `--scope project`, which writes the credentials into a committed `.mcp.json`.

**Alternative — shell env vars (`direnv`):** instead of `claude mcp add`, let the bundled server inherit `CB_CONNECTION_STRING` / `CB_USERNAME` / `CB_PASSWORD` from the environment Claude Code is launched in — scoped to the project via a git-ignored `.envrc`, not a global `~/.zshrc`. Offer this only if the user specifically prefers a shell/`direnv` workflow (it needs a full Claude Code restart to take effect).

**Other clients** — same two-way choice: **write the block into their config file for them**, or hand them the block to paste. Full blocks (+ Docker/source/Streamable-HTTP launch alternatives and cluster switching) are in [`references/client-setup.md`](references/client-setup.md):

- **Codex:** the `[mcp_servers.couchbase]` block (with `[mcp_servers.couchbase.env]`) in `~/.codex/config.toml`.
- **Cursor / Windsurf / Claude Desktop / JetBrains:** the `mcpServers.couchbase` JSON block in that client's MCP settings.
- **VS Code:** the same JSON block but under the top-level **`servers`** key (not `mcpServers`), in `.vscode/mcp.json` (workspace) or the user config. The **Couchbase VS Code Extension** (v3.0.0+) also bundles the server and can start it on cluster connect.
- **Any other MCP client:** drop the same `command`/`args`/`env` entry into that client's MCP config.

**Safety vars:** pass `CB_MCP_READ_ONLY_MODE`, `CB_MCP_DISABLED_TOOLS`, and `CB_MCP_CONFIRMATION_REQUIRED_TOOLS` like the connection values — `-e` on `claude mcp add` (recommended), or as scoped exports if you use the bundled template (which defaults `CB_MCP_READ_ONLY_MODE` to `true`, clears the deprecated `CB_MCP_READ_ONLY_QUERY_MODE` to `false` so `CB_MCP_READ_ONLY_MODE` is the single switch, and passes any you set through). **Don't edit the plugin's bundled `mcp.json`:** per-user changes there don't apply to the installed (cached) copy and are overwritten on plugin update.

**Switching clusters:** a server connects to one cluster, fixed at startup — there is no runtime switch. To point it at a different cluster, update `CB_CONNECTION_STRING` and credentials and restart the client.

**Secret hygiene:** never commit credentials; don't hardcode secrets into version-controlled files (including a `project`-scoped `.mcp.json`). The recommended `--scope local` route keeps them in `~/.claude.json`, outside your repo. If you instead use the bundled-template route (exporting `CB_*` for the server to inherit), `chmod 600` and **git-ignore** the file holding them (e.g. `.envrc`) and avoid global `~/.zshrc` exports, which leak into other shells and projects.

## Step 6 — Restart and verify

1. Apply the config — **reload or restart the client** so it loads the server. Claude Code: run `/reload-plugins` to pick it up without losing your session; if the tools don't appear, restart Claude Code (a full restart is the guaranteed fallback for any registration route). Other clients: fully quit and relaunch (Codex, Claude Desktop) or reload MCP servers (Cursor / Windsurf / JetBrains; VS Code: **MCP: List Servers** → restart). Any other client: reload or restart it so it re-reads its MCP config. (Bundled-template route only: the server inherits `CB_*` from Claude Code's launch environment, so if you set those vars *after* launching — e.g. just ran `direnv allow` / `source ~/.zshrc` — you must restart, not just reload, for the new env to apply.)
2. Verify by asking the agent to call a Couchbase MCP tool — *"list my buckets"* (`get_buckets_in_cluster`) or *"run `SELECT 'ok' AS status`"*. A real result means you're connected.
3. If it fails, re-run the masked check from Step 1 and see Troubleshooting.

### Setup verification checklist

- [ ] `CB_CONNECTION_STRING`, `CB_USERNAME`, `CB_PASSWORD` are all set (masked check from Step 1)
- [ ] Scheme matches the deployment — `couchbases://` for Capella, `couchbase://` for local
- [ ] Username is a **database / Cluster Access** credential, not the Capella **UI login**
- [ ] (Capella) your IP is in the **Allowed IP** list
- [ ] Access level is intentional — read-only (`CB_MCP_READ_ONLY_MODE=true`) unless write was explicitly chosen
- [ ] Client reloaded/restarted so the server picked up the config
- [ ] A real tool call succeeds — `test_cluster_connection` / `get_buckets_in_cluster` (if no tools appear yet, wait a few seconds and re-check / `/reload-plugins` before concluding it failed — `uvx`'s first launch can lag; see Troubleshooting)

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
| **Tools missing right after a restart, then present on a later one** (intermittent) | Startup-timing race: `uvx` resolves/downloads the package and the server completes its MCP handshake asynchronously, so a slow launch can exceed the client's startup window. Wait a few seconds and re-check (or `/reload-plugins`) before concluding it's not installed; raise the window by launching with `MCP_TIMEOUT=30000` (ms); for deterministic startups `uv tool install "couchbase-mcp-server>=0.8.0,<0.9.0"` (or pre-warm with `uvx couchbase-mcp-server --version`) so launches skip resolution/download. |
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
