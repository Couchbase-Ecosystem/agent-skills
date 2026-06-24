# Index DDL reference

> The MCP server is read-only by default — these statements are **recommendations to give the user**, who runs them in the Query Workbench / `cbq` (or after enabling write mode with approval). Creating an index requires the `Query Manage Index` RBAC privilege.

## Contents
- [CREATE INDEX](#create-index)
- [Deferred build (create many, build once)](#deferred-build-create-many-build-once)
- [Replicas & partitioning (scale / HA)](#replicas--partitioning-scale--ha)
- [Monitor](#monitor)
- [Alter / drop](#alter--drop)
- [Hints & statistics](#hints--statistics)

## CREATE INDEX

```sql
CREATE INDEX idx_country_name
  ON `travel-sample`.inventory.airport(country, airportname)
  WHERE country IS NOT MISSING          -- optional: partial index
  WITH { "defer_build": true };          -- optional: defer the build
```

Modifiers:
- `IF NOT EXISTS` — safe re-run.
- `DESC` per key — `…(country, airportname DESC)` to match a descending sort.
- `WHERE <pred>` — **partial index** over a filtered subset (smaller, cheaper).
- `INCLUDE MISSING` on the leading key — index documents missing that field (7.6+).
- Array key — `DISTINCT ARRAY s.day FOR s IN schedule END` for array/`UNNEST` predicates.

## Deferred build (create many, build once)

```sql
CREATE INDEX idx_a ON ks(a) WITH { "defer_build": true };
CREATE INDEX idx_b ON ks(b) WITH { "defer_build": true };
BUILD INDEX ON ks(idx_a, idx_b);          -- builds both in a single scan
```

## Replicas & partitioning (scale / HA)

```sql
CREATE INDEX idx_a ON ks(a) WITH { "num_replica": 2 };                          -- N+1 copies; needs ≥ N+1 index nodes
CREATE INDEX idx_b ON ks(b) PARTITION BY HASH(b) WITH { "num_partitions": 8 };  -- spread one index over index nodes (16 default)
```
- Index replicas are **active** (load-balanced across copies), unlike passive KV replicas. Enterprise only.
- Pin to nodes with `WITH { "nodes": [...] }`; if both given, `num_replica` must equal `len(nodes) - 1`.
- Partition by the index's **equality** key to get *partition elimination* (scan one partition, not all).

## Monitor

```sql
SELECT name, state, `using`, index_key, `condition`, last_scan_time
FROM system:indexes
WHERE keyspace_id = "airport";
```
States progress `deferred` → `building` → `online`. A null/old `last_scan_time` flags an unused index.

## Alter / drop

```sql
ALTER INDEX idx_a ON ks WITH { "action": "replica_count", "num_replica": 1 };
DROP INDEX idx_a ON ks IF EXISTS;
```

## Hints & statistics

```sql
SELECT … FROM ks USE INDEX (idx_country_name USING GSI) WHERE …;   -- force an index (use sparingly)
UPDATE STATISTICS FOR `travel-sample`.inventory.airport(country, airportname);  -- refresh CBO stats
```
