# Couchbase Agent Skills — Gemini Context

This extension provides Couchbase Agent Skills and wires up the Couchbase MCP server.

- Skills live in `skills/<skill-name>/SKILL.md` and are loaded on demand.
- Skills are **MCP-centric**: operate a live Couchbase cluster via the configured MCP server. Ground answers in the real cluster (schema, indexes, `EXPLAIN`) rather than guessing.
- Treat the cluster as **read-only** unless the user explicitly approves a write or DDL statement.
- Use Couchbase terminology: Bucket → Scope → Collection, SQL++, GSI, the Search Service, Capella.

Required environment for the MCP server: `CB_CONNECTION_STRING`, `CB_USERNAME`, `CB_PASSWORD`, `CB_BUCKET_NAME`.
