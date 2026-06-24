# Diagnosing slow SQL++

Read an `EXPLAIN` plan, and find the slow queries on a cluster. Couchbase-specific operator names, plan
attributes, and system catalogs only — see [`cost-based-optimizer.md`](cost-based-optimizer.md) for why a
plan was chosen, [`index-antipatterns.md`](index-antipatterns.md) for symptom→fix.

## Contents
- [Three questions for any plan](#three-questions-for-any-plan)
- [Plan operators (red flags)](#plan-operators-red-flags)
- [Index scan spans](#index-scan-spans)
- [Runtime timings & counts](#runtime-timings--counts)
- [Finding slow queries cluster-wide](#finding-slow-queries-cluster-wide)
- [Cancel & clean up requests](#cancel--clean-up-requests)

## Three questions for any plan
Read the plan bottom-up and answer, in order:
1. **Access method?** `IndexScan3` good · `PrimaryScan3` bad (no usable GSI) · `KeyScan` best (`USE KEYS`).
2. **Is there a `Fetch`?** If yes the query is *not* covered — a KV lookup runs per row. Acceptable for few rows, costly for many. To cover, add the projected/filtered fields to the index keys.
3. **Were `spans`/`limit`/`offset` pushed into the scan?** If `limit`/`offset` sit in a later `Limit`/`Offset`/`Order` operator instead of inside `IndexScan3`, pagination wasn't pushed down (see [`query-optimization.md`](query-optimization.md)).

## Plan operators (red flags)
Scan operators carry a **version suffix** (`IndexScan3`, `PrimaryScan3`, today's default; older clusters emit `IndexScan2`/`IndexScan`). **Match on the prefix, not the literal string.**

| Operator | Means | Action |
|---|---|---|
| `PrimaryScan3` | Full-keyspace scan; no satisfying GSI. **Worst case in prod.** | Build a targeted GSI. Also fires as a fallback when the intended index is offline. |
| `IndexScan3` | Normal secondary-index scan. | Check `covers` field + presence of `Fetch`. |
| `KeyScan` | Direct key access via `USE KEYS`. | Optimal; nothing to fix. |
| `IndexCountScan` | `COUNT()` answered from the index. | Good. |
| `Fetch` | KV fetch after the scan → query not covered. | Cover the query if the row count is high. |
| `IntersectScan` / `OrderedIntersectScan` | 2+ single-key indexes intersected. | Usually replace with one **composite** index. |
| `UnionScan` | `OR`/`IN` across indexes unioned. | Consider an **array** index over the OR'd fields. |
| `DistinctScan` | Dedup wrapper (array index, `IN`). | Usually fine. |
| `NestedLoopJoin` | Inner side scanned once per outer row. | Inner `~child` must be `IndexScan3`, never `PrimaryScan3`. See [`cost-based-optimizer.md`](cost-based-optimizer.md). |
| `HashJoin` | Smaller side hashed, larger probed. | `build_alias` = hashed side; should be the smaller one. |
| `UnnestScan` | Array-index scan for `UNNEST`. | Binding var must match the index expression. |

A covered scan shows the keys under `covers` and filtered equality predicates under `filter_covers`; no `Fetch` follows.

## Index scan spans
A scan's `spans.range` shows what the predicate bounded the index to — `Low`, `High`, `Inclusion`:

| Inclusion | Meaning |
|---|---|
| `0` | NEITHER bound included |
| `1` | LOW only (`>=`, `<`) |
| `2` | HIGH only |
| `3` | BOTH (`>= … <=`) |

Missing `Low` ⇒ defaults to `MISSING` (scans from the start); missing `High` ⇒ unbounded to the end. `LIKE '%x%'` and `LIKE '%x'` produce a `""`→`"[]"` span (whole-index range); only `LIKE 'x%'` bounds it. An `OR` produces multiple independent ranges.

## Runtime timings & counts
`explain_sql_plus_plus_query` returns the **static plan only** (operators + `optimizer_estimates`). Runtime timings/counts are **not** in EXPLAIN and there is **no MCP profiling tool** — read them from the `system:completed_requests` catalog (`phaseTimes`, `phaseCounts`, `phaseOperators`). Per operator, `#stats` carries `#itemsIn`/`#itemsOut`.

| Field | High value means |
|---|---|
| `servTime` | Time waiting on the Index/Data service → stressed indexer or KV. |
| `kernTime` | Time waiting on the Go scheduler → a downstream operator is the bottleneck (or many concurrent requests). |
| `execTime` | Time the operator itself ran. |

`#itemsIn ≫ #itemsOut` on a scan = the index returned far more than the query kept → poor selectivity; tighten the index/predicate.

## Finding slow queries cluster-wide
The MCP server wraps the slow-query catalogs. Use these when the user asks "what's slow on my cluster?":

| Tool | Surfaces |
|---|---|
| `get_longest_running_queries` | Highest average `serviceTime`. |
| `get_most_frequent_queries` | Highest call count (the 80/20 to fix first). |
| `get_queries_using_primary_index` | `PrimaryScan` users — top fix list. |
| `get_queries_not_using_covering_index` | Candidates to promote to a covering index. |
| `get_queries_not_selective` | `WHERE` barely narrows the scan. |
| `get_queries_with_largest_response_sizes` | Biggest payloads (often `SELECT *`). |
| `get_queries_with_large_result_count` | Most rows returned. |

(A fresh/local cluster may have little history — say so if these return empty.)

For control beyond the wrappers, query the catalogs directly with `run_sql_plus_plus_query` (read-only):
- `system:completed_requests` — completed queries over `completed-threshold` (default 1000 ms; `completed-limit` keeps 4000). Key fields: `statement`, `serviceTime`, `elapsedTime`, `phaseCounts`, `state`, `clientContextID`.
- `system:active_requests` — currently executing queries.

```sql
-- Slowest statements by avg service time (durations are strings → convert)
SELECT statement, COUNT(1) AS runs, AVG(STR_TO_DURATION(serviceTime)) AS avg_ns
FROM system:completed_requests
WHERE UPPER(statement) NOT LIKE 'INFER%' AND UPPER(statement) NOT LIKE 'CREATE INDEX%'
GROUP BY statement ORDER BY avg_ns DESC;

-- Queries that hit a primary scan
SELECT statement, phaseCounts FROM system:completed_requests
WHERE phaseCounts.`primaryScan` IS NOT MISSING;

-- Non-covered (scanned an index, then fetched)
SELECT statement FROM system:completed_requests
WHERE phaseCounts.`indexScan` IS NOT MISSING AND phaseCounts.`fetch` IS NOT MISSING;
```

## Cancel & clean up requests
Both require write mode (recommend, don't run by default):
```sql
DELETE FROM system:active_requests   WHERE requestId = "...";   -- cancel a running query
DELETE FROM system:completed_requests WHERE statement = "...";  -- drop a fixed query from the log
```
