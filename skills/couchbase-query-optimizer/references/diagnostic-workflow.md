# Diagnostic workflow

How to use the official Couchbase MCP server tools to find, diagnose, and fix slow queries. This is the operational complement to the conceptual references.

All tools are read-only by default — they don't mutate the cluster. Index DDL is output as a recommendation for the user to run.

## The five-step loop

```
1. FIND          →  get_longest_running_queries / get_most_frequent_queries / get_queries_*
2. UNDERSTAND    →  explain_sql_plus_plus_query — EXPLAIN + parsed findings
3. RECOMMEND     →  get_index_advisor_recommendations — ADVISE statement
4. CREATE        →  user runs DDL in Query Workbench / cbq (or run_sql_plus_plus_query with write mode)
5. VERIFY        →  explain_sql_plus_plus_query + run_sql_plus_plus_query with profile
```

Read-only mode (default) blocks step 4. The user runs the `CREATE INDEX` statement, or write mode is explicitly enabled with their approval.

## Step 1 — Find the slow queries (Pareto)

80% of perf problems come from 20% of queries. Find that 20% first.

```
Tool: get_longest_running_queries
```
Returns the top N queries by elapsed time, with statement, average duration, and count.

```
Tool: get_most_frequent_queries
```
Returns the top N by invocation count. Tuning a 0.1s query that runs 100/sec saves more than tuning a 10s query that runs once/hour.

```
Tool: get_queries_using_primary_index
```
Anything in this list is a high-priority fix — every entry is doing a full-keyspace scan.

```
Tool: get_queries_not_using_covering_index
```
Queries doing IndexScan + Fetch — candidates for promotion to a covering index.

```
Tool: get_queries_not_selective
```
Queries where the WHERE filter doesn't narrow the result set much. Often signals a wrong index or a missing predicate.

```
Tool: get_queries_with_largest_response_sizes
Tool: get_queries_with_large_result_count
```
Queries returning excessive data — candidates for projection pruning or pagination.

Sort the combined list by **(avg_duration × frequency)** to get the actual top-priority queries.

## Step 2 — Understand the plan

For each query from step 1:

```
Tool: explain_sql_plus_plus_query
Args: {"statement": "SELECT name FROM hotel WHERE state = 'CA'"}
```

Returns the EXPLAIN output plus a parsed findings block that flags common issues:
- `has_primary_scan: true` → ❌ uses PrimaryScan
- `has_intersect_scan: true` → ⚠ IntersectScan present
- `has_fetch: true` + `covers_count: 0` → ⚠ not covered
- `indexes_used: [...]` → which indexes the optimizer picked

Read the plan structure as described in `explain-plan.md`. The parsed findings give you a quick read; the full plan is for confirming hypotheses.

## Step 3 — Get an index recommendation

```
Tool: get_index_advisor_recommendations
Args: {"statement": "SELECT name FROM hotel WHERE state = 'CA'"}
```

This runs `ADVISE <statement>` against the cluster. Output includes:
- `recommended_indexes` — what to create
- `current_indexes` — what exists that could be used
- `recommended_covering_indexes` — if covering would help
- `recommended_partial_indexes` — if a low-cardinality predicate is present

ADVISE is conservative — it recommends the minimum index that would help. If you have multiple queries that could share a wider composite index, you might do better designing manually (see `index-design.md`).

If ADVISE doesn't recommend anything, the query is already optimal for the existing index set, OR the query has no usable index pattern (e.g., it's `SELECT * FROM keyspace` with no WHERE).

## Step 4 — Create the index

The MCP server runs read-only by default. To create the index, the user has two options:

**Option A: run in Query Workbench or cbq**

Output the `CREATE INDEX` DDL and have the user paste it into the Query Workbench or run it with `cbq`. This keeps the MCP server read-only at all times.

**Option B: run via run_sql_plus_plus_query with write mode**

```bash
# Restart the MCP server with read-only mode off
CB_MCP_READ_ONLY_MODE=false uv run server.py
```

Then run the DDL with explicit user approval. See `references/index-ddl.md` for the full `CREATE INDEX` syntax.

## Step 5 — Verify

Re-run `explain_sql_plus_plus_query` to confirm the new index is picked:

```
Tool: explain_sql_plus_plus_query
Args: {"statement": "SELECT name FROM hotel WHERE state = 'CA' AND name = 'Hilton'"}
```

Look for:
- The new index name in `indexes_used`
- `has_primary_scan: false`
- `has_intersect_scan: false`
- `has_fetch: false` if you built a covering index

Then run the query with profile to confirm real-world improvement:

```
Tool: run_sql_plus_plus_query
Args: {
  "statement": "SELECT name FROM hotel WHERE state = 'CA' AND name = 'Hilton'",
  "query_context": "default:travel-sample.inventory",
  "profile": "timings"
}
```

Returns results plus a profile section with `kernTime`, `servTime`, `execTime` per operator. Compare against the baseline you captured in step 1.

## A worked example

User reports: "The hotel-search page is slow."

```
1. get_longest_running_queries
   → Top result: "SELECT name, country FROM hotel WHERE state = $1 AND city = $2"
                 avg 1.8s, runs 240/min

2. explain_sql_plus_plus_query
   → Plan: PrimaryScan3 (hotel_primary), Fetch, Filter, InitialProject
   → Findings: has_primary_scan: true, covers_count: 0

3. get_index_advisor_recommendations
   → Recommended: CREATE INDEX adv_state_city
                    ON hotel(state, city)
   → Recommended covering: CREATE INDEX adv_state_city_cover
                             ON hotel(state, city, name, country)

4. Choose the covering variant (the query is hot enough to justify it)
   → Output DDL for the user to run in Query Workbench / cbq

5. explain_sql_plus_plus_query (re-run on same statement)
   → Plan: IndexScan3 (adv_state_city_cover) with covers=[state, city, name, country]
   → Findings: has_primary_scan: false, covers_count: 4, has_fetch: false

   run_sql_plus_plus_query with profile=timings
   → New runtime: 12ms (was 1800ms). servTime on scan now dominant, no Fetch.
```

Done. Move to the next query in the Pareto list.

## When to query system:completed_requests directly

The perf tools are pre-canned views. Sometimes you need a custom question, like "find queries that hit `idx_old_thing` so I can drop it":

```sql
SELECT statement, COUNT(*) AS hits
FROM system:completed_requests
WHERE preparedText LIKE '%idx_old_thing%'
   OR ANY plan IN ARRAY plans WITHIN ~child SATISFIES plan = 'idx_old_thing' END
GROUP BY statement
ORDER BY hits DESC;
```

Use `run_sql_plus_plus_query` to run this directly (read-only mode allows SELECT against system catalogs).

## Schema inference

Before designing an index, confirm the document shape. The schema isn't enforced — it's discovered.

```
Tool: get_schema_for_collection
Args: {
  "bucket_name": "travel-sample",
  "scope_name": "inventory",
  "collection_name": "hotel",
  "sample_size": 1000
}
```

Returns a unioned schema: every field that appears in the sampled docs, with its type and a sample value. Use it to confirm field names before writing the `CREATE INDEX` statement (typos in field names produce silently-empty indexes).

## Continuous monitoring

For ongoing operations, run a weekly review:

1. `get_longest_running_queries` — has anything new slipped in?
2. `get_queries_using_primary_index` — should always be empty in prod
3. `get_queries_not_using_covering_index` — review the top entries; promote to covering if they're hot
4. Drop indexes that don't appear in any plan over the past month — they're costing memory and write throughput for nothing

## What to do next

- Don't know what plan you're looking at → `explain-plan.md`
- Don't know what index to recommend → `index-design.md`
- Need exact CREATE / ALTER / DROP INDEX DDL → `index-ddl.md`
- Don't know what's wrong with the query → `query-patterns.md`
- CBO-specific question → `cost-based-optimizer.md`
- Pagination-specific question → `pagination.md`
