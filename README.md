# Couchbase Agent Skills

Couchbase agent skills bring Couchbase expertise to your coding agents out of the box, so they work from authoritative, Couchbase-maintained knowledge instead of guessing from training data. They come in two families:

- **[Couchbase Server Data Skills](#couchbase-server-data-skills)** — query, optimize, and model data on a live Couchbase cluster through the Couchbase MCP server.
- **[Couchbase Mobile Skills](#couchbase-mobile-skills)** — build a complete offline-first mobile app with Capella App Services sync.

---

## Couchbase Server Data Skills

Couchbase Server data skills operate on a live cluster through the Couchbase MCP server, grounding every answer in your actual schema, data, and indexes — so agents querying, optimizing, or modeling your data deliver reliable, high-quality results.

| Skill Name | What it does |
|------------|--------------|
| `couchbase-mcp-setup` | **Initial configuration:** setting CB_* environment variables for the MCP server environment. |
| `couchbase-natural-language-querying` | Translating natural language into SQL++ for execution against live cluster environments. |
| `couchbase-query-optimizer` | Optimization of EXPLAIN plans, GSI index architecture, and identifying slow query bottlenecks. |
| `couchbase-data-modeling` | Schema design for JSON, evaluating embedding vs. referencing strategies, and defining document key patterns. |

### Prerequisites

Data skills need the **Couchbase MCP server**. It acts on a live cluster and can be installed via [`uv`](https://docs.astral.sh/uv/) (`uvx`) or Docker. For first-time configuration, use the `couchbase-mcp-setup` skill, or see the [MCP server docs](https://github.com/couchbase/mcp-server-couchbase#readme).

Enterprise support for the Couchbase MCP Server is available by licensing Couchbase AI Data Plane, which also entitles use and enterprise support of Couchbase Agent Memory and Couchbase Agent Catalog.

### Installation

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

#### Install each skill manually (Claude Desktop)

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

---

## Couchbase Mobile Skills

Couchbase Mobile skills build a fully functioning **offline-first** mobile app — iOS (Swift) or Android (Kotlin/Compose) — that keeps running even with no internet connectivity. They provision a Capella App Services backend (app data, users, roles, and access-control functions), then generate a runnable app project built on the Couchbase Lite SDK as the local database, with bidirectional **cloud-to-edge** sync: the app works through a network drop and reconciles when it reconnects.

You interact with one recipe skill; it pulls in the others and generates a runnable iOS or Android project along with its backend.

| Skill Name | What it does |
|---|---|
| `couchbase-mobile-cloud-edge-sync-app` | The entry-point recipe — runs when you ask to build an app and drives the whole build |
| `couchbase-mobile-concepts-patterns` | Concepts: scopes/collections, channels, access patterns |
| `couchbase-mobile-access-control-function` | The App Services access-control (sync) function |
| `couchbase-appservices-provisioning` | Provisions the Capella / App Services backend |
| `couchbase-lite-ios-app` | iOS (Swift) client |
| `couchbase-lite-android-app` | Android (Kotlin / Compose) client |

### Getting started

Full prerequisites, versions, and step-by-step setup are in **[`plugins/couchbase-mobile/README.md`](./plugins/couchbase-mobile/README.md)**.

---

## Contributing

Authoring, validating, and testing skills is documented in
[`CONTRIBUTING.md`](./CONTRIBUTING.md). For testing specifics — eval suites and
the [harness sandbox](./testing/sandbox/README.md) — see [`testing/`](./testing/README.md).

## License

Apache-2.0. See [`LICENSE`](./LICENSE).
