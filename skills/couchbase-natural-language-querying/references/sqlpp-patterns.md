# SQL++ query patterns

Read-only SQL++ syntax and query shapes — the parts that differ from ANSI SQL / other dialects. Examples use `travel-sample` collections (`airport`, `airline`, `route`, `hotel`; bucket `travel-sample`, scope `inventory`).

> Assume standard SQL works as you expect. This file lists only the **SQL++-specific** things. For evaluation rules (NULL/MISSING, type collation, identifiers) see [`sqlpp-semantics.md`](sqlpp-semantics.md); for exact function names/signatures see [`sqlpp-functions.md`](sqlpp-functions.md).

## Contents
- [Keyspaces & tool contract](#keyspaces--tool-contract)
- [Query shapes](#query-shapes)
- [SELECT specifics (RAW, `*`)](#select-specifics)
- [Joins](#joins)
- [UNNEST & NEST](#unnest--nest)
- [LET / LETTING / WITH](#let--letting--with)
- [Set operators](#set-operators)
- [Collection operators (array predicates & comprehensions)](#collection-operators)
- [Paths & navigation](#paths--navigation)
- [Subqueries](#subqueries)
- [String matching & search handoff](#string-matching--search-handoff)
- [Functions that don't exist](#functions-that-dont-exist)
- [Advanced (pointers only)](#advanced-pointers-only)
- [Coming from MongoDB](#coming-from-mongodb)
- [Common traps](#common-traps)

## Keyspaces & tool contract

- Pass `bucket_name` and `scope_name` as **tool arguments**; they set the scope context. The query uses a **bare collection name** — `FROM route`, never `` `travel-sample`.inventory.route ``. Default scope is `scope_name="_default"`.
- Backtick-quote a collection name only if it's a reserved word or has special characters.
- Document key = `META().id`. Fetch by key directly: `FROM hotel USE KEYS "hotel_123"` (point lookup, no scan).

## Query shapes

| Goal | Shape |
|---|---|
| Filter | `SELECT <fields> FROM c WHERE <pred> [ORDER BY … [DESC]] [LIMIT n] [OFFSET m]` |
| Aggregate | `GROUP BY …` + `COUNT/SUM/AVG/MIN/MAX`; pre-group filter in `WHERE`, post-group in `HAVING` |
| Join | `JOIN … ON KEYS` (key-based) or ANSI `JOIN … ON <pred>` |
| Flatten array | `UNNEST` |
| Per-element predicate | `ANY … SATISFIES … END` |

```sql
SELECT airline, COUNT(*) AS routes
FROM route GROUP BY airline ORDER BY routes DESC LIMIT 5;
```

Project only requested fields (avoid `SELECT *`); prefer keyset pagination over large `OFFSET`.

## SELECT specifics

- **`SELECT RAW expr`** — return unwrapped values, not `{alias: value}` objects. `SELECT RAW city FROM airport` → `["Paris", …]`. Use for single-column / scalar results and `IN`-subqueries. (`VALUE`/`ELEMENT` are synonyms for `RAW`.)
- **`SELECT *`** wraps each row under the keyspace/alias name: `SELECT * FROM hotel` → `[{"hotel": {…}}]`. To get the bare document, use **`SELECT hotel.*`** → `[{…}]`.
- Implicit projection aliases: a bare field keeps its name; a path uses its last component; an unnamed expression becomes `$1`, `$2`, ….

## Joins

Three forms — **don't mix forms in one `FROM`**:

| Form | Syntax | Use when |
|---|---|---|
| ANSI (preferred) | `JOIN r ON l.x = r.y` | join on arbitrary fields (RHS needs a secondary index for nested-loop) |
| Lookup | `JOIN r ON KEYS l.fkfield` | LHS field holds the RHS document key(s) |
| Index | `JOIN r ON KEY r.fkfield FOR l` | reverse of lookup; RHS field references LHS key (needs index on `r.fkfield`) |

```sql
-- lookup: route.airlineid holds the airline document key
SELECT r.sourceairport, a.name
FROM route AS r JOIN airline AS a ON KEYS r.airlineid;
```
Note `ON KEYS` (plural, value→key) vs `ON KEY … FOR …` (singular, index join). `LEFT [OUTER]` / `RIGHT [OUTER]` supported; default `INNER`.

## UNNEST & NEST

- **`UNNEST`** — flatten an array into one row per element (cross-product with parent). `INNER` (default) drops docs whose array is empty/missing; `LEFT [OUTER]` keeps them.
  ```sql
  SELECT r.sourceairport, s.day, s.flight
  FROM route AS r UNNEST r.schedule AS s
  WHERE r.sourceairport = "SFO";
  ```
- **`NEST`** — inverse of UNNEST: collect matching RHS docs into an array field on each LHS row (`ON KEYS` / `ON KEY … FOR` / ANSI `ON`). Rarely needed for NL queries.

## LET / LETTING / WITH

- **`LET v = expr`** — per-document named expression (after `FROM`, before `WHERE`); later `LET` vars can reference earlier ones.
- **`LETTING v = expr`** — like `LET` but **after `GROUP BY`**, may reference aggregates (post-group).
- **`WITH cte AS (…)`** — CTE evaluated **once per query** (not per row); chainable. `WITH RECURSIVE` exists for hierarchies (see [Advanced](#advanced-pointers-only)).

## Set operators

`UNION` / `INTERSECT` / `EXCEPT` return **DISTINCT** rows. Add `ALL` (`UNION ALL`, …) to keep duplicates (cheaper).

## Collection operators

Operate over array elements without (or before) `UNNEST`.

**Predicates** — return a boolean; note the empty-array results:

| Operator | True when | Empty array |
|---|---|---|
| `ANY v IN arr SATISFIES <cond> END` (`SOME` = synonym) | some element matches | **FALSE** |
| `EVERY v IN arr SATISFIES <cond> END` | all elements match | **TRUE** |
| `ANY AND EVERY v IN arr SATISFIES <cond> END` | non-empty **and** all match | **FALSE** |

```sql
WHERE ANY s IN schedule SATISFIES s.utc > "20:00" END
```
Use `IN` to range the current level, `WITHIN` to recurse into nested arrays/objects. Optional position var: `ANY i:v IN arr SATISFIES … END` (`i` is the 0-based index).

**Comprehensions** — transform an array:

| Form | Returns |
|---|---|
| `ARRAY <expr> FOR v IN arr [WHEN <cond>] END` | new array (empty if none match) |
| `FIRST <expr> FOR v IN arr [WHEN <cond>] END` | first matching value, `MISSING` if none |
| `OBJECT <k>:<v> FOR x IN arr [WHEN <cond>] END` | object (`k` must be a unique string) |

```sql
SELECT ARRAY s.flight FOR s IN schedule WHEN s.day = 5 END AS friday_flights
FROM route WHERE airline = "KL";
```

**Membership / existence:** `x IN arr` (top level), `x WITHIN arr` (any depth), `EXISTS arr` (≥1 element; also used with subqueries).

## Paths & navigation

- Field: `obj.field` (case-sensitive). Backtick odd names: ``obj.`first-name` ``. Case-insensitive lookup: `obj.["Field"]i`.
- Array element: `arr[0]`; `arr[-1]` = last. Slice: `arr[1:3]` (indices 1–2), `arr[2:]`, `arr[:2]`.
- Length: `ARRAY_LENGTH(arr)`; non-empty: `ARRAY_LENGTH(arr) > 0` or `EXISTS arr`.

## Subqueries

A parenthesized `SELECT` usable in `FROM`/`WHERE`/projection; **always returns an array**. Use `SELECT RAW` so membership tests work cleanly:

```sql
SELECT a.name FROM airline AS a
WHERE a.iata IN (SELECT RAW r.airline FROM route AS r WHERE r.sourceairport = "SFO");
```
Correlated subquery: reference the outer alias via the `FROM` (e.g. `FROM outer.nested_array`), or `USE KEYS <outer_expr>` when joining another keyspace by key.

## String matching & search handoff

- `LIKE 'foo%'` (`%` = any run, `_` = one char); `||` concatenates (`city || ", " || country`). Case-insensitive: wrap both sides in `LOWER()`/`UPPER()`.
- **Do not** use `LIKE '%term%'` or `REGEXP_*` for a *search* request (relevance, fuzzy, "similar to", semantic) — that's the Couchbase **Search Service** (FTS), out of scope for this skill.

## Functions that don't exist

Don't invent names from other SQL dialects. Notably:
- No `NOW()`, `GETDATE()` → use `NOW_STR()` / `NOW_MILLIS()`. No `DATEDIFF()`/`DATEADD()`/`EXTRACT()` → `DATE_DIFF_STR`, `DATE_ADD_STR`, `DATE_PART_STR` (see [`sqlpp-functions.md`](sqlpp-functions.md#datetime)).
- **No `GEO_DISTANCE`** or built-in geo. For "within N miles of X", compute great-circle distance from `geo.lat`/`geo.lon` with a haversine using number functions (`RADIANS`, `SIN`, `COS`, `ACOS`, `SQRT`), or use the Search Service for native geospatial.
- When unsure a function exists, check [`sqlpp-functions.md`](sqlpp-functions.md) or the [official function reference](https://docs.couchbase.com/server/current/n1ql/n1ql-language-reference/functions.html) — don't guess.

## Advanced (pointers only)

Rare in NL querying — confirm syntax in the [official language reference](https://docs.couchbase.com/server/current/n1ql/n1ql-language-reference/index.html) before using:
- **Window functions** — `ROW_NUMBER()/RANK()/DENSE_RANK()/LAG()/LEAD()/FIRST_VALUE()…` require an `OVER (PARTITION BY … ORDER BY …)` clause. (See [`sqlpp-functions.md`](sqlpp-functions.md#window).)
- **`WITH RECURSIVE` cte AS (anchor `UNION [ALL]` recursive-arm)** — for hierarchy/graph traversal; has built-in depth/row limits.
- **Time series** — `_TIMESERIES(doc, opts)`, usually the RHS of `UNNEST`; reads the doc's `ts_data`/`ts_interval`/`ts_start`/`ts_end` fields and emits points with `_t` (epoch ms) plus `_v0`, `_v1`, ….

## Coming from MongoDB

Only the non-obvious mappings:

| MQL | SQL++ |
|---|---|
| `$lookup` | `JOIN … ON KEYS` (key-based) or ANSI `JOIN … ON <pred>` |
| `$unwind` | `UNNEST` |
| `$elemMatch` | `ANY v IN arr SATISFIES <cond> END` |
| `_id` | `META().id` |
| `{f: {$exists: true}}` | `f IS NOT MISSING` (see [semantics](sqlpp-semantics.md)) |
| projection `{name:1,_id:0}` | list fields in `SELECT` (no `SELECT *`) |

## Common traps

| Intent | Wrong | Right |
|---|---|---|
| Field is present | `f IS NOT NULL` (keeps MISSING out? no) | `f IS VALUED` / `f IS NOT MISSING` — see [semantics](sqlpp-semantics.md#null-vs-missing) |
| Any array element matches | `value IN arr_of_objects` | `ANY v IN arr SATISFIES v.k = value END` |
| Search nested array | `x IN obj` | `x WITHIN obj` |
| First match | `(ARRAY … END)[0]` | `FIRST … END` |
| Substring search | `s LIKE "sub"` | `s LIKE "%sub%"` |
| Unwrapped scalar list | `SELECT city …` | `SELECT RAW city …` |
| Bare doc, not wrapped | `SELECT * FROM hotel` | `SELECT hotel.* FROM hotel` |
| Wrong field name | silently returns `MISSING`, empty results (no error) — validate names via `INFER` first |
