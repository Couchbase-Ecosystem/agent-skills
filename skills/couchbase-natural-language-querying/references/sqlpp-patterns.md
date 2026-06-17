# SQL++ patterns

Reference for generating read-only SQL++. Examples use the `travel-sample` collections `airport`, `airline`, `route`, `hotel` (bucket `travel-sample`, scope `inventory`).

When you need a function or aren't sure one exists, **look it up** in the official reference rather than relying on recall — SQL++ function names and behavior differ from other dialects:
- Functions (by category): <https://docs.couchbase.com/server/current/n1ql/n1ql-language-reference/functions.html>
- Reserved words (must be backtick-escaped as identifiers): <https://docs.couchbase.com/server/current/n1ql/n1ql-language-reference/reservedwords.html>

## Keyspaces & identifiers

- **Don't qualify the keyspace in the query.** `bucket_name` and `scope_name` are passed as **arguments** to the MCP query tools, which set the scope context automatically — so `FROM` takes a **bare collection name** (`FROM route`), never `` `bucket`.`scope`.`collection` ``. The default scope is passed as `scope_name="_default"`.
- Backtick-quote a collection name only if it is a reserved word or contains special characters.
- The document key is `META().id`. Fetch by key directly with `USE KEYS`.

## Literals & operators

- **Literals:** strings in double or single quotes (`"France"`, `'SFO'`); numbers (`5`, `3.14`); `TRUE`/`FALSE`; `NULL`; `MISSING` (Couchbase-specific — see below). Arrays `[1, 2, 3]` and objects `{"a": 1}` are first-class values.
- **Comparison:** `=`, `!=` (or `<>`), `<`, `<=`, `>`, `>=`, `BETWEEN x AND y`, `IN [...]`, `IS NULL` / `IS NOT NULL`, `IS MISSING` / `IS NOT MISSING`, `LIKE 'foo%'`.
- **Logical:** `AND`, `OR`, `NOT`.
- **Arithmetic:** `+ - * / %`. **String concatenation:** `||` (e.g. `city || ", " || country`).
- **Conditional:** `CASE WHEN … THEN … ELSE … END`.

## Query shapes

- **Filter** — `SELECT … FROM <collection> WHERE <predicate>`. Project only the fields asked for (avoid `SELECT *`); filter as early as possible in `WHERE`; `ORDER BY … [ASC|DESC]`, `LIMIT`, `OFFSET`.
- **Aggregate** — `GROUP BY` with `COUNT/SUM/AVG/MIN/MAX`; filter pre-group in `WHERE`, post-group in `HAVING`.
  ```sql
  SELECT airline, COUNT(*) AS routes
  FROM route
  GROUP BY airline
  ORDER BY routes DESC
  LIMIT 5;
  ```
- **Join** — key-based `JOIN … ON KEYS` (follow a document-key reference) or ANSI `JOIN … ON <predicate>`.
- **Unnest arrays** — `UNNEST` (see Arrays).

## Functions

Couchbase groups functions into categories — Aggregate, Array, String, Date, Number, Conditional, Type, Object, Pattern-Matching, and more (see the Functions link above). Common ones:
- **Aggregate:** `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `ARRAY_AGG`.
- **String:** `LOWER`, `UPPER`, `SUBSTR`, `CONTAINS`, `SPLIT`, `TRIM`, `LENGTH`.
- **Array:** `ARRAY_LENGTH`, `ARRAY_CONTAINS`, `ARRAY_APPEND`, `ARRAY_DISTINCT`.
- **Number:** `ROUND`, `FLOOR`, `CEIL`, `ABS`, `RADIANS`, `SIN`, `COS`, `ACOS`, `SQRT`, `POWER`.
- **Type:** `TYPE`, `TONUMBER`, `TOSTRING`, `ISARRAY`, `ISNUMBER`.

**Don't assume a function exists — confirm it in the reference.** For example, "hotels within 5 miles of Heathrow" needs a geo-distance computation. The Query service has **no** built-in `GEO_DISTANCE`; either compute great-circle distance from `geo.lat`/`geo.lon` with the Number functions (`RADIANS`, `SIN`, `COS`, `ACOS`, `SQRT`) as a haversine, or use the Couchbase **Search Service** for native geospatial queries. Look up the right functions instead of inventing a name.

## Arrays

- **Flatten** an array to query its elements: `UNNEST`.
  ```sql
  SELECT r.sourceairport, s.day, s.flight
  FROM route AS r
  UNNEST r.schedule AS s
  WHERE r.sourceairport = "SFO";
  ```
- **Predicate over elements without flattening:** `ANY … SATISFIES` / `EVERY … SATISFIES`.
  ```sql
  WHERE ANY s IN schedule SATISFIES s.utc > "20:00" END
  ```
- Length: `ARRAY_LENGTH(arr)`. Element by position: `arr[0]`. Non-empty check: `ARRAY_LENGTH(arr) > 0`.

## Subqueries

- A subquery is a parenthesized `SELECT` usable in the `FROM`, `WHERE`, or projection. Use the `IN` form for membership and `EXISTS` for existence:
  ```sql
  SELECT a.name
  FROM airline AS a
  WHERE a.icao IN (SELECT RAW r.airline FROM route AS r WHERE r.sourceairport = "SFO");
  ```
- For per-document array computation, prefer array comprehensions (`ARRAY x FOR x IN … END`) or `FIRST x FOR x IN … END` over a correlated subquery when it reads more simply.

## NULL vs MISSING (important)

Couchbase distinguishes a field that is `NULL` from one that is absent (`MISSING`).
- Field-exists check: `field IS NOT MISSING`; absent: `field IS MISSING`.
- `field IS NULL` only matches an explicit null value.
- A wrong/nonexistent field name yields `MISSING` (no error, empty results) — validate names against `INFER` first. `INFER` samples documents, so a field can be real yet absent from the inferred shape; if a field you expect is missing, sample more docs before assuming it doesn't exist.

## Projection & efficiency

- Select only requested fields; avoid `SELECT *` unless the user wants the whole document. `SELECT RAW expr` returns unwrapped values (handy for single-field or scalar results).
- Filter as early as possible in `WHERE`.
- Use `LIMIT` for open-ended/exploratory questions.

## String matching (and what NOT to do here)

- `LIKE 'foo%'` for prefix matches; `LOWER()`/`UPPER()` for case-insensitive comparisons.
- Do **not** reach for `LIKE '%term%'` or `REGEXP_*` to satisfy a *search* request (relevance, fuzzy, semantic, "similar to") — that's a full-text/vector job for the Couchbase **Search Service** (FTS).

## Coming from MongoDB?

A quick map for users who think in MQL (otherwise prefer the SQL++-native sections above):

| MQL | SQL++ |
|-----|-------|
| `db.c.find({country: "France"})` | `SELECT * FROM c WHERE country = "France"` |
| projection `{name: 1, _id: 0}` | list the fields in the `SELECT` (no `SELECT *`) |
| `{a: {$gte: 1, $lte: 5}}` | `WHERE a BETWEEN 1 AND 5` |
| `{a: {$in: [...]}}` | `WHERE a IN [...]` |
| `.sort({a:-1}).limit(10)` | `ORDER BY a DESC LIMIT 10` |
| `.skip(n)` | `OFFSET n` (prefer keyset pagination for large offsets) |
| `$group` / `$sum`,`$avg`,… | `GROUP BY` / `SUM()`,`AVG()`,… |
| `$lookup` | `JOIN … ON KEYS` or ANSI `JOIN … ON <predicate>` |
| `$unwind` | `UNNEST` |
| `_id` / `$exists` | `META().id` / `IS [NOT] MISSING` |
