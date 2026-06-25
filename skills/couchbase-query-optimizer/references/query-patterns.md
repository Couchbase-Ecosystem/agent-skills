# Query patterns and anti-patterns

The most common reasons a Couchbase SQL++ query is slow, and what to do about each.

## 1. PrimaryScan / no usable index

Symptom: EXPLAIN shows `PrimaryScan3` or `PrimaryScan`. The query is scanning the entire keyspace.

Causes:
- No secondary index exists that matches the WHERE clause
- An index exists but the leading key isn't in WHERE
- A query field is wrapped in a function call that breaks index matching

Fix: see `index-design.md`. The general rule: build a secondary index whose **leading key matches a field that appears with an equality predicate in WHERE**.

In production, drop the primary index outright once you've confirmed no critical query depends on it. This forces queries to fail loudly instead of silently full-scanning.

```sql
-- Find queries hitting the primary index (or use the MCP tool)
SELECT statement, count(*) AS occurrences
FROM system:completed_requests
WHERE preparedText LIKE '%PrimaryScan%'
   OR statement LIKE '%/* PRIMARY */%'
GROUP BY statement
ORDER BY occurrences DESC;

-- The MCP tool:
-- get_queries_using_primary_index
```

## 2. IntersectScan when a single composite index would work

Symptom: EXPLAIN shows `IntersectScan` with two or more child IndexScans.

Cause: Two indexes both qualify for the query, and the optimizer can't tell which is more selective (it's rule-based, no cardinality knowledge), so it runs both and intersects.

Fix: build a single composite index leading with the most-selective predicate.

```sql
-- Before: two single-field indexes
CREATE INDEX idx_state ON hotel(state);
CREATE INDEX idx_city ON hotel(city);
-- Query → IntersectScan(idx_state, idx_city)

-- After: one composite index, most-selective key first
CREATE INDEX idx_city_state ON hotel(city, state);
-- (city is more selective — there are more cities than states)
-- Query → single IndexScan3
```

If the two indexes serve genuinely different queries, leave them. The intersect only happens when both happen to qualify for the same query.

## 3. Leading key not in WHERE / not sargable

Symptom: EXPLAIN doesn't pick the index you expect, even though it covers the right fields.

Cause: the leading key of the index is either missing from WHERE entirely, or wrapped in something that makes it non-sargable.

The non-sargable patterns:
| Pattern | Why bad | Fix |
|---|---|---|
| `WHERE field IS NULL` | Index doesn't store NULL by default | Use `INCLUDE MISSING` (7.1+) or restructure |
| `WHERE field IS MISSING` | Same | `INCLUDE MISSING` |
| `WHERE NOT (field = 'x')` | Negation doesn't push down well | Rewrite as `field != 'x'` or, better, broaden the index |
| `WHERE field != 'x'` | Range that excludes one value — sometimes works, often doesn't | Often need a USE INDEX hint |
| `WHERE LOWER(field) = 'x'` | Function on field breaks index match | Create a functional index on `LOWER(field)` |
| `WHERE field = $1 OR field2 = $2` | OR across fields — usually IntersectScan or UnionScan | Restructure as UNION ALL of two queries, each indexed |

Force selection with the IS NOT MISSING idiom:
```sql
-- If the optimizer won't pick idx_state because 'state' might be missing:
CREATE INDEX idx_state ON hotel(state);

-- Add IS NOT MISSING to make the leading key participate
SELECT * FROM hotel
WHERE state IS NOT MISSING AND state = 'CA';
```

## 4. Fetch dominates the runtime

Symptom: Plan shows a Fetch operator and the profile shows it taking most of the runtime.

Cause: the query isn't covered. Every matching document gets fetched from the Data service.

Fix:
- If the result set is small (< 100 rows) → leave it; one Fetch per row is fine
- If the result set is large → build a covering index that includes every SELECT field
- If you can't cover it (the projection is too wide) → restructure the query to return less, or paginate

Example. Query returns 50,000 rows; runtime 8 seconds; profile shows Fetch taking 7.5s:
```sql
-- Bad — 50,000 fetches
SELECT id, name, address, country
FROM hotel
WHERE state = 'CA';

-- Better — cover it
CREATE INDEX idx_state_cover ON hotel(state, name, address, country);
-- Now: IndexScan3 with covers=[...], no Fetch
```

## 5. Deep pagination (LIMIT/OFFSET at large offsets)

Symptom: `LIMIT 20 OFFSET 100000` is slow. EXPLAIN looks fine but the query takes seconds.

Cause: Couchbase's IndexScan honors LIMIT and OFFSET, but to reach OFFSET 100000 it still has to scan the 100,000 entries in the index — they're just discarded.

Fix: KeySet pagination. Use the last value from page N as the start of page N+1.

```sql
-- Bad — gets worse with depth
SELECT * FROM hotel
WHERE state = 'CA'
ORDER BY name
LIMIT 20 OFFSET 100000;

-- Better — pass the last seen 'name' from the previous page
SELECT * FROM hotel
WHERE state = 'CA' AND name > $last_seen_name
ORDER BY name
LIMIT 20;
```

Constant cost per page, regardless of depth. Trade-off: doesn't support random-access page numbers; only sequential next-page navigation. See `pagination.md` for the full pattern including composite cursors.

## 6. OR across different fields

Symptom: `WHERE a = $1 OR b = $2` is slow.

Cause: A single composite index can't satisfy an OR across different fields. The optimizer typically falls back to PrimaryScan or two separate scans.

Fix: rewrite as UNION ALL with separate, focused indexes:
```sql
-- Bad
SELECT * FROM doc WHERE a = 'foo' OR b = 'bar';

-- Better — two focused queries, each indexed
SELECT * FROM doc WHERE a = 'foo'
UNION ALL
SELECT * FROM doc WHERE b = 'bar' AND (a IS MISSING OR a != 'foo');
```

The `(a IS MISSING OR a != 'foo')` guard prevents duplicates if a doc satisfies both predicates.

## 7. SELECT *

Symptom: queries doing `SELECT *` show large Fetch operators and high network bytes.

Cause: pulls the whole document; can never be covered (the index would have to include every field).

Fix: project only the fields you actually need. Usually shrinks both Fetch time and network bytes by 3-10x.

```sql
-- ❌ Pulls the whole doc
SELECT * FROM hotel WHERE state = 'CA';

-- ✓ Project just what you need
SELECT name, country, city FROM hotel WHERE state = 'CA';
```

This is also a precondition for building a covering index — you need to know the exact projection.

## 8. Array predicate with EVERY (no array index)

Symptom: query against an array field doesn't use the array index.

Cause: `EVERY x IN arr SATISFIES ... END` alone is not array-indexable. Only `ANY` and `ANY AND EVERY` are.

Fix: use the right operator.

```sql
-- ❌ EVERY alone — won't use array index
WHERE EVERY v IN schedule SATISFIES v.delayed = false END

-- ✓ Use ANY AND EVERY — uses the array index
WHERE ANY AND EVERY v IN schedule SATISFIES v.delayed = false END
```

Note the semantic difference: `EVERY` evaluates to true on empty arrays, `ANY AND EVERY` requires at least one element. Usually `ANY AND EVERY` is what you want anyway.

## 9. UNNEST binding mismatch

Symptom: `UNNEST` query doesn't use the array index you built for it.

Cause: the binding variable name in the query doesn't match the binding variable in `CREATE INDEX`.

```sql
-- The index uses 'v'
CREATE INDEX idx_unnest_flight
ON route(DISTINCT ARRAY v.flight FOR v IN schedule END);

-- ❌ Query uses 's' — index NOT used
SELECT r.id FROM route r UNNEST r.schedule s WHERE s.flight LIKE 'UA%';

-- ✓ Query uses 'v' — index used
SELECT r.id FROM route r UNNEST r.schedule v WHERE v.flight LIKE 'UA%';
```

Fix is purely syntactic — rename the binding variable to match.

## 10. Repeated query without PREPARE

Symptom: A query runs thousands of times per second but each run includes parse + optimize overhead.

Fix: prepare it once, execute many times.

```sql
PREPARE find_hotel_by_state FROM
  SELECT name FROM `travel-sample`.inventory.hotel WHERE state = $state;

EXECUTE find_hotel_by_state USING ['CA'];
```

In an SDK:
```python
cluster.query("SELECT name FROM hotel WHERE state = $state",
              QueryOptions(adhoc=False, named_parameters={"state": "CA"}))
```
`adhoc=False` tells the SDK to prepare on first call and cache the prepared name.

Prepared statements also avoid the SQL-injection trap if you bind variables (which you should anyway).

## 11. SQL injection through string concatenation

Symptom (developer-side): queries built by string concat with user input.

Fix: always use named or positional parameters.

```python
# ❌ Injection — also can't be prepared
query = f"SELECT * FROM hotel WHERE city = \"{user_city}\""

# ✓ Parameterized — safe + prepareable
query = "SELECT * FROM hotel WHERE city = $city"
cluster.query(query, named_parameters={"city": user_city})
```

This isn't a "performance" issue strictly, but every preparable query is a covered query opportunity — the security and performance arguments overlap.

## 12. Wide IN lists

Symptom: `WHERE id IN [1000-element-list]` is slow or hits document-size limits.

Cause: large IN lists become large index spans; very large ones can exceed cluster limits.

Fix: for very large sets (>500 elements), use a temp keyspace or a join, or chunk the query:

```sql
-- Bad — 5000 IDs
WHERE id IN [...5000 elements...]

-- Better — chunk into batches of 100-500 and union the results
-- Or, load the IDs into a temp keyspace and JOIN
```

## 13. ORDER BY on a non-indexed expression

Symptom: An `Order` operator high in the runtime profile.

Cause: the sort is being done in memory by the Query service because the index can't supply ordered results.

Fix: make sure the ORDER BY fields are at the trailing position of the index in the same direction.

```sql
-- Query
SELECT name FROM hotel WHERE state = 'CA' ORDER BY name;

-- Index that supplies order
CREATE INDEX idx_state_name ON hotel(state, name);
--                                  ^^^^^ ^^^^
--                                  WHERE leading   ORDER trailing
```

The plan should show no separate Order operator — the IndexScan returns rows already sorted.

## 14. The "magic" anti-pattern: indexing the docType

Spotted often: `CREATE INDEX idx_type ON keyspace(docType)`.

Cause: someone added it thinking "we filter on docType everywhere, an index will help." It doesn't. docType has maybe 5-20 distinct values across millions of documents — extremely low cardinality.

Effects:
- Becomes a candidate for IntersectScan with other indexes
- Used as a fallback when no real index qualifies — causes unexpected EXPLAIN plans
- Wastes index memory and write throughput

Fix:
1. Drop `idx_type`
2. Convert every other index to a partial index gated on docType:
```sql
CREATE INDEX idx_user_email
ON keyspace(email)
WHERE docType = 'user';
```

Now `WHERE docType = 'user' AND email = 'x'` uses a tight, partial index. No IntersectScan.

## 15. Filter on a computed field that's expensive

Symptom: `WHERE complex_function(field) = 'x'` is slow.

Cause: the function runs once per document in the Fetch + Filter stages.

Fix:
- Store the computed value at write time as a separate field, index on the stored field
- Or build a functional index on `complex_function(field)` directly

## What to do next

- Designing the right index from scratch → `index-design.md`
- Reading the EXPLAIN output → `explain-plan.md`
- A specific pagination problem → `pagination.md`
- Joining two keyspaces → `joins-and-cbo.md`
- Step-by-step diagnostic loop → `diagnostic-workflow.md`
