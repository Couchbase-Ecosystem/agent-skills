# Query-shape optimization (beyond indexing)

Indexing is the primary lever, but the query's shape matters too. Join algorithms/order & hints live in
[`cost-based-optimizer.md`](cost-based-optimizer.md).

## Contents
- [`USE KEYS` (skip the index)](#use-keys-skip-the-index)
- [Predicate pushdown & selectivity](#predicate-pushdown--selectivity)
- [Projection](#projection)
- [JOINs](#joins)
- [Arrays / UNNEST](#arrays--unnest)
- [Pagination](#pagination)
- [LIMIT / ORDER BY](#limit--order-by)
- [Aggregations](#aggregations)
- [Prepared statements](#prepared-statements)
- [Scan consistency](#scan-consistency)
- [UPDATE / MERGE](#update--merge)

## `USE KEYS` (skip the index)
When the document key(s) are known, `… USE KEYS ["k1","k2"]` does a `KeyScan` — a direct KV fetch, bypassing
the index entirely. Fastest path; prefer it over a `meta().id` index scan (or fetch via the SDK directly).

## Predicate pushdown & selectivity
- Put the **most selective** filters in `WHERE` and ensure the **leading index key** matches one of them, so the index scan is bounded rather than full-range.
- Avoid wrapping indexed fields in functions in the `WHERE` clause (defeats the index — see antipatterns).

## Projection
- Don't `SELECT *` on hot paths — project only needed fields so a **covering** index can satisfy the query without a `Fetch`. `SELECT RAW expr` returns unwrapped scalars cheaply.

## JOINs
- For ANSI `JOIN … ON <pred>`, **index the probe-side join key** and drive from the **more-selective side**. Algorithm choice (`HashJoin` vs `NestedLoopJoin`), join order, and hints are CBO concerns → [`cost-based-optimizer.md`](cost-based-optimizer.md).
- A correlated subquery has the same cost shape as a nested-loop join — `EXPLAIN` both and pick the cheaper.

## Arrays / UNNEST
- Filter **before** `UNNEST` where possible to reduce the rows flattened.
- Back array predicates with a `DISTINCT ARRAY` index so `UNNEST`/`ANY … SATISFIES` use the index — the query's binding expression must match the index ([antipattern #13](index-antipatterns.md#13-unnest-or-any-binding-mismatch)).
- Turn `LIKE '%term%'` into an indexed array scan: index `DISTINCT ARRAY v FOR v IN SUFFIXES(LOWER(name)) END`, query `ANY v IN SUFFIXES(LOWER(name)) SATISFIES v LIKE 'term%' END`. (Mind index size — suffixes grow with string length.)
- `IN` matches the current array level only; `WITHIN` recurses into all descendant arrays — avoid `WITHIN` unless you truly need the recursion.

## Pagination
- Use **keyset pagination** (`WHERE sort_key > :last ORDER BY sort_key LIMIT n`) instead of large `OFFSET`, backed by an index on the sort key.
- `LIMIT`/`OFFSET` are pushed **into** `IndexScan3` (much cheaper) only when **all** hold: whole predicate fits one index · no `IntersectScan` · any `ORDER BY` matches the index key order · no `JOIN`. Otherwise they apply after the scan — verify in the plan (see [`diagnosis.md`](diagnosis.md)).

## LIMIT / ORDER BY
- Include a `LIMIT` so the planner can stop early.
- Back `ORDER BY` with an index whose keys match (and direction matches) to avoid an in-memory sort.

## Aggregations
- `GROUP BY` on indexed leading keys enables aggregate pushdown and avoids scanning.
- Combine N conditional counts into one scan with `CASE` instead of N separate `COUNT` queries: `COUNT(CASE WHEN cond THEN 1 END)` per metric.

## Prepared statements
- Re-planning a hot query each call wastes `parse`/`plan` time. Prepare once: SDK `adhoc=false`, or `PREPARE name FROM …` then `EXECUTE name`.
- Use named/positional parameters (`$1`, `$name`) for values — secure, and one cached plan serves all parameter values.

## Scan consistency
Indexes update asynchronously after a KV mutation (usually <1 ms). Per query, pick:
- `not_bounded` — default, fastest; reads the index as-is.
- `request_plus` — waits for the index to catch up (read-your-own-writes); slowest under heavy write load.
- `at_plus` — waits for specific mutation tokens (requires mutation tokens enabled).

For a single/handful of docs, KV access is strongly consistent and cheaper than `request_plus`.

## UPDATE / MERGE
- Constrain mutations with an **indexed predicate** (`UPDATE ks SET … WHERE <indexed pred>`) so they don't scan the whole keyspace.
- Use `MERGE` for conditional upserts. Keep mutation predicates selective and indexed — the same `EXPLAIN`/key-order/covering reasoning applies to the `WHERE` of a DML statement.
