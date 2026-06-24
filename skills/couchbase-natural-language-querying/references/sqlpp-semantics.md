# SQL++ evaluation semantics

How SQL++ evaluates values — the rules behind "why did my query return nothing / odd ordering." Read this when a query is syntactically fine but returns surprising results. For syntax/shapes see [`sqlpp-patterns.md`](sqlpp-patterns.md); for functions see [`sqlpp-functions.md`](sqlpp-functions.md).

## Contents
- [NULL vs MISSING](#null-vs-missing)
- [Four-valued logic (AND/OR/NOT)](#four-valued-logic)
- [Types & collation order](#types--collation-order)
- [ORDER BY: NULL/MISSING placement](#order-by-placement)
- [Identifiers & reserved words](#identifiers--reserved-words)
- [Literals](#literals)

## NULL vs MISSING

SQL++ has **two** "empty" values (SQL has only NULL):
- **`NULL`** — the field exists, value is explicitly null.
- **`MISSING`** — the field is **absent** from the document. (Schema-less: a field can exist in one doc and be MISSING in another.)

A **wrong/nonexistent field name yields `MISSING`** — no error, just empty/odd results. Always validate field names against `INFER` (sample-based, so absence isn't proof; sample more docs or fetch a known key if a field you expect is missing).

In results: MISSING is **omitted from objects** entirely, and **converted to `null` inside arrays**.

**Existence tests:**

| Test | TRUE when field is… |
|---|---|
| `f IS NULL` | NULL only |
| `f IS NOT NULL` | valued **or MISSING** ⚠️ |
| `f IS MISSING` | MISSING only |
| `f IS NOT MISSING` | valued **or NULL** |
| `f IS VALUED` | has a real value (not NULL, not MISSING) |
| `f IS NOT VALUED` | NULL or MISSING |

⚠️ **Trap:** `IS NOT NULL` does **not** exclude MISSING, and `IS NOT MISSING` does **not** exclude NULL. To require a real value, use **`IS VALUED`**.

**Propagation** (comparisons `= < >` …, arithmetic `+ - * /`, `||`):
- any operand `MISSING` → result `MISSING`
- else any operand `NULL` (or wrong type) → result `NULL`

So `WHERE missing_field = "x"` is `MISSING` (row excluded), and `WHERE null_field = "x"` is `NULL` (row excluded) — neither errors. To match across NULLs use `IS [NOT] DISTINCT FROM` (`NULL IS NOT DISTINCT FROM NULL` → TRUE).

**Aggregates** ignore both NULL and MISSING, except `COUNT(*)` counts every row. `COUNT(expr)` counts rows where `expr` is valued.

## Four-valued logic

A boolean condition can be TRUE / FALSE / NULL / MISSING. In `WHERE`/`HAVING`/`WHEN`, only **TRUE** keeps a row (NULL and MISSING are treated as not-true). Note the asymmetry:

- **`AND`** → `FALSE` if any operand FALSE; else `MISSING` if any MISSING; else `NULL` if any NULL; else TRUE. *(MISSING dominates NULL.)*
- **`OR`** → `TRUE` if any operand TRUE; else `NULL` if any NULL; else `MISSING` if any MISSING; else FALSE. *(NULL dominates MISSING.)*
- **`NOT`** → `NOT NULL = NULL`, `NOT MISSING = MISSING`.

## Types & collation order

JSON types only: MISSING, NULL, boolean, number, string, array, object, binary. **No native date type** — dates are stored as strings or epoch **milliseconds** (see [date functions](sqlpp-functions.md#datetime)).

Default ascending **collation** (sort order) across types:
```
MISSING < NULL < FALSE < TRUE < number < string < array < object < binary
```
Consequences:
- Comparing different types never errors — it follows this order.
- **String comparison is byte-wise (UTF-8) and case-sensitive**: `"Z" < "a"` (uppercase before lowercase), and `"10" < "9"` (string compare), whereas numeric `10 > 9`. Cast or `LOWER()` when needed.
- Arrays compare element-by-element; objects compare by length then key/value pairs.

## ORDER BY placement

By the collation above, `MISSING`/`NULL` sort **first** on `ASC` and **last** on `DESC`. Override per key with `ORDER BY f ASC NULLS LAST` / `NULLS FIRST`.

## Identifiers & reserved words

- Unescaped identifier: `[A-Za-z_][0-9A-Za-z_$]*`, **case-sensitive**.
- Backtick-quote anything else — reserved words, spaces, hyphens: `` `order` ``, `` `first-name` ``. A literal backtick is `` `` `` (doubled).
- The reserved-word list is large (~150 words: `ANY`, `FIRST`, `ORDER`, `TYPE`, `WINDOW`, …). Don't memorize it; if a field/collection name collides with SQL++ syntax, backtick it. Full list: <https://docs.couchbase.com/server/current/n1ql/n1ql-language-reference/reservedwords.html>.

## Literals

- Strings: single **or** double quotes (`'SFO'`, `"France"`) — unlike JSON, both are allowed.
- Numbers: signed decimal with optional fraction/E-notation; no leading zeros on multi-digit integers.
- `TRUE` / `FALSE` / `NULL` / `MISSING` — case-insensitive keywords (`MISSING` is SQL++-specific).
- Arrays `[1, 2, 3]` and objects `{"a": 1}` are first-class literal values.
