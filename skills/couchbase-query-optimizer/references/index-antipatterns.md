# GSI antipatterns (and fixes)

Symptom → fix quick reference. Diagnose the plan with [`diagnosis.md`](diagnosis.md); apply fixes with
[`core-indexing-principles.md`](core-indexing-principles.md) / [`index-ddl.md`](index-ddl.md).

| # | Antipattern | Plan tell |
|---|---|---|
| 1 | Relying on the primary index | `PrimaryScan3` |
| 2 | Range/sort before equality | full-range span |
| 3 | Function-wrapped predicate | `PrimaryScan3` / `Fetch` + filter |
| 4 | Missing covering on a hot path | `Fetch` |
| 5 | Redundant / unused indexes | — |
| 6 | Large-`OFFSET` pagination | high `offset` |
| 7 | Stale statistics | no `optimizer_estimates` |
| 8 | Leading-wildcard `LIKE` | `""`→`"[]"` span |
| 9 | Multiple single-key indexes | `IntersectScan` |
| 10 | `OR` across different fields | `UnionScan` |
| 11 | Low-cardinality leading key | `IntersectScan` / `Fetch` |
| 12 | `ORDER BY` on a non-indexed expr | `Order` operator |
| 13 | `UNNEST`/`ANY` binding mismatch | `PrimaryScan3` (index skipped) |
| 14 | Repeated query without `PREPARE` | high `parse`/`plan` time |
| 15 | `EVERY` without `ANY AND EVERY` | wrong rows (empty arrays) |

## 1. Relying on the primary index in production
**Problem:** queries fall back to `PrimaryScan3`, scanning every key.
**Fix:** build targeted GSIs on the fields in your `WHERE`/`ORDER BY`. Avoid leaving a primary index as the only index on a hot keyspace.

## 2. Range/sort before equality in the key
**Problem:** a compound key like `(date, status)` for `WHERE status = "active" AND date > …` forces inefficient scanning.
**Fix:** lead with equality keys, then sort, then range: `(status, date)`.

## 3. Function-wrapped predicate
**Problem:** wrapping the indexed field in a function (`WHERE LOWER(city) = "paris"`, `WHERE SUBSTR(code,0,2) = …`) prevents a plain index on `city` from being used.
**Fix:** create a **functional index** on the same expression — `CREATE INDEX … ON …(LOWER(city))` — or store a normalized value, or use the **Search service** for text matching.

## 4. Missing covering on a hot read path
**Problem:** the plan shows a `Fetch` because projected fields aren't in the index, adding a KV lookup per row.
**Fix:** add the `SELECT`/`ORDER BY` fields to the index keys so the query is covered (no `Fetch`). Weigh against the extra write cost.

## 5. Redundant or unused indexes
**Problem:** overlapping indexes waste memory and slow writes (every mutation maintains all indexes) without helping reads.
**Fix:** audit with `SELECT * FROM system:indexes` — look for indexes whose `last_scan_time` is null or stale, and for keys that are a prefix of another index. Drop after confirming they're unused.

## 6. Large-`OFFSET` pagination
**Problem:** `OFFSET 10000 LIMIT 20` scans and discards 10,000 rows; cost grows with the offset.
**Fix:** **keyset pagination** — `WHERE sort_key > :last_seen ORDER BY sort_key LIMIT 20`, backed by an index on `sort_key`.

## 7. Stale statistics
**Problem:** after a bulk load the optimizer's cardinality estimates are wrong, so it may pick a full scan over an available GSI.
**Fix:** run `UPDATE STATISTICS` on the keyspace/fields so the cost-based optimizer chooses correctly.

## 8. Leading-wildcard `LIKE`
**Problem:** `WHERE name LIKE '%term%'` (or other text/relevance/"similar to" searches) can't use a range scan.
**Fix:** use the **Search service** (FTS) for text/relevance search. A prefix match `LIKE 'term%'` *can* use an index; or index `SUFFIXES()` as an array (see [`query-optimization.md`](query-optimization.md)).

## 9. Multiple single-key indexes intersected
**Problem:** plan shows `IntersectScan` — two+ single-key indexes scanned and intersected (extra scans + merge).
**Fix:** one **composite** index covering the predicates, ordered per [key-order rules](core-indexing-principles.md#compound-key-order). Keep separate single-key indexes only for genuinely non-deterministic predicate sets.

## 10. `OR` across different fields
**Problem:** `WHERE username = … OR email = …` produces a `UnionScan` (a scan per branch); a composite index doesn't help.
**Fix:** index the OR'd fields as an array — `DISTINCT ARRAY v FOR v IN [LOWER(username), LOWER(email)] END` — and query with `ANY v IN […] SATISFIES v = … END` → single `DistinctScan`.

## 11. Low-cardinality leading key (e.g. `docType`-only index)
**Problem:** an index led by a near-constant field (`CREATE INDEX … ON ks(docType)`) indexes nearly every doc and invites `IntersectScan`/`Fetch`.
**Fix:** use the low-cardinality field as a partial-index **filter** (`WHERE docType = "user"`), not as a leading key. Lead with a selective field.

## 12. `ORDER BY` on a non-indexed expression
**Problem:** the plan has an `Order` operator that sorts every row in memory because the sort key isn't in the index (or direction/order mismatches).
**Fix:** add the sort fields to the index keys **after** the predicates, matching order *and* direction (see [sort-direction matching](core-indexing-principles.md#sort-direction-matching)).

## 13. `UNNEST` or `ANY` binding mismatch
**Problem:** the array index is silently skipped (often → `PrimaryScan3`) because the query's binding variable/expression doesn't match the index definition.
**Fix:** make the `ANY v IN expr SATISFIES …` (or `UNNEST`) expression identical to the indexed `ARRAY … FOR v IN expr END`.

## 14. Repeated query without `PREPARE`
**Problem:** a hot query re-parses and re-plans every call (visible as `parse`/`plan` phase time).
**Fix:** prepare it once — SDK `adhoc=false`, or `PREPARE name FROM …` + `EXECUTE name`. Parameterize values so it's one cached plan (see [`query-optimization.md`](query-optimization.md)).

## 15. `EVERY` without `ANY AND EVERY`
**Problem:** `EVERY v IN arr SATISFIES …` is **true for empty/missing arrays**, returning unwanted documents.
**Fix:** use `ANY AND EVERY v IN arr SATISFIES … END` when at least one element must exist.

## Before finalizing — query/index checklist

- [ ] No hot query relies on the primary index (`PrimaryScan3`)
- [ ] Every composite index leads with an equality key that appears in the query's `WHERE`
- [ ] Low-cardinality fields (e.g. `docType`) are partial-index **filters**, not leading keys
- [ ] Indexed fields aren't function-wrapped in `WHERE` (or a functional index exists)
- [ ] Hot read paths are covered (no `Fetch`), weighed against the extra write cost
- [ ] No deep `LIMIT`/`OFFSET` on large result sets (use keyset pagination)
- [ ] `OR` across different fields uses an array index, not a left-as-is `UnionScan`
- [ ] Array predicates (`ANY`/`UNNEST`) match an array index's binding expression
- [ ] Statistics refreshed after bulk loads (`UPDATE STATISTICS`)
- [ ] No redundant/unused indexes (audit `system:indexes`)

Any failed check → name it and apply the matching fix above.
