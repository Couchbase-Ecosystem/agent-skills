# SQL++ function catalog

SQL++-specific function names and signatures (the ones easy to misname or invent). **Standard functions behave as expected and are not listed**: `COUNT/SUM/AVG/MIN/MAX`, `UPPER/LOWER/TRIM/LTRIM/RTRIM`, `LENGTH`, `ABS/ROUND/CEIL/FLOOR/SIGN`, `SQRT/POWER/EXP`, trig (radians). If a function isn't here, check the [official reference](https://docs.couchbase.com/server/current/n1ql/n1ql-language-reference/functions.html) rather than guessing.

## Contents
- [Date / time](#datetime) ← largest, most error-prone
- [Array](#array)
- [Object](#object)
- [Conditional (NULL/MISSING & numeric)](#conditional)
- [Numeric extras](#numeric-extras)
- [Type](#type)
- [String (non-obvious)](#string)
- [Pattern matching (regex)](#pattern-matching)
- [Comparison & aggregate extras](#comparison--aggregate-extras)
- [Meta](#meta)
- [Window](#window)
- [Search / vector (out of scope)](#search--vector)

## Date/time

**No date type.** Dates are strings or epoch **milliseconds** (not seconds). `_STR` functions take/return strings; `_MILLIS` functions take/return integer ms. If the format arg is omitted, ISO-8601 is assumed.

| Function | Result |
|---|---|
| `NOW_STR([fmt])`, `NOW_MILLIS()`, `NOW_UTC([fmt])`, `NOW_TZ(tz[,fmt])`, `NOW_LOCAL([fmt])` | current time, **stable** across the whole query |
| `CLOCK_STR([fmt])`, `CLOCK_MILLIS()`, … | current time, **re-read per call** (don't use for consistent timestamps) |
| `MILLIS(str)` / `STR_TO_MILLIS(str[,fmt])` | date string → epoch ms |
| `MILLIS_TO_STR(ms[,fmt])`, `MILLIS_TO_UTC`, `MILLIS_TO_TZ(ms,tz[,fmt])`, `MILLIS_TO_ZONE_NAME` | epoch ms → string |
| `STR_TO_UTC(str)`, `STR_TO_TZ(str,tz)`, `STR_TO_ZONE_NAME(str,tz)` | shift a date string between zones |
| `DATE_ADD_STR(str,n,part)` / `DATE_ADD_MILLIS(ms,n,part)` | add `n` of `part` (negative to subtract) |
| `DATE_DIFF_STR(d1,d2,part)` / `DATE_DIFF_MILLIS(ms1,ms2,part)` | difference in `part` units |
| `DATE_PART_STR(str,part)` / `DATE_PART_MILLIS(ms,part[,tz])` | extract a component (the SQL++ `EXTRACT`) |
| `DATE_TRUNC_STR(str,part)` / `DATE_TRUNC_MILLIS(ms,part)` | truncate down to `part` |
| `DATE_FORMAT_STR(str,[in_fmt,]out_fmt)` | reformat a date string |
| `DATE_RANGE_STR(start,end,part[,n])` / `DATE_RANGE_MILLIS(…)` | array of dates stepping by `part` |
| `WEEKDAY_STR(str)` / `WEEKDAY_MILLIS(ms[,tz])` | weekday name ("Wednesday") |
| `DURATION_TO_STR(ns)` / `STR_TO_DURATION("2h30m")` | nanoseconds ↔ Go duration string |

**`part` names:** `millennium, century, decade, year, quarter, month, week, iso_week, iso_year, day, day_of_year (doy), day_of_week (dow), hour, minute, second, millisecond, timezone, timezone_hour, timezone_minute`.

**Format strings** — pick **one** convention per format (don't mix):
- ISO-8601 component codes: `YYYY-MM-DDThh:mm:ss.sTZD` (also `MM`, `DD`, `hh`, `HH12`/`HH24`, `mm`/`MI`, `ss`/`SS`, `MONTH`/`Mon`/`month`, `DAY`/`Dy`/`day`, `AM`/`PM`, `TZD`).
- Go reference date: `2006-01-02 15:04:05` (1=Jan-pos, 2=day, 15=24h-hour…), `Jan`/`January`, `Mon`/`Monday`, `-07:00`/`Z07:00`. ⚠️ `2006-02-01` is read as Go (02=day), not as ISO.
- Percent-style (Unix `date`): `%Y-%m-%d %H:%M:%S`.

## Array

| Function | Result |
|---|---|
| `ARRAY_LENGTH(a)` | element count |
| `ARRAY_CONTAINS(a, v)` | boolean membership (top level) |
| `ARRAY_POSITION(a, v)` | 0-based index, `-1` if absent |
| `ARRAY_DISTINCT(a)` | dedupe |
| `ARRAY_SORT(a)` / `ARRAY_REVERSE(a)` | sort / reverse |
| `ARRAY_AGG(expr)` | aggregate values into an array (keeps NULLs, drops MISSING) |
| `ARRAY_FLATTEN(a, depth)` | flatten nested arrays |
| `ARRAY_CONCAT`, `ARRAY_APPEND`, `ARRAY_PREPEND`, `ARRAY_PUT` | combine / add |
| `ARRAY_UNION`, `ARRAY_INTERSECT`, `ARRAY_EXCEPT`, `ARRAY_SYMDIFF` | set ops |
| `ARRAY_MIN/MAX/SUM/AVG/COUNT(a)` | reductions (`ARRAY_SUM`→0 if no numbers) |
| `ARRAY_RANGE(start, end[, step])` | generate numeric array |
| `ARRAY_STAR(a)` | array-of-objects → object-of-arrays |

(For mapping/filtering an array, the `ARRAY … FOR … END` comprehension in [`sqlpp-patterns.md`](sqlpp-patterns.md#collection-operators) is usually clearer than these.)

## Object

| Function | Result |
|---|---|
| `OBJECT_NAMES(o)` | array of keys |
| `OBJECT_VALUES(o)` | array of values |
| `OBJECT_PAIRS(o)` | array of `{name, val}` pairs |
| `OBJECT_LENGTH(o)` | key count |
| `OBJECT_ADD(o, k, v)` / `OBJECT_REMOVE(o, k)` / `OBJECT_PUT` | derive a modified object |
| `OBJECT_CONCAT(o1, o2, …)` | merge (later wins) |
| `OBJECT_FIELD(o, "a.b")` | access nested field by dotted string |

## Conditional

NULL/MISSING-aware (return the first qualifying argument):

| Function | Returns |
|---|---|
| `IFMISSING(a, b, …)` | first non-MISSING |
| `IFNULL(a, b, …)` | first non-NULL |
| `IFMISSINGORNULL(a, b, …)` / `COALESCE(…)` | first that is neither MISSING nor NULL |
| `NVL(a, b)` | `a` if valued, else `b` |
| `NVL2(a, b, c)` | `b` if `a` valued, else `c` |
| `MISSINGIF(a, b)` / `NULLIF(a, b)` | MISSING / NULL when `a = b`, else `a` |
| `DECODE(e, s1,r1, s2,r2, …[,default])` | CASE-style exact match |

Numeric (NaN/Infinity): `IFNAN`, `IFINF`, `IFNANORINF`, `NANIF`, `POSINFIF`, `NEGINFIF`.

## Numeric extras

`MOD(a,b)` (allows floats) vs `IMOD(a,b)` (integer); `TRUNCATE(n[,digits])`; `RANDOM([seed])` → [0,1); `CBRT(n)` cube root; `LN` (natural) vs `LOG` (base-10); constants `PI()`, `E()`, `INF()`, `NAN()`; `DEGREES()`/`RADIANS()`.

## Type

- `TYPE(v)` → `"missing"|"null"|"boolean"|"number"|"string"|"array"|"object"|"binary"`.
- Checks: `ISARRAY`, `ISNUMBER`, `ISSTRING`, `ISOBJECT`, `ISBOOLEAN`, `ISATOM`.
- Conversions: `TONUMBER(v[,strip])`, `TOSTRING`, `TOARRAY`, `TOBOOLEAN`, `TOOBJECT`, `TOATOM`.

## String

⚠️ Positions/offsets come in **0-based and 1-based** variants:

| Function | Result |
|---|---|
| `SUBSTR(s, pos[, len])` | **0-based** substring; `SUBSTR1(…)` is **1-based** |
| `POSITION(s, sub)` | **0-based** index, `-1` if absent; `POSITION1(…)` is 1-based (0 if absent) |
| `CONTAINS(s, sub)` | boolean substring test |
| `SPLIT(s[, sep])` | split to array (default: whitespace) |
| `REPLACE(s, find, repl[, n])` | replace up to `n` occurrences |
| `INITCAP(s)` / `TITLE(s)` | Title Case |
| `LPAD/RPAD(s, len[, pad])`, `REPEAT(s, n)`, `REVERSE(s)` | pad / repeat / reverse |
| `MASK(s[, opts])` | redact characters |
| `BASE64(v)` / `BASE64_ENCODE` / `BASE64_DECODE`, `ENCODE_JSON`/`DECODE_JSON` | encode/decode |
| `TOKENS(v, opts)` | tokenize into an array (indexing helper) |

(`MB_*` variants exist for multibyte-aware length/position/substr.)

## Pattern matching

`REGEXP_CONTAINS(s, p)` (substring), `REGEXP_LIKE(s, p)` (whole string), `REGEXP_MATCHES`, `REGEXP_POSITION`, `REGEXP_REPLACE(s, p, r[, n])`, `REGEXP_SPLIT`. ⚠️ **Go (RE2) regex syntax** — no lookahead/lookbehind/backreferences; escape backslashes in string literals (`"\\d+"`).

## Comparison & aggregate extras

- `GREATEST(…)` / `LEAST(…)` — max/min across args, ignoring NULL/MISSING (collation order).
- Aggregates beyond the basics: `ARRAY_AGG`, `COUNTN` (count numeric only), `MEDIAN`, `STDDEV`/`STDDEV_SAMP`/`STDDEV_POP`, `VARIANCE`/`VAR_SAMP`/`VAR_POP`.
- `COUNT(DISTINCT x)` and a per-aggregate `… FILTER (WHERE cond)` clause are supported.

## Meta

`META().id` (document key), `META().cas`, `META().expiration` (0 = none), `META().flags`, `META().xattrs.<attr>`; `UUID()` generates a new id.

## Window

Require an `OVER (PARTITION BY … ORDER BY … [frame])` clause: `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `PERCENT_RANK()`, `CUME_DIST()`, `NTILE(n)`, `LAG(e[,off[,def]])`, `LEAD(…)`, `FIRST_VALUE(e)`, `LAST_VALUE(e)`, `NTH_VALUE(e,n)`. Aggregates (`SUM`, `AVG`, …) also work with `OVER`. (Enterprise Edition.) Uncommon for NL queries.

## Search / vector

Out of scope for this skill — hand off to the Couchbase **Search Service**: `SEARCH(keyspace, query)`, `SEARCH_META()`, `SEARCH_SCORE()`, `CONTAINS_TOKEN(…)`, and vector funcs `APPROX_VECTOR_DISTANCE`/`VECTOR_DISTANCE`. Don't use these for read-only SELECT generation here.
