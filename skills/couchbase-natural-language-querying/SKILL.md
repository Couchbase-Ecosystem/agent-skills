---
name: couchbase-natural-language-querying
description: >-
  Turn a plain-English data question into a read-only SQL++ query, grounded in
  the live cluster's actual schema, sample data, and indexes — then run it and
  return the results. Use when the user asks to write or generate a query, says
  "show me…", "how many…", "list…", "find documents where…", uses an
  analytical/computation opener like "what was the average…", "calculate…",
  "compute…", "what's the mean/max/total…", or otherwise wants to
  filter/group/aggregate Couchbase data in natural language. Applies even
  mid-conversation when a session that began as schema/setup/modeling pivots to
  answering a data question. Does NOT handle
  full-text, vector, or semantic search (use the Couchbase Search Service); does NOT
  analyze, optimize, or speed up queries or design indexes (use
  couchbase-query-optimizer); does NOT perform writes or run DDL (it may
  *suggest* a CREATE FUNCTION for the user to run). Requires the
  Couchbase MCP server.
license: Apache-2.0
---

# Couchbase Natural-Language Querying

Convert a natural-language question into **read-only SQL++**, grounded in the live cluster via the Couchbase MCP server, then **run it and return the results**. Always ground in the *actual* schema before writing SQL++ — never guess field names.

> **Read-only.** Never generate or run writes or DDL (`INSERT`/`UPDATE`/`DELETE`/`MERGE`/`CREATE`/`DROP`). The MCP server defaults to read-only mode — keep it that way for this skill.

> **One exception — UDFs are *suggested*, never run.** When creating a user-defined function clearly makes sense (a reusable computation the user wants to save, or a repeated derived expression), you may **present** a `CREATE FUNCTION` statement for the user to run themselves — in the Query Workbench / `cbq`, or after they enable writes. `CREATE FUNCTION` is DDL: **never execute it** (read-only mode blocks it anyway), and note it needs a "Manage Global/Scope Functions" role. Do this only when it genuinely earns its place — by default, don't mention UDFs at all. See [`references/sqlpp-udfs.md`](references/sqlpp-udfs.md).

> **Terminology: "N1QL" = "SQL++".** They name the same language. Always use **SQL++** in what you write and say. Couchbase's docs, URLs, and file names still use "N1QL" (e.g. `n1ql-language-reference`) — treat every such mention as SQL++.

> **Tool-call contract.** The query tools — `run_sql_plus_plus_query`, `explain_sql_plus_plus_query`, and `get_schema_for_collection` — take `bucket_name` and `scope_name` as **separate arguments** and set the scope context automatically. Write the query against **bare collection names**; never prefix or fully-qualify with bucket/scope. For example:
>
> ```
> run_sql_plus_plus_query(
>   bucket_name="travel-sample", scope_name="inventory",
>   query="SELECT airline, COUNT(*) AS routes FROM route GROUP BY airline ORDER BY routes DESC LIMIT 5")
> ```
>
> Putting the keyspace inside the query string (`` FROM `travel-sample`.inventory.route ``) is **incorrect**.

## Step 0 — Confirm the connection (pre-flight)

Before your **first cluster tool call**, verify connectivity once — so a missing connection fails fast and clearly instead of surfacing as a slow timeout deep in a data call:

1. Call `get_server_configuration_status` — it returns server status and `connections.cluster_connected` **without opening a connection** (instant, no timeout).
2. If it isn't already connected, call `test_cluster_connection` **once**. It returns a structured `{status, message}` rather than throwing a long `UnambiguousTimeoutException`.
3. If the cluster isn't reachable (`status: "error"` / not connected), **stop — do not retry cluster tools.** Tell the user the MCP server is installed but not connected, then hand off to **`couchbase-mcp-setup`** to configure the connection string and credentials.
4. Continue only once the connection is confirmed.

## Step 1 — Ground in the live cluster (before writing any SQL++)

- **Resolve the keyspace.** If the bucket/scope/collection isn't given, list them with `get_buckets_in_cluster` and `get_scopes_and_collections_in_bucket`, and confirm with the user.
- **Infer the structure.** Call `get_schema_for_collection` (it runs SQL++ `INFER`) to get fields, types, and nesting. `INFER` samples a subset of documents, so it can miss rare fields or schema variants — treat the result as a strong hint, not a complete catalog.
- **Look at real data.** Pull a few sample docs (a small `SELECT … LIMIT 4`, or `get_document_by_id`) to see actual values and shapes.
- **Know the indexes.** Call `list_indexes` for the keyspace (used for the coverage note in Step 5).
- **Check for relevant UDFs — only if the question warrants it.** If (and only if) the question maps onto a *named or reusable operation* (a unit conversion, a business rule, a domain computation) or the user references a function by name, run `SELECT identity, definition FROM system:functions` (read-only) once and reuse the result for the session. For a plain filter/aggregate/join, **skip this** — most clusters have no UDFs, and an empty result means there's nothing to use. See [`references/sqlpp-udfs.md`](references/sqlpp-udfs.md).

## Step 2 — Validate fields against the schema

- Check each field/path you reference against the inferred schema (including nested paths and array-element fields). Because `INFER` is sample-based, absence from the inferred shape isn't proof a field doesn't exist — if you expect a field that's missing, sample more docs or fetch a known key before concluding it's absent.
- **Couchbase silently returns `MISSING` for nonexistent fields** — a wrong field name yields empty or odd results, not an error. Cross-check names and correct or flag mismatches (e.g. `airport_name` → `airportname`).
- Respect case sensitivity of both field names and string values.

## Step 3 — Generate the SQL++

- **Pick the shape:** `SELECT … WHERE` for filters; `GROUP BY` + `COUNT/SUM/AVG` for aggregation; `JOIN` (`ON KEYS` / `ON`) for references; `UNNEST` for arrays.
- **Reference bare collection names** (e.g. `FROM route`), not `` `bucket`.`scope`.`collection` `` — `bucket_name`/`scope_name` are passed as tool arguments (the default scope is `scope_name="_default"`). Backtick-quote a collection name only if it's a reserved word or has special characters.
- Project only what's asked (avoid `SELECT *`); filter early in `WHERE`; prefer keyset pagination over large `OFFSET`.
- **Reuse an existing UDF only if it fits.** If Step 1 surfaced a UDF the question maps onto naturally, call it like a built-in (`SELECT to_meters(geo.alt) FROM airport`). UDF names are **case-sensitive**; an unqualified name resolves against the current `bucket_name`/`scope_name`. Otherwise just write the SQL++ inline — don't reach for a UDF. See [`references/sqlpp-udfs.md`](references/sqlpp-udfs.md).
- See [`references/sqlpp-patterns.md`](references/sqlpp-patterns.md) for SQL++ query shapes and syntax (joins, `UNNEST`, collection operators, subqueries). For evaluation rules (`NULL` vs `MISSING`, type collation, identifiers) see [`references/sqlpp-semantics.md`](references/sqlpp-semantics.md); for exact function names/signatures (especially date/time) see [`references/sqlpp-functions.md`](references/sqlpp-functions.md). Check these before guessing a function name.

## Step 4 — Run it read-only and return the results

- Execute via `run_sql_plus_plus_query`, passing `bucket_name` and `scope_name` as arguments. Read-only mode blocks data modification, so this is safe.
- For open-ended questions, add a sensible `LIMIT` before running so you don't pull a huge result set.
- Show the user **both the SQL++ and the results**. If the user only wants the query text ("don't run it"), skip execution.

## Step 5 — Note index coverage (don't optimize here)

- From `list_indexes` (or `explain_sql_plus_plus_query`, the dedicated tool that runs EXPLAIN and returns the plan — don't wrap your `SELECT` in `EXPLAIN` through the query tool), note whether the query is served by a GSI or would fall back to a primary/collection scan.
- If it's a scan or otherwise slow, say so briefly and **hand off to `couchbase-query-optimizer`** — do not design indexes or tune the query in this skill.

## Scope

- **In:** read-only `SELECT`/aggregation/`JOIN`/`UNNEST` queries, grounded in the live schema, run and returned.
- **Out (hand off):** full-text / vector / semantic search and `SEARCH()` → the Couchbase **Search Service** (FTS); query optimization, `EXPLAIN` analysis, index design → `couchbase-query-optimizer`; any write or DDL → refuse (read-only) — the one exception is **suggesting** (never running) a `CREATE FUNCTION` when a UDF clearly fits (see Step 3 / [`references/sqlpp-udfs.md`](references/sqlpp-udfs.md)).

## References

Four distilled SQL++ references — they keep only what differs from standard SQL, so the rest can be recalled directly. Load progressively: start with patterns, pull in the others as a query needs them (UDFs only when relevant).

- [`references/sqlpp-patterns.md`](references/sqlpp-patterns.md) — **start here.** Query shapes and SQL++-specific syntax: keyspace/tool contract, `SELECT RAW`/`*`, joins, `UNNEST`/`NEST`, collection operators (`ANY`/`EVERY`/comprehensions, `IN` vs `WITHIN`), subqueries, string matching, functions that don't exist, common traps.
- [`references/sqlpp-semantics.md`](references/sqlpp-semantics.md) — evaluation rules when a query returns surprising results: `NULL` vs `MISSING` (and `IS VALUED`), four-valued logic, type collation/sort order, identifiers & reserved words, literals.
- [`references/sqlpp-functions.md`](references/sqlpp-functions.md) — function catalog (SQL++-specific names/signatures only): date/time (formats, parts, `STR`/`MILLIS` families), array, object, conditional, type, string, regex, window. Check here before guessing a function name; the official reference is linked as the fallback.
- [`references/sqlpp-udfs.md`](references/sqlpp-udfs.md) — **User-Defined Functions, only when relevant.** Discover existing UDFs (`system:functions`), call them (case-sensitivity, qualification, arg-count error `10104`), and — only when a UDF clearly fits — *present* (never run) a `CREATE FUNCTION`. Stay silent about UDFs by default.
