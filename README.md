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
|---|---|
| **Claude Code** | Within a Claude Code session: `/plugin marketplace add Couchbase-Ecosystem/agent-skills`, then `/plugin install couchbase@couchbase-plugins` |
| **Claude Desktop App** | In **Customize**, click the `+` next to **Personal Plugins** → **Add** → **Add Marketplace**, enter `Couchbase-Ecosystem/agent-skills` (or the repo URL), and click **Sync**. Then click the `+` to install the **couchbase** plugin. _No marketplace flow in your UI? [Install each skill manually](#install-each-skill-manually-claude-desktop) below._ |
| **Codex CLI** | `codex plugin marketplace add Couchbase-Ecosystem/agent-skills`, then start `codex` and open the plugins browser `/plugins`. Find the `couchbase` plugin and install. |
| **Codex Desktop App** | Go to **Plugins** → click the dropdown next to the `+` (top-right) → **Add marketplace**, enter `Couchbase-Ecosystem/agent-skills` as the source, and click **Add marketplace**. Then on the **Plugins → Personal** tab, click **Install** next to **Couchbase**. |
| **Antigravity CLI** | `agy plugin install https://github.com/Couchbase-Ecosystem/agent-skills` |
| **Gemini CLI** | `gemini extensions install https://github.com/Couchbase-Ecosystem/agent-skills` |
| **GitHub Copilot CLI** | Within a Copilot CLI session: `/plugin marketplace add Couchbase-Ecosystem/agent-skills`, then `/plugin install couchbase@couchbase-plugins` (restart to activate the MCP server) |
| **Cursor** | Add `Couchbase-Ecosystem/agent-skills` as a plugin marketplace, then install `couchbase` via `/add-plugin` or the marketplace UI |

After installing, run the **`couchbase-mcp-setup`** skill to connect to your cluster — it walks you through setting the `CB_*` environment variables (`CB_CONNECTION_STRING`, `CB_USERNAME`, `CB_PASSWORD`) per harness.

### Install each skill manually (Claude Desktop)

If your Claude Desktop UI does not show the plugin marketplace flow, use per-skill uploads instead.

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
the [harness sandbox](./testing/sandbox/README.md) — see [`testing/`](./testing/README.md).

## License

Apache-2.0. See [`LICENSE`](./LICENSE).
