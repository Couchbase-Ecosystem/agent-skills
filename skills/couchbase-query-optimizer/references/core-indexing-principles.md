# Core GSI indexing principles

How to choose keys for a GSI. For exact DDL see [`index-ddl.md`](index-ddl.md); for mistakes see
[`index-antipatterns.md`](index-antipatterns.md); for stats/CBO see [`cost-based-optimizer.md`](cost-based-optimizer.md).

## Contents
- [Primary vs. secondary indexes](#primary-vs-secondary-indexes)
- [Compound key order](#compound-key-order)
- [Sort-direction matching](#sort-direction-matching)
- [Covering indexes (eliminate `Fetch`)](#covering-indexes-eliminate-fetch)
- [Partial (filtered) indexes](#partial-filtered-indexes)
- [Array & functional indexes](#array--functional-indexes)
- [Selectivity & statistics](#selectivity--statistics)
- [`INCLUDE MISSING`](#include-missing)

## Primary vs. secondary indexes

The **primary index** indexes every document key — a `PrimaryScan3` means the query has no usable secondary index and scans the whole keyspace. Fine for ad-hoc dev, **bad in production**. Build targeted **GSIs** on the fields your queries filter and sort on.

## Compound key order

For a compound GSI, order the keys to match the query's access pattern — equality, then sort, then range:
1. **Equality** predicates first (`=`, `IN` with few values).
2. **Sort** fields next (the `ORDER BY` keys).
3. **Range** predicates last (`>`, `<`, `BETWEEN`, large `IN`, `!=`).

As a strong default, the **leading index key should appear in the query's `WHERE` (equality) or `ORDER BY`** — otherwise the planner usually won't use the index. It's not absolute: a **covering index can still be chosen for a full index scan** even when the leading key isn't in a predicate (the planner prefers it over a `PrimaryScan3`), and **`INCLUDE MISSING`** on the leading key (see below) deliberately changes this. Also, if the equality predicate is not selective but a range predicate is, leading with the range key can win — let selectivity guide ordering.

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

## Partial (filtered) indexes
Add a `WHERE` to index only the relevant subset — a smaller index scans faster. As a default, **every GSI
should be partial** (e.g. `WHERE type = "hotel"`). The filter must be a *superset* of the query's predicate
for the index to qualify, and an equality field already in the `WHERE` filter need not also be an index key.

## Array & functional indexes
Index inside an array (for `UNNEST` / `ANY … SATISFIES`) with an array index. The **binding variable and
expression in the query must match the index exactly**:
```sql
CREATE INDEX idx_sched_day ON `travel-sample`.inventory.route(DISTINCT ARRAY s.day FOR s IN schedule END);
-- matches: … WHERE ANY s IN schedule SATISFIES s.day = 2 END
```
`DISTINCT ARRAY` (dedups per document) is the usual choice over `ALL ARRAY`. A **functional index** indexes an
expression so a function-wrapped predicate stays sargable — `CREATE INDEX … ON ks(LOWER(city))` serves
`WHERE LOWER(city) = "paris"`. (Functional indexes can also turn a range into an equality — see
[`query-optimization.md`](query-optimization.md).)

## Selectivity & statistics

- Lead with the **most selective** equality predicate so the index scan returns as few items as possible.
- Couchbase's cost-based optimizer relies on **statistics**. After bulk loads or big data shifts, run `UPDATE STATISTICS` so the planner estimates cardinality correctly and chooses the right index instead of falling back to a scan.

## `INCLUDE MISSING`

By default a GSI omits documents missing the leading key. Use `INCLUDE MISSING` (Server 7.6+) on the leading key when you need those documents indexed (e.g., `ORDER BY` that must include rows where the field is absent).
