# Couchbase Agent Skills

Official Couchbase **agent skills** + **MCP server** for your favorite coding agent. Connect to a live Couchbase cluster, explore data, write and run SQL++, optimize queries and GSI indexes, design data models, and build full-text and vector search — grounded in your real cluster.

> **Status:** early scaffolding. The repository structure and skills are MCP-centric (the agent operates a live cluster via the Couchbase MCP server). Skill content is authored task-by-task; see `skills/` and the project's task breakdown.

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

> Replace the repository URL below with the final published location once the org/repo is confirmed.

| Harness | Install |
|---------|---------|
| **Claude Code** | Add the marketplace, then `/plugin install couchbase` |
| **Cursor** | Install from the Cursor marketplace / `/add-plugin couchbase` |
| **Codex** | `codex plugin marketplace add couchbase/agent-skills`, then install via the plugin browser |
| **Gemini CLI** | `gemini extensions install https://github.com/couchbase/agent-skills` |
| **GitHub Copilot CLI** | `/plugin install https://github.com/couchbase/agent-skills.git` (restart to activate the MCP server) |
| **Vercel Agent Skills** | `npx skills add couchbase/agent-skills` |

After installing, ensure the `CB_*` environment variables above are set so the MCP server can connect.

## Local development

```bash
# Validate skill structure
./tools/validate-skills.sh

# Run a skill's eval suite (see testing/)
./tools/validate-skills.sh && echo "structure OK"
```

## License

Apache-2.0. See [`LICENSE`](./LICENSE).
