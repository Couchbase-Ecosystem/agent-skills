# GSI antipatterns (and fixes)

## 1. Relying on the primary index in production
**Problem:** queries fall back to `PrimaryScan`, scanning every key.
**Fix:** build targeted GSIs on the fields in your `WHERE`/`ORDER BY`. Avoid leaving a primary index as the only index on a hot keyspace.

## 2. Range/sort before equality in the key
**Problem:** a compound key like `(date, status)` for `WHERE status = "active" AND date > …` forces inefficient scanning.
**Fix:** follow ESR — equality keys lead: `(status, date)`.

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
**Fix:** use the **Search service** (FTS) for text/relevance search. A prefix match `LIKE 'term%'` *can* use an index.
