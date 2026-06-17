# Core GSI indexing principles

## Primary vs. secondary indexes

The **primary index** indexes every document key — a `PrimaryScan3` means the query has no usable secondary index and scans the whole keyspace. Fine for ad-hoc dev, **bad in production**. Build targeted **GSIs** on the fields your queries filter and sort on.

## ESR key order (Equality → Sort → Range)

For a compound GSI, order the keys to match the query's access pattern:
1. **Equality** predicates first (`=`, `IN` with few values).
2. **Sort** fields next (the `ORDER BY` keys).
3. **Range** predicates last (`>`, `<`, `BETWEEN`, large `IN`, `!=`).

The **leading index key must appear in the query's `WHERE` (equality) or `ORDER BY`**, or the index can't be used. Exception: if the equality predicate is not selective but a range predicate is, leading with the range key can win — let selectivity guide ordering.

Example — for `WHERE country = "France" ORDER BY airportname`:
```sql
CREATE INDEX idx_country_name ON `travel-sample`.inventory.airport(country, airportname);
```

## Sort-direction matching

An index records a direction per key. `(country, airportname)` (both ascending) serves `ORDER BY country, airportname` and its full reverse, but **not mixed directions**. For `ORDER BY country ASC, airportname DESC`, build `(country, airportname DESC)` to match exactly.

## Covering indexes (eliminate `Fetch`)

A query is **covered** when every field it references — in `WHERE`, `SELECT`, and `ORDER BY` — is present in the index keys, so the engine answers it from the index alone and the plan has **no `Fetch`** operator. Add the projected fields to the index keys to make a hot read path covered:
```sql
-- SELECT city FROM …airport WHERE country = "France"
CREATE INDEX idx_country_city ON `travel-sample`.inventory.airport(country, city);
```
Balance this against write cost — wider indexes cost more to maintain.

## Array indexing

To index fields inside an array (for `UNNEST` or `ANY … SATISFIES` predicates), use an array index:
```sql
CREATE INDEX idx_sched_day ON `travel-sample`.inventory.route(DISTINCT ARRAY s.day FOR s IN schedule END);
```

## Selectivity & statistics

- Lead with the **most selective** equality predicate so the index scan returns as few items as possible.
- Couchbase's cost-based optimizer relies on **statistics**. After bulk loads or big data shifts, run `UPDATE STATISTICS` so the planner estimates cardinality correctly and chooses the right index instead of falling back to a scan.

## `INCLUDE MISSING`

By default a GSI omits documents missing the leading key. Use `INCLUDE MISSING` (Server 7.6+) on the leading key when you need those documents indexed (e.g., `ORDER BY` that must include rows where the field is absent).
