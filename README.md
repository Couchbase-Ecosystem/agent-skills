# Couchbase Agent Skills

Official Couchbase **agent skills** + **MCP server** for your favorite coding agent. Connect to a live Couchbase cluster, explore data, write and run SQL++, optimize queries and GSI indexes, design data models, and build full-text and vector search — grounded in your real cluster.

> **Status:** v1 skills built — MCP-centric (the agent operates a live cluster via the Couchbase MCP server): `couchbase-mcp-setup`, `couchbase-connection`, `couchbase-natural-language-querying`, `couchbase-query-optimizer`, `couchbase-data-modeling`, `couchbase-search-and-ai`.

## What's here

| Path | Purpose |
|------|---------|
| `skills/` | Agent Skills (one directory per skill, each with a `SKILL.md`). |
| `mcp.json` | Couchbase MCP server wiring (consumed by the plugin manifests). |
| `.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`, `.agents/`, `gemini-extension.json` | Per-harness plugin/extension manifests. |
| `tools/` | Repo tooling — skill validator and the `review-skill` meta-tool. |
| `testing/` | Per-skill evaluation suites (`evals.json`). |

## Prerequisites: the Couchbase MCP server

These skills act on a live cluster through the [Couchbase MCP server](https://github.com/Couchbase-Ecosystem/mcp-server-couchbase) (`couchbase-mcp-server`). It runs via [`uv`](https://docs.astral.sh/uv/) (`uvx`) or Docker — **not** a plain `npx` command.

Set these environment variables (the manifests reference them):

| Variable | Description | Default |
|----------|-------------|---------|
| `CB_CONNECTION_STRING` | Cluster connection string, e.g. `couchbases://cb.xxxx.cloud.couchbase.com` | **required** |
| `CB_USERNAME` | Database username | **required** |
| `CB_PASSWORD` | Database password | **required** |
| `CB_BUCKET_NAME` | Bucket to access | **required** |
| `CB_MCP_READ_ONLY_QUERY_MODE` | Block data-modifying queries | `true` |

For first-time configuration, use the `couchbase-mcp-setup` skill, or see the [MCP server docs](https://github.com/Couchbase-Ecosystem/mcp-server-couchbase#readme).

## Install

The repo at [`Couchbase-Ecosystem/agent-skills`](https://github.com/Couchbase-Ecosystem/agent-skills) is itself the plugin / marketplace source — install directly from it:

| Harness | Install |
|---------|---------|
| **Claude Code** | `/plugin marketplace add Couchbase-Ecosystem/agent-skills`, then `/plugin install couchbase@couchbase-plugins` |
| **Codex** | `codex plugin marketplace add Couchbase-Ecosystem/agent-skills`, then install `couchbase` from the plugin browser |
| **Gemini CLI** | `gemini extensions install https://github.com/Couchbase-Ecosystem/agent-skills` |
| **GitHub Copilot CLI** | `copilot plugin marketplace add Couchbase-Ecosystem/agent-skills`, then `/plugin install couchbase@couchbase-plugins` (restart to activate the MCP server) |
| **Cursor** | Add `Couchbase-Ecosystem/agent-skills` as a plugin marketplace, then install `couchbase` via `/add-plugin` or the marketplace UI |
| **Vercel Agent Skills** | `npx skills add Couchbase-Ecosystem/agent-skills` |

After installing, set the `CB_*` environment variables above so the MCP server can connect — or run the **`couchbase-mcp-setup`** skill, which walks you through it per harness.

## Local development

```bash
# Validate skill structure (frontmatter, links, sizes)
./tools/validate-skills.sh

# Validate eval-suite schema (no API key needed)
python3 tools/run-evals.py --dry-run

# Run behavioral evals against a model (needs ANTHROPIC_API_KEY or OPENAI_API_KEY) — see testing/
python3 tools/run-evals.py --execute
```

## License

Apache-2.0. See [`LICENSE`](./LICENSE).
