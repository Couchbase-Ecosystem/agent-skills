---
name: couchbase-query-optimizer
description: >-
  Diagnose and fix slow SQL++ queries and design GSI indexes for Couchbase,
  grounded in real EXPLAIN plans and the index advisor on the live cluster. Use
  ONLY when the user asks for performance or indexing help — "why is this query
  slow?", "how do I index this?", "optimize this SQL++", "what are the slow
  queries on my cluster?", "my query does a primary scan". Only engage to
  diagnose or speed up an *existing* query or design an index. Do NOT use to
  write or generate a query — even one meant to run slowly or "beyond N
  seconds"; that is query authoring, not optimization (use
  couchbase-natural-language-querying). Not for document/data modeling or key
  design (use couchbase-data-modeling). Prefer GSI indexing as the optimization
  strategy. Requires the Couchbase MCP server.
license: Apache-2.0
metadata:
  version: "0.1.0"
allowed-tools: mcp__couchbase__*
---

# Couchbase Query Optimizer

Diagnose slow SQL++ and recommend **GSI** (Global Secondary Index) designs using the live cluster's real `EXPLAIN` plans, the index advisor, and (cluster-wide) slow-query tools via the Couchbase MCP server.

> **Recommend, don't apply.** This skill **diagnoses (read-only)** and **outputs `CREATE INDEX` DDL** — it does not create indexes. The MCP server is read-only by default, so DDL won't run unless the user explicitly enables writes. Have the user run the DDL in the Query Workbench / `cbq`, or grant explicit approval.

## Step 1 — Determine the context

- **Specific query** ("why is *this* slow / how do I index this") → single-query diagnosis.
- **Cluster-wide** ("what are the slow queries on my cluster?") → use the slow-query-analysis tools.

## Step 2 — Gather metadata (read-only MCP)

**Specific query:**
- `list_indexes` — existing GSIs on the keyspace.
- `explain_sql_plus_plus_query` — the execution plan.
- `get_index_advisor_recommendations` — `ADVISE` suggestions for the query.
- `get_schema_for_collection` — field names/types, so recommended keys are valid.

**Cluster-wide:**
- `get_queries_using_primary_index`, `get_queries_not_using_covering_index`, `get_queries_not_selective`, `get_longest_running_queries`, `get_most_frequent_queries`.

(A fresh local cluster may have little query history — say so if these come back empty.)

## Step 3 — Diagnose the plan

Read the `EXPLAIN` output for the tell-tale operators. Scan operators carry a version suffix (e.g. `PrimaryScan3`, `IndexScan3`), so match on the prefix, not the literal string:
- **`PrimaryScan3`** → no suitable GSI; the query scans every key. The biggest red flag in production.
- **`IndexScan3`** → the normal secondary-index scan; check its `covers` field (and whether the plan has a `Fetch`) to tell if it's covered.
- **`Fetch`** present → not covered; documents are fetched after the index scan.
- **`IntersectScan` / `OrderedIntersectScan`** → multiple single-key indexes intersected; usually a sign you want one composite index.
- **`DistinctScan` / `UnionScan`** → a scan wrapping an index scan (array-index dedup, `OR`/`IN` unions); usually fine, but check selectivity and whether one composite index is better.
- **Large `OFFSET` / no `LIMIT`** → pagination/selectivity problem.

Assess selectivity (how many items the index scan returns vs. the final result). → [`references/core-indexing-principles.md`](references/core-indexing-principles.md), [`references/index-antipatterns.md`](references/index-antipatterns.md).

## Step 4 — Recommend a GSI design

- **Key order:** equality-predicate fields first, then sort, then range. Match the sort direction (`DESC` in the key).
- **Covering:** include the `WHERE` + `SELECT` + `ORDER BY` fields in the index keys so the plan drops the `Fetch`.
- **Partial** (`WHERE` on the index) for filtered subsets; **array** (`DISTINCT ARRAY …`) for array/`UNNEST` predicates.
- If statistics are stale (e.g., after a bulk load), recommend `UPDATE STATISTICS`.
- Output the **exact `CREATE INDEX` statement**. → [`references/index-ddl.md`](references/index-ddl.md) (syntax), [`references/query-optimization.md`](references/query-optimization.md) (query-shape fixes beyond indexing).

## Step 5 — Communicate (recommend, don't apply)

- Present the diagnosis, the `CREATE INDEX` DDL, and the reasoning concisely.
- **Do not auto-run `CREATE INDEX`.** Tell the user to run it (Query Workbench / `cbq`), or proceed only with explicit approval and write mode enabled.
- Note the trade-off: every index adds write/maintenance cost — recommend only what the workload needs, and flag redundant or unused indexes.

## Scope

- **In:** diagnosing slow SQL++ via `EXPLAIN`/`ADVISE`, GSI design, index antipatterns, query-shape tuning.
- **Out (hand off):** writing a query from scratch without a performance angle → `couchbase-natural-language-querying`; document structure / key design / embedding → `couchbase-data-modeling`.

## References

- [`references/core-indexing-principles.md`](references/core-indexing-principles.md) — key order, covering, sort direction, array indexing, selectivity, statistics.
- [`references/index-antipatterns.md`](references/index-antipatterns.md) — common indexing mistakes + fixes.
- [`references/index-ddl.md`](references/index-ddl.md) — `CREATE`/`ALTER`/`DROP`/`BUILD INDEX`, replicas/partitioning, monitoring, hints, statistics.
- [`references/query-optimization.md`](references/query-optimization.md) — query-shape tuning beyond indexes (pushdown, JOIN order, `UNNEST`, pagination, `UPDATE`/`MERGE`).
