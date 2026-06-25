# Joins and the cost-based optimizer

Joins are where CBO actually matters. This page covers picking the right join type, ordering joins, and using ANSI JOIN syntax.

## ANSI JOIN — use this, not lookup JOIN

Couchbase supports two JOIN syntaxes. Use ANSI JOIN:

```sql
-- ✓ ANSI JOIN — modern, supports HASH/NL, both directions
SELECT u.name, o.total
FROM users u
INNER JOIN orders o ON u.id = o.user_id
WHERE u.status = 'active';

-- ❌ Lookup JOIN — legacy, more restrictive
SELECT u.name, o.total
FROM users u
JOIN orders o ON KEY o.user_id FOR u;
```

ANSI JOIN works on any indexed field. Lookup JOIN requires a key-side reference and is more limited. Use ANSI everywhere new.

## Join algorithms

| Algorithm | When the planner picks it | Cost characteristics |
|---|---|---|
| `NestedLoopJoin` | Outer side is small, inner side is indexed | Cheap when outer is small (< few hundred rows). Linear in outer × inner-scan cost. |
| `HashJoin` | Both sides moderately sized; CBO has cardinality info | Build hash table of smaller side, probe with larger. Wins when both sides are non-trivial. |
| `IndexJoin` (legacy) | Lookup-JOIN with key-only references | Rare in ANSI JOIN code. |

The CBO picks between NL and HASH automatically when stats are available. Without stats, it defaults to NL.

## Driving from the most selective side

The general rule: drive the join from the keyspace where the WHERE predicate is most selective. That keyspace becomes the outer side.

```sql
-- Bad — joins from the larger side
SELECT u.name, o.total
FROM orders o                         -- 10M rows
INNER JOIN users u ON o.user_id = u.id -- 100k rows
WHERE u.status = 'admin';             -- 50 admin users

-- Better — drive from the small side
SELECT u.name, o.total
FROM users u                          -- 50 admins after WHERE filter
INNER JOIN orders o ON o.user_id = u.id -- index lookup per admin
WHERE u.status = 'admin';
```

After WHERE filtering, `users` is 50 rows; 50 nested-loop probes into `orders` (with an index on `user_id`) is cheap. Driving from orders means scanning 10M and looking up users 10M times.

CBO will reorder joins automatically if stats are good. If stats are missing or wrong, force the order with `/*+ ORDERED */`.

## The join-side indexes you need

For an ANSI JOIN `a JOIN b ON a.id = b.foreign_id`:

- The **probe side** (usually the larger one) needs an index on the join key — `CREATE INDEX idx_b_fkey ON b(foreign_id)`. Without this, the planner can't do an index-driven join and falls back to scanning all of b for each a-row.
- The **build side** doesn't strictly need an index on the join key (it's hashed in memory for HashJoin, or iterated for NL).

For a covering join (best case), the probe-side index should include every column from b that the SELECT projects.

```sql
-- The covering probe-side index
CREATE INDEX idx_orders_user_total_cover
ON orders(user_id, total, order_date);

-- Now the join can be covered on the orders side:
SELECT u.name, o.total, o.order_date
FROM users u
INNER JOIN orders o ON o.user_id = u.id
WHERE u.status = 'admin';
```

## Reading a join plan

A NestedLoopJoin in EXPLAIN:
```json
{
  "#operator": "NestedLoopJoin",
  "alias": "o",
  "on_clause": "((`o`.`user_id`) = (`u`.`id`))",
  "~child": {
    "#operator": "IndexScan3",
    "index": "idx_orders_user_id",
    "spans": [...]
  }
}
```

The `~child` is the inner side — the keyspace scanned once per outer row. Make sure it's an IndexScan3, not a PrimaryScan3.

A HashJoin:
```json
{
  "#operator": "HashJoin",
  "alias": "o",
  "build_alias": "u",
  "on_clause": "((`o`.`user_id`) = (`u`.`id`))",
  "~child": {
    "#operator": "IndexScan3",
    "index": "idx_orders_user_total_cover"
  }
}
```

`build_alias` tells you which side was hashed. The smaller side should be the build side.

If you see `NestedLoopJoin` with a `PrimaryScan3` child, you're doing a full-keyspace scan per outer row. That's catastrophic for non-trivial outer sets. Fix immediately: add the join-key index.

## ORDERED hint

When you know the optimal order and CBO is picking wrong:

```sql
SELECT /*+ ORDERED */ u.name, o.total
FROM users u
INNER JOIN orders o ON o.user_id = u.id
WHERE u.status = 'admin';
```

Forces FROM-clause order: u outer, o inner. Useful when:
- Stats are missing or stale
- The cardinality of WHERE u.status = 'admin' is much smaller than CBO estimates
- You're debugging — pin the plan, see if it's faster, then update stats to make CBO agree

## USE HASH / USE NL

Forces a specific join algorithm:

```sql
-- Force HashJoin with orders as probe
SELECT u.name, o.total
FROM users u
INNER JOIN orders o USE HASH(probe) ON o.user_id = u.id
WHERE u.status = 'admin';

-- Force NestedLoopJoin
SELECT u.name, o.total
FROM users u
INNER JOIN orders o USE NL ON o.user_id = u.id
WHERE u.status = 'admin';
```

Pick NL when outer is small (< few hundred) and the inner side has a tight index. Pick HASH when both sides are non-trivial and won't fit in NL's per-outer-row scan budget.

## Subqueries vs joins

Couchbase supports correlated subqueries:

```sql
SELECT u.name,
       (SELECT VALUE COUNT(*) FROM orders o WHERE o.user_id = u.id)[0] AS order_count
FROM users u
WHERE u.status = 'admin';
```

For 50 admins, this is 50 sub-queries — same cost shape as an NL join. EXPLAIN it before deciding. Often a GROUP BY join is cleaner:

```sql
SELECT u.name, agg.order_count
FROM users u
INNER JOIN (
  SELECT user_id, COUNT(*) AS order_count
  FROM orders
  GROUP BY user_id
) agg ON agg.user_id = u.id
WHERE u.status = 'admin';
```

Run EXPLAIN on both. Pick the one with the cheaper plan.

## Updating statistics for join queries

This is where CBO needs them most. After bulk loads or significant data changes:

```sql
UPDATE STATISTICS FOR users(id, status);
UPDATE STATISTICS FOR orders(user_id, total);
```

Then run EXPLAIN on the join query — `optimizer_estimates` should appear on every operator, and CBO will pick the right algorithm and order.

Schedule stats updates weekly or after every bulk-load job. Use `run_sql_plus_plus_query` to run `UPDATE STATISTICS` when read-only mode is off.

## What to do next

- Single-keyspace queries → `query-patterns.md`
- Designing the right indexes → `index-design.md`
- Understanding the join plan → `explain-plan.md`
- CBO hints in detail → `cost-based-optimizer.md`
- Wiring this into a workflow → `diagnostic-workflow.md`
