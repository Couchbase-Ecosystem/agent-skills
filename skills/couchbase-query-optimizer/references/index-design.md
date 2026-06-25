# Index design

Choosing the right index type is most of the tuning work. Once the right index exists, the query plan usually fixes itself.

## The index types

| Type | When to use | Syntax |
|---|---|---|
| **Secondary** | Default. Equality / range predicate on one or more fields. | `CREATE INDEX idx ON keyspace(field1, field2);` |
| **Covering** | Hot read query. Avoid the Fetch round-trip. | Same as secondary, but include every SELECT and WHERE field. |
| **Partial** | Only a fraction of docs are queried. | `CREATE INDEX idx ON keyspace(field) WHERE type = 'X';` |
| **Array** | Predicates against array elements (`ANY`, `UNNEST`). | `CREATE INDEX idx ON keyspace(DISTINCT ARRAY v.field FOR v IN arr END);` |
| **Composite** | Multiple equality/range predicates. | `CREATE INDEX idx ON keyspace(f1, f2, f3);` order matters. |
| **Functional** | Predicate on a computed expression. | `CREATE INDEX idx ON keyspace(LOWER(name));` |
| **Primary** | Almost never in production. | `CREATE PRIMARY INDEX ON keyspace;` |
| **Vector** (8.x) | Vector similarity search. | `CREATE VECTOR INDEX idx ON keyspace(embedding VECTOR);` |
| **FTS** | Full-text search (separate service). | Created via FTS UI / REST, not SQL++. |

## Covering indexes — the highest-leverage tool

A covering index contains every field the query touches. The Query service can answer the query from the index alone, no Fetch.

The recipe:
1. List every field in the SELECT projection
2. List every field in the WHERE clause
3. List every field used in ORDER BY / GROUP BY
4. Create one composite index containing all of them, leading with the most-selective WHERE field

Example. Query:
```sql
SELECT name, country
FROM `travel-sample`.inventory.hotel
WHERE state = 'CA' AND city = 'Berkeley';
```

Covering index:
```sql
CREATE INDEX idx_state_city_cover
ON `travel-sample`.inventory.hotel(state, city, name, country);
```

After EXPLAIN, the IndexScan3 operator will show a `covers` field listing every column, and there will be NO `Fetch` operator. That's the proof.

The trade-off: covering indexes are larger and take longer to build. For hot read queries this is worth it. For rarely-run queries, don't bother — a small non-covering index is cheaper.

## Partial indexes — for low-cardinality leading fields

The trap: indexing `docType` (or any low-cardinality field) as the leading key is bad. Every document with that type lands in the index, the rule-based optimizer might still pick it, and you get an IntersectScan or a wide scan.

The fix: use the low-cardinality field as a partial-index predicate, NOT as an index key.

```sql
-- ❌ BAD — docType as leading key
CREATE INDEX idx_dtype ON keyspace(docType);

-- ✓ GOOD — docType gates the index; status is the real key
CREATE INDEX idx_user_status
ON keyspace(status)
WHERE docType = 'user';
```

The query has to include the same WHERE clause for the partial index to qualify:
```sql
SELECT * FROM keyspace
WHERE docType = 'user' AND status = 'active';
```

## Array indexes — pattern matching is strict

Array indexing has rules that bite hard if you don't follow them.

### Rule 1: Use DISTINCT ARRAY, not ALL ARRAY

```sql
CREATE INDEX idx_schedule_days
ON route(DISTINCT ARRAY v.day FOR v IN schedule END);
```

### Rule 2: The query must use `ANY` or `ANY AND EVERY`

These can use the array index:
```sql
SELECT * FROM route
WHERE ANY v IN schedule SATISFIES v.day = 2 END;

SELECT * FROM route
WHERE ANY AND EVERY v IN schedule SATISFIES v.day <= 5 END;
```

These **cannot** use the array index:
```sql
-- ❌ EVERY alone has no index support
SELECT * FROM route
WHERE EVERY v IN schedule SATISFIES v.day <= 5 END;

-- ❌ Direct array element access doesn't trigger the array index
SELECT * FROM route WHERE schedule[0].day = 2;
```

### Rule 3: UNNEST binding variable must match the CREATE INDEX binding

```sql
-- CREATE INDEX uses binding variable 'v'
CREATE INDEX idx_unnest_day
ON route(DISTINCT ARRAY v.day FOR v IN schedule END);

-- ✓ Query must use the same name 'v'
SELECT r.id FROM route r UNNEST r.schedule v WHERE v.day = 2;

-- ❌ Different binding name — index won't be used
SELECT r.id FROM route r UNNEST r.schedule s WHERE s.day = 2;
```

### Rule 4: Composite array indexes mix array keys with scalar keys

```sql
CREATE INDEX idx_country_schedule
ON route(
  country,
  DISTINCT ARRAY v.day FOR v IN schedule END
);
```

Now `WHERE country = 'US' AND ANY v IN schedule SATISFIES v.day = 2 END` can use the composite array index.

### Rule 5 (7.1+): INCLUDE MISSING for the leading key

If the array field can be absent from some documents and you still want those docs indexed:
```sql
CREATE INDEX idx_sched_missing
ON route(DISTINCT ARRAY v.flight FOR v IN schedule END INCLUDE MISSING);
```

## Composite indexes — order matters

The leading key must appear in the WHERE clause. The optimizer uses keys left-to-right, stopping at the first one not present in the predicate.

```sql
CREATE INDEX idx_abc ON keyspace(a, b, c);

WHERE a = 1                       -- ✓ uses idx_abc, key 'a'
WHERE a = 1 AND b = 2             -- ✓ uses idx_abc, keys 'a', 'b'
WHERE a = 1 AND c = 3             -- ⚠ uses idx_abc only for 'a' — 'c' applied via Filter
WHERE b = 2 AND c = 3             -- ❌ idx_abc NOT selected — no leading key
```

The fix for the last case is to create a separate index leading with `b`, or restructure the query so `a` participates.

## Functional indexes — for derived expressions

If you query on a transformed value, the same transformation must be in the index:

```sql
-- Query
SELECT * FROM user WHERE LOWER(email) = 'user@example.com';

-- Right index — matches the expression
CREATE INDEX idx_email_lower ON user(LOWER(email));

-- Wrong index — won't be used by the query above
CREATE INDEX idx_email ON user(email);
```

Watch out for the SDK or app inserting `meta().id` derived values — they need functional indexes too.

## Force the optimizer's hand with USE INDEX

When the rule-based optimizer keeps picking the wrong index, force the right one:

```sql
SELECT *
FROM `travel-sample`.inventory.hotel USE INDEX (idx_state_city_cover)
WHERE state = 'CA' AND city = 'Berkeley';
```

Don't use `USE INDEX` as a permanent fix — it's brittle (the index name is hardcoded). Use it to confirm the right index would help, then figure out why the optimizer didn't pick it (usually: a low-cardinality leading key on a competing index, or the query reaches the leading key via a non-sargable predicate).

## Vector indexes (8.x)

Couchbase 8.0 added native vector indexing for similarity search. Two flavors:

```sql
-- Composite vector index — for filtered + vector search
CREATE VECTOR INDEX idx_embed_filtered
ON product(category, embedding VECTOR)
WITH {"dimension": 1536, "similarity": "cosine"};

-- Hyperscale vector index — for large-scale vector-only search
CREATE VECTOR INDEX idx_embed_hyperscale
ON product(embedding VECTOR)
USING HYPERSCALE
WITH {"dimension": 1536, "similarity": "cosine"};
```

Query with the `VECTOR_DISTANCE` function:
```sql
SELECT meta().id,
       VECTOR_DISTANCE(embedding, $query_vec, "cosine") AS dist
FROM product
WHERE category = 'electronics'
ORDER BY dist
LIMIT 10;
```

The MCP server's `admin_vector_index_create_hyperscale` and `admin_vector_index_create_composite` tools wrap the DDL (one tool per index type — they have different option sets). See `diagnostic-workflow.md` for using them with the index advisor.

## Index Advisor — let the database recommend

Couchbase has a built-in `ADVISE` statement that recommends indexes for a query:

```sql
ADVISE SELECT name FROM `travel-sample`.inventory.hotel WHERE state = 'CA' AND city = 'Berkeley';
```

The output includes:
- `recommended_indexes` — what to create
- `current_indexes` — what already exists that could be used
- `recommended_covering_indexes` — if a covering index would help
- `recommended_partial_indexes` — if a partial index would help (often when the query has a low-cardinality predicate)

Naming convention: ADVISE names recommended indexes with an `adv-` prefix. You can rename when creating.

The MCP server's `get_index_advisor_recommendations` tool wraps this.

## Sizing rule of thumb

- A typical secondary index uses ~50-100 bytes per indexed document (depends on key width)
- A covering index multiplies by the projection width (a covering index with 5 fields is 5x bigger than the same single-field index)
- Plan for 2-3x the index memory of the indexed data for healthy operation
- The Indexer service has its own RAM quota — bigger indexes need bigger quotas

If `get_queries_not_using_covering_index` or `list_indexes` (with `last_scan_time` check) flags indexes that aren't being used, drop them. Unused indexes still cost memory and write throughput.

## What to do next

- Now go read the EXPLAIN plan → `explain-plan.md`
- Fix the query that triggered the index design → `query-patterns.md`
- Wire this into a workflow → `diagnostic-workflow.md`
