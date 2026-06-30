# Couchbase Agent Skills

Couchbase agent skills bring Couchbase expertise to your agents out of the box, letting them operate from authoritative knowledge rather than relying on training data or guesswork. Designed with the enterprise-supported Couchbase MCP server, these skills work against a real, live cluster — grounding every answer in your actual schema, data, and indexes so agents deliver reliable, high-quality results.

Enterprise support for Couchbase MCP Server is available by licensing Couchbase AI Data Plane, which also entitles use and enterprise support of Couchbase Agent Memory and Couchbase Agent Catalog.

## Available Skills

| Skill Name | What it does |
|------------|--------------|
| `couchbase-mcp-setup` | **Initial configuration:** setting CB_* environment variables for the MCP server environment. |
| `couchbase-natural-language-querying` | Translating natural language into SQL++ for execution against live cluster environments. |
| `couchbase-query-optimizer` | Optimization of EXPLAIN plans, GSI index architecture, and identifying slow query bottlenecks. |
| `couchbase-data-modeling` | Schema design for JSON, evaluating embedding vs. referencing strategies, and defining document key patterns. |

## Prerequisites

The skills act on a live cluster through the [Couchbase MCP server](https://github.com/couchbase/mcp-server-couchbase) which can be installed via [`uv`](https://docs.astral.sh/uv/) (`uvx`) or Docker. For first-time configuration, use the `couchbase-mcp-setup` skill, or see the [MCP server docs](https://github.com/couchbase/mcp-server-couchbase#readme).

## Installation methods

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
