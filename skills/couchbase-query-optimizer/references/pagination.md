# Pagination

LIMIT/OFFSET is the default. It works fine for shallow pages and falls apart at depth. This page covers when to switch and how.

## The LIMIT/OFFSET story

Couchbase honors both LIMIT and OFFSET, and the IndexScan can push them down to the indexer (no per-page Fetch overhead). For shallow offsets, this is fast and easy.

```sql
SELECT name FROM hotel
WHERE state = 'CA'
ORDER BY name
LIMIT 20 OFFSET 0;     -- ✓ fast
LIMIT 20 OFFSET 40;    -- ✓ fast
LIMIT 20 OFFSET 200;   -- ✓ fast
```

Where it falls apart: the indexer still has to scan past every offset entry, even though they're discarded.

```sql
LIMIT 20 OFFSET 10000;    -- ⚠ scans 10,020 entries, returns 20
LIMIT 20 OFFSET 1000000;  -- ❌ scans 1,000,020 entries, returns 20
```

At 100k+ offsets, LIMIT/OFFSET becomes the bottleneck. The fix is KeySet pagination.

## KeySet pagination

Use the last value from page N as the start of page N+1. The cost is constant per page, regardless of depth.

```sql
-- Page 1 — no cursor yet
SELECT name FROM hotel
WHERE state = 'CA'
ORDER BY name
LIMIT 20;

-- Capture the last 'name' returned, e.g. "Hyatt Regency"

-- Page 2 — use the last value as the cursor
SELECT name FROM hotel
WHERE state = 'CA' AND name > "Hyatt Regency"
ORDER BY name
LIMIT 20;

-- Page 3 — last value from page 2 becomes the new cursor
SELECT name FROM hotel
WHERE state = 'CA' AND name > "Sheraton Downtown"
ORDER BY name
LIMIT 20;
```

The index `idx_state_name ON hotel(state, name)` supplies both the filter and the order — every page is a tight index span.

## When KeySet wins, when it loses

| Pattern | LIMIT/OFFSET | KeySet |
|---|---|---|
| Page 1-10 of a list | ✓ Both fine | ✓ Slightly more complex |
| Page 1000 of a list | ❌ Slow | ✓ Fast |
| Show "page 47 of 100" UI | ✓ Works | ❌ Can't jump |
| Infinite-scroll feed | ⚠ Slows as user scrolls | ✓ Constant cost |
| Skip to a known row | ❌ Need OFFSET | ✓ Set cursor to that row |
| Random-access to any page | ✓ Possible | ❌ Doesn't support it |

Rule of thumb: if the UI is "next page" / "load more" / infinite scroll, use KeySet. If the UI is "page 47 of 100," use LIMIT/OFFSET and accept that going deep will be slow.

## Composite cursors

For ORDER BY on multiple fields, the cursor needs every sort field:

```sql
-- ORDER BY two fields
SELECT name, rating FROM hotel
WHERE state = 'CA'
ORDER BY rating DESC, name ASC
LIMIT 20;
-- Last row: rating=4, name="Holiday Inn"

-- Next page — composite cursor: (rating < 4) OR (rating = 4 AND name > 'Holiday Inn')
SELECT name, rating FROM hotel
WHERE state = 'CA'
  AND (
    rating < 4
    OR (rating = 4 AND name > "Holiday Inn")
  )
ORDER BY rating DESC, name ASC
LIMIT 20;
```

The pattern is: for sort keys $f_1, f_2, ..., f_n$ with last-seen values $v_1, v_2, ..., v_n$:
```
(f_1 < v_1)
OR (f_1 = v_1 AND f_2 < v_2)
OR (f_1 = v_1 AND f_2 = v_2 AND f_3 < v_3)
...
OR (f_1 = v_1 AND ... AND f_n > v_n)
```

(Substitute `<` / `>` based on ASC vs DESC of each sort key.)

This looks ugly in raw SQL. In practice, encapsulate it in the data-access layer; from the app's perspective the cursor is an opaque token.

## Encoding the cursor

Send the cursor to the client as base64-encoded JSON so they can return it on the next request:

```python
import base64, json

# After fetching page N
last_row = results[-1]
cursor = base64.urlsafe_b64encode(json.dumps({
    "rating": last_row["rating"],
    "name": last_row["name"],
}).encode()).decode()

# Send cursor in the response

# When client requests next page with that cursor:
parsed = json.loads(base64.urlsafe_b64decode(cursor))
# Use parsed["rating"] and parsed["name"] in the WHERE clause
```

Keep the cursor opaque to the client — they shouldn't depend on its structure.

## Total-count problem

KeySet pagination doesn't tell you the total result count. If you need "showing 21-40 of 7,341," you need a separate count query — and that count query has its own performance characteristics.

Options:
- **Don't show the total** if you can avoid it (infinite scroll doesn't need it)
- **Approximate the total** using `meta().count` or a cached estimate
- **Run COUNT separately**, accepting the extra cost:
  ```sql
  SELECT COUNT(*) AS total FROM hotel WHERE state = 'CA';
  ```
  This can be a covered index scan with the right partial index.
- **Cap the count**: "showing first 10,000+ results" — count up to a limit, then say "10,000+"

## Index requirements for KeySet

KeySet only works if the index supplies the ORDER BY direction. The index needs:
1. The leading key(s) match the WHERE clause
2. The trailing key(s) match the ORDER BY in the same direction

```sql
-- Query: WHERE state = 'CA' ORDER BY name ASC
CREATE INDEX idx_state_name_asc ON hotel(state, name);          -- ✓ default ASC

-- Query: WHERE state = 'CA' ORDER BY name DESC
CREATE INDEX idx_state_name_desc ON hotel(state, name DESC);    -- ✓ explicit DESC
```

If the index direction doesn't match, the planner injects an Order operator (in-memory sort) and the KeySet trick loses its constant-time property.

## Cursor stability

KeySet cursors are stable as long as:
- The sort fields don't change for in-flight docs (someone renaming a hotel after you've cursored past it means you might miss it on a subsequent page)
- The sort columns are unique enough that the cursor doesn't collide (use a tiebreaker like `meta().id` as the last sort key)

Best practice for the tiebreaker:
```sql
-- Always include meta().id as the final sort key for guaranteed uniqueness
ORDER BY rating DESC, name ASC, meta().id ASC
```

And include `meta().id` in the cursor.

## What to do next

- Index design for the trailing ORDER BY → `index-design.md`
- Reading the EXPLAIN to confirm pagination cost is constant → `explain-plan.md`
- Wire it into a workflow → `diagnostic-workflow.md`
