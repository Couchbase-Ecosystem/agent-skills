---
name: couchbase-natural-language-querying
description: >-
  Turn a plain-English data question into a read-only SQL++ query, grounded in
  the live cluster's actual schema, sample data, and indexes — then run it and
  return the results. Use when the user asks to write or generate a query, says
  "show me…", "how many…", "list…", "find documents where…", or wants to
  filter/group/aggregate Couchbase data in natural language. Does NOT handle
  full-text, vector, or semantic search (use the Couchbase Search Service); does NOT
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

> **Tool-call contract.** The query tools — `run_sql_plus_plus_query`, `explain_sql_plus_plus_query`, and `get_schema_for_collection` — take `bucket_name` and `scope_name` as **separate arguments** and set the scope context automatically. Write the query against **bare collection names**; never prefix or fully-qualify with bucket/scope. For example:
>
> ```
> run_sql_plus_plus_query(
>   bucket_name="travel-sample", scope_name="inventory",
>   query="SELECT airline, COUNT(*) AS routes FROM route GROUP BY airline ORDER BY routes DESC LIMIT 5")
> ```
>
> Putting the keyspace inside the query string (`` FROM `travel-sample`.inventory.route ``) is **incorrect**.

## Step 1 — Ground in the live cluster (before writing any SQL++)

- **Resolve the keyspace.** If the bucket/scope/collection isn't given, list them with `get_buckets_in_cluster` and `get_scopes_and_collections_in_bucket`, and confirm with the user.
- **Infer the structure.** Call `get_schema_for_collection` (it runs SQL++ `INFER`) to get fields, types, and nesting. `INFER` samples a subset of documents, so it can miss rare fields or schema variants — treat the result as a strong hint, not a complete catalog.
- **Look at real data.** Pull a few sample docs (a small `SELECT … LIMIT 4`, or `get_document_by_id`) to see actual values and shapes.
- **Know the indexes.** Call `list_indexes` for the keyspace (used for the coverage note in Step 5).

## Step 2 — Validate fields against the schema

- Check each field/path you reference against the inferred schema (including nested paths and array-element fields). Because `INFER` is sample-based, absence from the inferred shape isn't proof a field doesn't exist — if you expect a field that's missing, sample more docs or fetch a known key before concluding it's absent.
- **Couchbase silently returns `MISSING` for nonexistent fields** — a wrong field name yields empty or odd results, not an error. Cross-check names and correct or flag mismatches (e.g. `airport_name` → `airportname`).
- Respect case sensitivity of both field names and string values.

## Step 3 — Generate the SQL++

- **Pick the shape:** `SELECT … WHERE` for filters; `GROUP BY` + `COUNT/SUM/AVG` for aggregation; `JOIN` (`ON KEYS` / `ON`) for references; `UNNEST` for arrays.
- **Reference bare collection names** (e.g. `FROM route`), not `` `bucket`.`scope`.`collection` `` — `bucket_name`/`scope_name` are passed as tool arguments (the default scope is `scope_name="_default"`). Backtick-quote a collection name only if it's a reserved word or has special characters.
- Project only what's asked (avoid `SELECT *`); filter early in `WHERE`; prefer keyset pagination over large `OFFSET`.
- See [`references/sqlpp-patterns.md`](references/sqlpp-patterns.md) for SQL++ literals, operators, functions, query shapes, subqueries, arrays, and `NULL` vs `MISSING` — and look up functions in the linked official reference rather than guessing.

## Step 4 — Run it read-only and return the results

- Execute via `run_sql_plus_plus_query`, passing `bucket_name` and `scope_name` as arguments. Read-only mode blocks data modification, so this is safe.
- For open-ended questions, add a sensible `LIMIT` before running so you don't pull a huge result set.
- Show the user **both the SQL++ and the results**. If the user only wants the query text ("don't run it"), skip execution.

## Step 5 — Note index coverage (don't optimize here)

- From `list_indexes` (or `explain_sql_plus_plus_query`, the dedicated tool that runs EXPLAIN and returns the plan — don't wrap your `SELECT` in `EXPLAIN` through the query tool), note whether the query is served by a GSI or would fall back to a primary/collection scan.
- If it's a scan or otherwise slow, say so briefly and **hand off to `couchbase-query-optimizer`** — do not design indexes or tune the query in this skill.

## Scope

- **In:** read-only `SELECT`/aggregation/`JOIN`/`UNNEST` queries, grounded in the live schema, run and returned.
- **Out (hand off):** full-text / vector / semantic search and `SEARCH()` → the Couchbase **Search Service** (FTS); query optimization, `EXPLAIN` analysis, index design → `couchbase-query-optimizer`; any write or DDL → refuse (read-only).

## References

- [`references/sqlpp-patterns.md`](references/sqlpp-patterns.md) — SQL++ literals, operators, functions, query shapes, subqueries, arrays, `NULL` vs `MISSING`, projection, pagination (with links to the official function and reserved-word references).
