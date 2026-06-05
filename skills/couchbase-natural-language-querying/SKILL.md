---
name: couchbase-natural-language-querying
description: >-
  Turn a plain-English data question into a read-only SQL++ query, grounded in
  the live cluster's actual schema, sample data, and indexes — then run it and
  return the results. Use when the user asks to write or generate a query, says
  "show me…", "how many…", "list…", "find documents where…", or wants to
  filter/group/aggregate Couchbase data in natural language. Does NOT handle
  full-text, vector, or semantic search (use couchbase-search-and-ai); does NOT
  analyze, optimize, or speed up queries or design indexes (use
  couchbase-query-optimizer); does NOT perform writes or DDL. Requires the
  Couchbase MCP server.
license: Apache-2.0
metadata:
  version: "0.1.0"
allowed-tools: mcp__couchbase__*
---

# Couchbase Natural-Language Querying

Convert a natural-language question into **read-only SQL++**, grounded in the live cluster via the Couchbase MCP server, then **run it and return the results**. Always ground in the *actual* schema before writing SQL++ — never guess field names.

> **Read-only.** Never generate or run writes or DDL (`INSERT`/`UPDATE`/`DELETE`/`MERGE`/`CREATE`/`DROP`). The MCP server defaults to read-only mode — keep it that way for this skill.

## Step 1 — Ground in the live cluster (before writing any SQL++)

- **Resolve the keyspace.** If the bucket/scope/collection isn't given, list them with `get_buckets_in_cluster` and `get_scopes_and_collections_in_bucket`, and confirm with the user.
- **Infer the structure.** Call `get_schema_for_collection` (it runs SQL++ `INFER`) to get fields, types, and nesting.
- **Look at real data.** Pull a few sample docs (a small `SELECT … LIMIT 4`, or `get_document_by_id`) to see actual values and shapes.
- **Know the indexes.** Call `list_indexes` for the keyspace (used for the coverage note in Step 5).

## Step 2 — Validate fields against the schema

- Every field/path you reference must exist in the inferred schema (including nested paths and array-element fields).
- **Couchbase silently returns `MISSING` for nonexistent fields** — a wrong field name yields empty or odd results, not an error. Cross-check names and correct or flag mismatches (e.g. `airport_name` → `airportname`).
- Respect case sensitivity of both field names and string values.

## Step 3 — Generate the SQL++

- **Pick the shape:** `SELECT … WHERE` for filters; `GROUP BY` + `COUNT/SUM/AVG` for aggregation; `JOIN` (`ON KEYS` / `ON`) for references; `UNNEST` for arrays.
- **Fully-qualify the keyspace with backticks:** `` `bucket`.`scope`.`collection` `` (default scope/collection is `_default`).
- Project only what's asked (avoid `SELECT *`); filter early in `WHERE`; prefer keyset pagination over large `OFFSET`.
- See [`references/sqlpp-patterns.md`](references/sqlpp-patterns.md) for MQL→SQL++ mappings and SQL++ idioms (arrays, `NULL` vs `MISSING`, `META().id`, `USE KEYS`).

## Step 4 — Run it read-only and return the results

- Execute via `run_sql_plus_plus_query`. Read-only mode blocks data modification, so this is safe.
- For open-ended questions, add a sensible `LIMIT` before running so you don't pull a huge result set.
- Show the user **both the SQL++ and the results**. If the user only wants the query text ("don't run it"), skip execution.

## Step 5 — Note index coverage (don't optimize here)

- From `list_indexes` (or a quick `EXPLAIN`), note whether the query is served by a GSI or would fall back to a primary/collection scan.
- If it's a scan or otherwise slow, say so briefly and **hand off to `couchbase-query-optimizer`** — do not design indexes or tune the query in this skill.

## Scope

- **In:** read-only `SELECT`/aggregation/`JOIN`/`UNNEST` queries, grounded in the live schema, run and returned.
- **Out (hand off):** full-text / vector / semantic search and `SEARCH()` → `couchbase-search-and-ai`; query optimization, `EXPLAIN` analysis, index design → `couchbase-query-optimizer`; any write or DDL → refuse (read-only).

## References

- [`references/sqlpp-patterns.md`](references/sqlpp-patterns.md) — MQL→SQL++ translation, keyspace syntax, arrays, `NULL` vs `MISSING`, projection, pagination.
