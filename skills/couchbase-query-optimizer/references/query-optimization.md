# Query-shape optimization (beyond indexing)

Indexing is the primary lever, but the query's shape matters too.

## Predicate pushdown & selectivity
- Put the **most selective** filters in `WHERE` and ensure the **leading index key** matches one of them, so the index scan is bounded rather than full-range.
- Avoid wrapping indexed fields in functions in the `WHERE` clause (defeats the index — see antipatterns).

## Projection
- Don't `SELECT *` on hot paths — project only needed fields so a **covering** index can satisfy the query without a `Fetch`. `SELECT RAW expr` returns unwrapped scalars cheaply.

## JOINs
- Prefer key-based joins (`JOIN … ON KEYS`) when you have the document keys.
- For ANSI `JOIN … ON <pred>`, **index the join keys** and order the join so the **smaller/more-selective side drives**.

## Arrays / UNNEST
- Filter **before** `UNNEST` where possible to reduce the rows flattened.
- Back array predicates with a `DISTINCT ARRAY` index so `UNNEST`/`ANY … SATISFIES` use the index instead of scanning.

## Pagination
- Use **keyset pagination** (`WHERE sort_key > :last ORDER BY sort_key LIMIT n`) instead of large `OFFSET`, backed by an index on the sort key.

## LIMIT / ORDER BY
- Include a `LIMIT` so the planner can stop early.
- Back `ORDER BY` with an index whose keys match (and direction matches) to avoid an in-memory sort.

## Aggregations
- `GROUP BY` on indexed leading keys enables aggregate pushdown and avoids scanning.

## UPDATE / MERGE
- Constrain mutations with an **indexed predicate** (`UPDATE ks SET … WHERE <indexed pred>`) so they don't scan the whole keyspace.
- Use `MERGE` for conditional upserts. Keep mutation predicates selective and indexed — the same `EXPLAIN`/ESR/covering reasoning applies to the `WHERE` of a DML statement.
