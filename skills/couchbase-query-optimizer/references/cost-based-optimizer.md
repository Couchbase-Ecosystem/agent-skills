# Cost-based optimizer (CBO)

Couchbase's cost-based optimizer (CBO) went GA in **Couchbase Server 7.0** (Enterprise Edition) — preview was in 6.5. Couchbase Server **7.6** added meaningful improvements: automatic statistics gathering when an index is created or built, plus richer join enumeration. CBO doesn't replace the rule-based logic; it augments it where statistics make a better choice possible.

The skill text below assumes 7.0+ for the basic CBO and 7.6+ for the join-enumeration and auto-stats behaviors.

## What CBO does

- **Estimates cost** of alternative join orders and access methods using statistics on indexes and collections
- **Picks the cheaper plan** when multiple equivalent plans exist (e.g., choosing between two indexes, or two join orders)
- **Chooses between NestedLoopJoin and HashJoin** based on estimated cardinality

What it doesn't do:
- Pick a different secondary index for a single-keyspace query if statistics are missing — falls back to rule-based logic
- Magically fix a query with no usable index
- Help if statistics are missing or stale (pre-7.6 — you must run `UPDATE STATISTICS` manually)

## Enabling CBO

CBO is enabled by default in 7.0+ on Couchbase Server Enterprise Edition and Capella. To deactivate it for a single request:

```sql
SET `query_use_cbo` = false;
SELECT ...;
```

Or via the N1QL Feature Control field at the cluster level. Generally don't disable it — when it's wrong, fix the statistics or add a hint rather than turning the whole thing off.

## Verifying CBO is running
```sql
-- The plan output will include "optimizer_estimates" on each operator if CBO is on
EXPLAIN SELECT a.field FROM a JOIN b ON a.id = b.id;
```

Look for `optimizer_estimates` blocks in the plan:
```json
{
  "#operator": "IndexScan3",
  "index": "idx_a_field",
  "optimizer_estimates": {
    "cardinality": 24024,
    "cost": 4108.6,
    "fr_cost": 12.17,
    "size": 11
  }
}
```

If `optimizer_estimates` is missing, CBO didn't run (either disabled, stats missing, or below 7.6).

## Statistics — the prerequisite

CBO needs statistics on indexes to estimate cost. Stats are gathered with `UPDATE STATISTICS`:

```sql
UPDATE STATISTICS FOR `travel-sample`.inventory.hotel(state, city, name);
```

Without stats, CBO falls back to defaults or skips its analysis. Symptoms of missing stats:
- `optimizer_estimates` blocks have placeholder costs
- The plan is identical to the pre-7.6 rule-based plan
- Joins are always NestedLoopJoin (HashJoin requires cardinality info)

For production: run `UPDATE STATISTICS` after large data loads and on a schedule (weekly is typical). Use `run_sql_plus_plus_query` to run this statement when read-only mode is off.

## CBO hints

CBO supports hint comments that override its decisions for a single query. Hints live in a block comment immediately after the keyword they modify.

### productivity hint

For joins where one side is much smaller, the `productivity` hint tells CBO the expected ratio of rows joining successfully:

```sql
SELECT /*+ ORDERED */ a.name, b.detail
FROM small_table a
INNER JOIN large_table b USE HASH(probe) ON a.id = b.foreign_id
WHERE a.flag = true;
```

When to use it: foreign-key joins where most rows on the small side find a match on the large side. Without the hint, CBO might over-estimate the join cardinality and pick a sub-optimal plan.

### USE INDEX

Forces a specific index (not strictly a CBO feature — works in both rule-based and CBO modes):

```sql
SELECT *
FROM hotel USE INDEX (idx_state_city_cover)
WHERE state = 'CA' AND city = 'Berkeley';
```

### USE HASH / USE NL

Forces the join algorithm:

```sql
SELECT *
FROM a
JOIN b USE HASH(probe) ON a.id = b.foreign_id;

SELECT *
FROM a
JOIN b USE NL ON a.id = b.foreign_id;
```

- `USE HASH(probe)` — b is the probe side; a is the build side
- `USE HASH(build)` — b is the build side
- `USE NL` — force nested-loop join (cheap if outer side is small, expensive otherwise)

### ORDERED

Forces the join order specified in the FROM clause; CBO won't reorder:

```sql
SELECT /*+ ORDERED */ a.name, b.detail, c.summary
FROM a
JOIN b ON a.id = b.foreign_id
JOIN c ON b.id = c.foreign_id;
```

Use when you know the right order (smallest result set first) and CBO is picking wrong.

## When to use hints vs. when to fix the underlying issue

Hints are duct tape. They work, but:
- They embed implementation knowledge into the query
- They drift as data shape changes
- They make queries harder to maintain

Prefer fixing the root cause when possible:
- Wrong index picked → restructure index keys, or add stats
- Wrong join order → add stats, then run `UPDATE STATISTICS`
- Stats stale → schedule `UPDATE STATISTICS` regularly

Use hints when:
- You've confirmed via EXPLAIN that the forced plan is genuinely better
- The issue is transient (e.g., during a data migration when stats are temporarily wrong)
- You need predictable performance for a specific critical query

## Analytics service has its own parameters

The Analytics service (separate from the Query service) has its own set of CBO-style parameters set via SET:

```sql
SET `compiler.parallelism` = 4;
SET `compiler.queryplanshape` = "zigzag";

SELECT ...
```

Common Analytics parameters:
| Parameter | Effect |
|---|---|
| `compiler.parallelism` | Number of parallel partitions for query execution |
| `compiler.queryplanshape` | Hash-join plan shape: `zigzag` (default), `leftdeep`, `rightdeep` |
| `compiler.sort.parallel` | Enable full parallel sort (true) or merge-on-one-node (false) |
| `compiler.framesize` | Frame size for buffered operators |

These don't affect query correctness, only performance characteristics. They're set per request and don't persist.

## Verifying CBO improvements

When testing whether CBO made a query faster:

1. Run the query with `profile: 'timings'` and capture `kernTime` / `servTime` / `execTime` per operator
2. Make the change (add stats, add hint, restructure index)
3. Re-run with profile
4. Compare total runtime AND per-operator timings — a faster total runtime that's just trading one slow operator for another isn't a real win

`run_sql_plus_plus_query` returns the profile when invoked with the profile option enabled. Wire this into the diagnostic loop in `diagnostic-workflow.md`.

## What to do next

- Pre-7.6 cluster, or non-join query → `query-patterns.md` and `index-design.md`
- Diagnosing a slow join → `joins-and-cbo.md`
- Wiring this into a workflow → `diagnostic-workflow.md`
