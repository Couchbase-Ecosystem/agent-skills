# SQL++ patterns (and MQL → SQL++ translation)

Reference for generating read-only SQL++. Examples use `travel-sample` keyspaces (`` `travel-sample`.inventory.{airport,airline,route,hotel} ``).

## Keyspaces & identifiers

- Fully-qualify and backtick-quote: `` `bucket`.`scope`.`collection` ``. The default scope and collection are both `_default` (so a bucket with no custom scopes is `` `bucket`._default._default `` or just `` `bucket` ``).
- Backtick-quote any identifier that is a reserved word or contains special characters.
- The document key is `META().id` (the analog of Mongo's `_id`). Fetch by key directly with `USE KEYS`.

## find → SELECT

| MQL | SQL++ |
|-----|-------|
| `db.c.find({country: "France"})` | `SELECT * FROM `travel-sample`.inventory.airport WHERE country = "France"` |
| projection `{name: 1, _id: 0}` | `SELECT name FROM …` (list the fields; no `SELECT *`) |
| `{a: {$gte: 1, $lte: 5}}` | `WHERE a BETWEEN 1 AND 5` (or `a >= 1 AND a <= 5`) |
| `{a: {$in: [...]}}` | `WHERE a IN [...]` |
| `{$or:[…]}` / `{$and:[…]}` | `WHERE … OR …` / `AND` |
| `.sort({a:-1}).limit(10)` | `ORDER BY a DESC LIMIT 10` |
| `.skip(n)` | `OFFSET n` — prefer **keyset pagination** (`WHERE a > :last ORDER BY a LIMIT n`) for large offsets |

## Aggregation → GROUP BY

| MQL stage | SQL++ |
|-----------|-------|
| `$match` | `WHERE` (pre-group) / `HAVING` (post-group) |
| `$group: {_id:"$airline", n:{$sum:1}}` | `SELECT airline, COUNT(*) AS n FROM … GROUP BY airline` |
| accumulators `$sum/$avg/$min/$max` | `SUM()/AVG()/MIN()/MAX()` |
| `$sort` then `$limit` | `ORDER BY n DESC LIMIT 5` |
| `$project` | the `SELECT` list |
| `$lookup` | `JOIN … ON KEYS` (key-based) or ANSI `JOIN … ON <predicate>` |
| `$unwind` | `UNNEST` |

Example (top airlines by route count):
```sql
SELECT airline, COUNT(*) AS routes
FROM `travel-sample`.inventory.route
GROUP BY airline
ORDER BY routes DESC
LIMIT 5;
```

## Arrays

- **Flatten** an array to query its elements: `UNNEST`.
  ```sql
  SELECT r.sourceairport, s.day, s.flight
  FROM `travel-sample`.inventory.route AS r
  UNNEST r.schedule AS s
  WHERE r.sourceairport = "SFO";
  ```
- **Predicate over elements without flattening:** `ANY … SATISFIES` / `EVERY … SATISFIES`.
  ```sql
  WHERE ANY s IN schedule SATISFIES s.utc > "20:00" END
  ```
- Length: `ARRAY_LENGTH(arr)`. Element by position: `arr[0]`. Non-empty check: `ARRAY_LENGTH(arr) > 0`.

## NULL vs MISSING (important)

Couchbase distinguishes a field that is `NULL` from one that is absent (`MISSING`).
- Field-exists check: `field IS NOT MISSING` (analog of `$exists: true`); absent: `field IS MISSING`.
- `field IS NULL` only matches an explicit null value.
- A wrong/nonexistent field name yields `MISSING` (no error, empty results) — validate names against `INFER` first.

## Projection & efficiency

- Select only requested fields; avoid `SELECT *` unless the user wants the whole document. `SELECT RAW expr` returns unwrapped values (handy for single-field or scalar results).
- Filter as early as possible in `WHERE`.
- Use `LIMIT` for open-ended/exploratory questions.

## String matching (and what NOT to do here)

- `LIKE 'foo%'` for prefix matches; `LOWER()`/`UPPER()` for case-insensitive comparisons.
- Do **not** reach for `LIKE '%term%'` or `REGEXP_*` to satisfy a *search* request (relevance, fuzzy, semantic, "similar to") — that's a full-text/vector job for the Couchbase **Search Service** (FTS).
