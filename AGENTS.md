# Couchbase Agent Skills — Agent Guide

This repository provides Couchbase **Agent Skills** plus the Couchbase **MCP server** wiring.

- Skills live in `skills/<skill-name>/SKILL.md`. Each skill is a focused playbook the agent loads on demand.
- The skills are **MCP-centric**: they operate a live Couchbase cluster through the Couchbase MCP server (see `mcp.json`). Ground answers in the real cluster (schema, indexes, `EXPLAIN`) rather than guessing.
- Treat the cluster as **read-only** unless the user explicitly approves a write or DDL statement.
- Use Couchbase terminology: Bucket → Scope → Collection, SQL++, GSI, the Search Service, Capella.

To set up the MCP connection, see the `couchbase-mcp-setup` skill or the [MCP server docs](https://github.com/couchbase/mcp-server-couchbase#readme). Required env: `CB_CONNECTION_STRING`, `CB_USERNAME`, `CB_PASSWORD`.
