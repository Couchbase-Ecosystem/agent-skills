# SQL++ User-Defined Functions (UDFs)

> Open this **only** when a question maps onto a *named or reusable operation*, or the user
> references a function by name. **By default, don't mention UDFs at all** — a plain query needs
> none of this. For built-in function names/signatures see [`sqlpp-functions.md`](sqlpp-functions.md).

A UDF is a function someone created on the cluster — *inline* (a SQL++ expression, possibly a
subquery) or *external* (JavaScript). You can **call** a UDF in read-only SQL++ exactly like a
built-in. You cannot **create** one here (DDL — see below); you can only present the statement.

## Contents
- [When UDFs are relevant (and when not)](#when-udfs-are-relevant-and-when-not)
- [Discover existing UDFs](#discover-existing-udfs)
- [Calling a UDF](#calling-a-udf)
- [Suggesting a new UDF (never run it)](#suggesting-a-new-udf-never-run-it)
- [Performance trap](#performance-trap)
- [Quick decision tree](#quick-decision-tree)

## When UDFs are relevant (and when not)

**Relevant** when the question reads like a *named operation* — a unit conversion ("in meters",
"to Fahrenheit"), a business rule ("loyalty tier", "is eligible", "risk score"), a repeated derived
value — or the user names a function ("use our `tier()` function"). **Not relevant** for a plain
filter, count, group-by, join, or unnest: write the SQL++ inline and don't bring UDFs up.

Detecting a UDF ≠ suggesting it. Even after discovery, use a UDF only if the question maps onto it
naturally; otherwise stay silent.

## Discover existing UDFs

There is no dedicated MCP tool. Run this once (read-only) via `run_sql_plus_plus_query`, then reuse
the result for the session:

```sqlpp
SELECT identity, definition FROM system:functions
```

Each row:

| Field | Shape |
|---|---|
| `identity` | `{name, namespace, type ("global"\|"scope"), bucket?, scope?}` |
| `definition` | `{#language ("inline"\|"javascript"), parameters[], expression?/text? (inline), library?/object? (external)}` |

> **Absence is authoritative.** Unlike `INFER` (sample-based), `system:functions` lists every UDF.
> Empty result ⇒ there is nothing to use — move on without mentioning UDFs. Most clusters
> (fresh, `travel-sample`) return empty.

## Calling a UDF

Call it like a built-in, in any expression — `SELECT to_meters(geo.alt) FROM airport`. A
subquery-returning UDF can be a `FROM` term: `FROM locations("eat") AS l`.

| Trap | Note |
|---|---|
| **Case sensitivity** | UDF names **are** case-sensitive (built-ins are not) — match the exact case from `system:functions`. |
| **Wrong arg count** | Supplying the wrong number of args → error `10104`. Variadic UDFs (`params: ["..."]`) take any count. |
| **Qualification** | Unqualified resolves against the current `bucket_name`/`scope_name`. Global (`type: "global"`) may need `default:name`; scoped is ``default:`bucket`.scope.fn``. |
| **Side effects** | A UDF with side effects can't be called in an expression (only `EXECUTE FUNCTION`) — out of scope under read-only. |

## Suggesting a new UDF (never run it)

> **Recommend, don't apply.** `CREATE FUNCTION` is DDL — the MCP server's read-only mode blocks it.
> **Present** the statement for the user to run themselves (Query Workbench / `cbq`, or after they
> enable writes); **never execute it.** It needs a *Manage Global/Scope Functions* role.

Suggest one **only** when a non-trivial expression is repeated across queries, or the user asks to
save/name a computation — never for a one-off question. Inline syntax:

```sqlpp
CREATE FUNCTION to_meters(feet) { feet * 0.3048 };          -- braces form
CREATE FUNCTION celsius(f) LANGUAGE INLINE AS (f - 32) * 5/9; -- LANGUAGE form
```

`CREATE OR REPLACE` redefines an existing UDF; `IF NOT EXISTS` is a no-op if it already exists.
(External/JavaScript UDFs are *callable* the same way, but authoring them is out of scope here.)

## Performance trap

> A UDF in `WHERE`/projection is **not indexable** → it can force a primary/collection scan. If a
> UDF-bearing query is slow, note it and hand off to **`couchbase-query-optimizer`** (same as Step 5).

## Quick decision tree

| Situation | Do |
|---|---|
| Plain filter / aggregate / join / unnest | Ignore UDFs entirely. |
| Question names a function or maps onto a named operation | Discover (`system:functions`); reuse a UDF if one matches. |
| User names a function but it's not in `system:functions` | Check case first (names are case-sensitive); if it truly doesn't exist, write the logic inline — or, only if reuse justifies it, **present** a `CREATE FUNCTION`. |
| Same derived expression repeated, or user asks to save/name it | Optionally **present** a `CREATE FUNCTION` — never run it. |
| A UDF-bearing query is slow | Hand off to `couchbase-query-optimizer`. |

For full syntax, see the [official UDF reference](https://docs.couchbase.com/server/current/n1ql/n1ql-language-reference/userfun.html).
