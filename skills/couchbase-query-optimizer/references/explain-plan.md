# Reading the EXPLAIN plan

Every SQL++ tuning conversation starts here. EXPLAIN produces a tree of operators describing how the Query service plans to execute the statement. The tree tells you exactly which index will be used, what gets fetched, and where time will be spent.

## Getting the plan

Three ways to get the plan:

```sql
-- 1. Prefix any query with EXPLAIN
EXPLAIN SELECT name FROM `travel-sample`.inventory.hotel WHERE state = 'CA';

-- 2. The Query Workbench has an "Explain" button

-- 3. Via the MCP server
--    explain_sql_plus_plus_query — runs EXPLAIN and parses common findings (PrimaryScan,
--    IntersectScan, missing covering index, etc.) into a structured report
```

Add the `?profile=timings` query option (or `profile: "timings"` in the SDK) to a real query — that gives you per-operator timings on the actual run, not just the plan.

## Plan structure

The plan is a JSON tree. The root is the entry point; children are evaluated in order. The most common operators:

| Operator | What it does | Red-flag signs |
|---|---|---|
| `Sequence` | Run children in order | Structural — not a red flag |
| `Parallel` | Run child in parallel across cores | Structural — not a red flag |
| `PrimaryScan3` | Scan the primary index (full keyspace) | **BAD in production.** Equivalent to a full table scan. |
| `IndexScan3` | Scan a secondary GSI index | Good — but check whether it's the *right* index |
| `IntersectScan` | Run multiple IndexScans, intersect results | Usually bad — see "IntersectScan" below |
| `UnionScan` | Run multiple IndexScans, union results | Sometimes necessary for `OR` predicates |
| `Fetch` | Fetch full documents from the Data service | Present = not covered. Absent = covered (great). |
| `Filter` | Apply WHERE predicates that the index couldn't push down | High filter count means the index isn't selective enough |
| `InitialProject` | Select the projection columns | Structural |
| `Order` | Sort the rows | If sorting on a non-indexed expression, it's an in-memory sort |
| `Limit` / `Offset` | Apply LIMIT / OFFSET | Note: deep OFFSET still scans the prefix; see `pagination.md` |
| `NestedLoopJoin` / `HashJoin` | Join two keyspaces | Choice depends on CBO in 7.6+ |
| `UnnestScan` | Unnest an array, indexed by array index | Required for `UNNEST` with array indexes |

## Three key questions when reading a plan

### 1. What's the access method?

Find the first scan operator under the root. It should be `IndexScan3` (a real secondary index). If it's `PrimaryScan3`, you're scanning the entire keyspace — almost always a bug.

```json
{
  "#operator": "PrimaryScan3",         // ❌ red flag
  "index": "def_inventory_hotel_primary"
}
```
vs
```json
{
  "#operator": "IndexScan3",           // ✓ secondary index
  "index": "idx_hotel_state",
  "covers": [                          // ✓ also covered
    "cover ((`hotel`.`state`))",
    "cover ((`hotel`.`name`))",
    "cover ((meta(`hotel`).`id`))"
  ]
}
```

### 2. Is there a Fetch?

If the plan has a `Fetch` operator after the scan, the query is **not covered**. That's a round-trip from the Query service to the Data service for every matching document. For low-cardinality results (a handful of rows) this is fine. For high-cardinality results (thousands of rows), it's catastrophic for throughput.

To eliminate the Fetch, make the index cover the query. See `index-design.md` for the recipe.

### 3. Are SPANS being pushed down?

The `spans` field on an `IndexScan3` shows the range the indexer will scan. A tight span (a single equality, or a small range) is good. A wide-open span means the index lookup isn't actually doing selective work.

```json
"spans": [
  {
    "exact": true,
    "range": [
      {"low": "\"CA\"", "high": "\"CA\"", "inclusion": 3}    // ✓ exact equality
    ]
  }
]
```

If a span looks like `low: null, high: null` you're effectively doing a full index scan — almost as bad as a primary scan.

## IntersectScan — usually bad, sometimes inevitable

When two or more indexes qualify for a query (e.g., the query filters on fields covered by two different indexes), the Query service runs them in parallel and intersects the result IDs. This is `IntersectScan`.

It's usually bad because:
- The Query service runs every qualifying index — wasteful if one is selective and another isn't
- It often signals a missing single composite index that would do all the work

Fix:
1. Identify the most selective predicate
2. Create a single composite index leading with that field, including the other filter fields
3. Use `USE INDEX (...)` to force it if the rule-based optimizer keeps preferring the intersect

## Reading per-operator timings (profile output)

When you run a query with `profile: 'timings'`, each operator gets three timing fields:

| Field | Meaning |
|---|---|
| `kernTime` | Time the operator was scheduled but waiting for CPU. High kernTime = downstream pressure or query server CPU contention. |
| `servTime` | Time spent waiting on a downstream service (Indexer or Data service). High servTime on a Fetch or IndexScan = indexer / KV is the bottleneck. |
| `execTime` | Actual CPU time for the operator's own work. High execTime = the operator itself is doing too much (often a Filter applying too many predicates). |

Where to look first:
- If one Fetch operator dominates → query isn't covered, or the result set is too large
- If servTime on a scan dominates → the indexer is saturated (or the span is too wide)
- If a Filter has high execTime AND high `items_in` → the index isn't selective enough; predicates are being applied post-scan instead of pushed down

## A worked example

Query:
```sql
SELECT name, country
FROM `travel-sample`.inventory.hotel
WHERE state = 'CA' AND name LIKE 'Hilton%';
```

Bad plan (no index):
```
Sequence
├── PrimaryScan3 (def_inventory_hotel_primary)   ❌ full keyspace scan
├── Fetch                                         ❌ fetch every doc
├── Filter (state = 'CA' AND name LIKE 'Hilton%') ❌ filter all 917 hotels
└── InitialProject (name, country)
```

Better plan (single-field index):
```
Sequence
├── IndexScan3 (idx_state, spans=[state='CA'])    ✓ index scan
├── Fetch                                         ⚠ still fetching
├── Filter (name LIKE 'Hilton%')                  ⚠ post-scan filter
└── InitialProject (name, country)
```

Best plan (composite covering index):
```
Sequence
└── IndexScan3 (idx_state_name_country,           ✓ index scan
                spans=[state='CA', name LIKE 'Hilton%'],
                covers=[state, name, country, meta().id])
                                                  ✓ covered — no Fetch
   └── InitialProject (name, country)
```

The composite covering index:
```sql
CREATE INDEX idx_state_name_country
ON `travel-sample`.inventory.hotel(state, name, country);
```

## What to do next

- Bad scan or unexpected index → see `query-patterns.md` for fixes
- Want to design the right index → see `index-design.md`
- Need to wire this into a diagnostic workflow → see `diagnostic-workflow.md`
- Query is a join → see `joins-and-cbo.md`
