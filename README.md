# Couchbase Agent Skills

Official Couchbase **agent skills** + **MCP server** for your favorite coding agent. Connect to a live Couchbase cluster, explore data, write and run SQL++, optimize queries and GSI indexes, and design data models — grounded in your real cluster.

> **Status:** v1 skills built — MCP-centric (the agent operates a live cluster via the Couchbase MCP server): `couchbase-mcp-setup`, `couchbase-natural-language-querying`, `couchbase-query-optimizer`, `couchbase-data-modeling`.

## What's here

| Path | Purpose |
|------|---------|
| `skills/` | Agent Skills (one directory per skill, each with a `SKILL.md`). |
| `mcp.json` | Couchbase MCP server wiring (consumed by the plugin manifests). |
| `.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`, `.agents/`, `gemini-extension.json` | Per-harness plugin/extension manifests. |
| `tools/` | Repo tooling — skill validator and the `review-skill` meta-tool. |
| `testing/` | Eval suites and the testing sandbox — how to test the skills. See [`testing/`](./testing/README.md). |

## Prerequisites: the Couchbase MCP server

These skills act on a live cluster through the [Couchbase MCP server](https://github.com/couchbase/mcp-server-couchbase) (`couchbase-mcp-server`). It runs via [`uv`](https://docs.astral.sh/uv/) (`uvx`) or Docker — **not** a plain `npx` command.

Set these environment variables (the manifests reference them):

| Variable | Description | Default |
|----------|-------------|---------|
| `CB_CONNECTION_STRING` | Cluster connection string, e.g. `couchbases://cb.xxxx.cloud.couchbase.com` | **required** |
| `CB_USERNAME` | Database username | **required** |
| `CB_PASSWORD` | Database password | **required** |
| `CB_MCP_READ_ONLY_MODE` | Block all data modifications (KV and Query) | `true` |

For first-time configuration, use the `couchbase-mcp-setup` skill, or see the [MCP server docs](https://github.com/couchbase/mcp-server-couchbase#readme).

## Install

The repo at [`Couchbase-Ecosystem/agent-skills`](https://github.com/Couchbase-Ecosystem/agent-skills) is itself the plugin / marketplace source — install directly from it:

| Harness | Install |
|---------|---------|
| **Claude Code** | `/plugin marketplace add Couchbase-Ecosystem/agent-skills`, then `/plugin install couchbase@couchbase-plugins` |
| **Claude Desktop App** | No marketplace command — upload the repo as a plugin ZIP. See [Claude Desktop](#claude-desktop) below. |
| **Codex** | `codex plugin marketplace add Couchbase-Ecosystem/agent-skills`, then install `couchbase` from the plugin browser |
| **Gemini CLI** | `gemini extensions install https://github.com/Couchbase-Ecosystem/agent-skills` |
| **GitHub Copilot CLI** | `copilot plugin marketplace add Couchbase-Ecosystem/agent-skills`, then `/plugin install couchbase@couchbase-plugins` (restart to activate the MCP server) |
| **Cursor** | Add `Couchbase-Ecosystem/agent-skills` as a plugin marketplace, then install `couchbase` via `/add-plugin` or the marketplace UI |
| **Vercel Agent Skills** | `npx skills add Couchbase-Ecosystem/agent-skills` |

After installing, set the `CB_*` environment variables above so the MCP server can connect — or run the **`couchbase-mcp-setup`** skill, which walks you through it per harness.

### Claude Desktop

Use this plugin from the **Code** tab in Claude Desktop — the experience matches Claude Code in the terminal. Claude Desktop has no marketplace command, but it installs the repo as a **plugin** from a single ZIP: the manifest at [`.claude-plugin/plugin.json`](./.claude-plugin/plugin.json) bundles both the skills and the MCP server, so they install together.

1. **Get the plugin ZIP.** Either:
   - **Download it from GitHub** — on the [repo page](https://github.com/Couchbase-Ecosystem/agent-skills), use **Code → Download ZIP**.
   - **Or clone and package it yourself**, which lets you drop unnecessary files (e.g., `.git`, `testing/`, `.idea/`):
     ```bash
     git clone https://github.com/Couchbase-Ecosystem/agent-skills.git
     cd agent-skills
     zip -r couchbase-plugin.zip . -x '.git/*' '.github/*' 'skills/_template/*' '.idea/*' 'testing/*'
     ```
2. **Upload it.** Open **Customize** (available from any tab) → click the `+` next to **"Personal Plugins"** → select the **Personal** tab in the modal that opens → click the `+` next to **Local Uploads**, and select the ZIP. The skills register and the Couchbase MCP server is wired up automatically from [`mcp.json`](./mcp.json).
3. **Connect to your cluster.** The upload registers the server but not your credentials. Run the **`couchbase-mcp-setup`** skill — it walks you through supplying `CB_CONNECTION_STRING`, `CB_USERNAME`, and `CB_PASSWORD`, the same way it does in Claude Code.

#### If plugin upload is not available, install each skill manually

If your Claude Desktop UI does not show the plugin upload flow, use per-skill uploads instead.

1. **Create one ZIP per skill** (from repo root):
   ```bash
   mkdir -p skill-zips
   for d in skills/*; do
     [ -d "$d" ] || continue
     name="$(basename "$d")"
     [ "$name" = "_template" ] && continue
     zip -r "skill-zips/${name}.zip" "$d"
   done
   ```
2. **Upload each skill ZIP in Claude Desktop.** For each file in `skill-zips/`, go to **Customize → Skills → + icon → Create Skill → Upload a Skill**.
3. **Set up the MCP server separately.** Per-skill uploads do not include the bundled MCP server wiring, so follow the quickstart here: https://mcp-server.couchbase.com/get-started/quickstart

## Contributing

Authoring, validating, and testing skills is documented in
[`CONTRIBUTING.md`](./CONTRIBUTING.md). For testing specifics — eval suites and
the [real-harness sandbox](./testing/sandbox/README.md) — see [`testing/`](./testing/README.md).

## License

Apache-2.0. See [`LICENSE`](./LICENSE).
