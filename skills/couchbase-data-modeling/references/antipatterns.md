# Data-modeling antipatterns (and fixes)

## 1. Unnecessary buckets / scopes / collections

**Problem:** splitting homogeneous data across many buckets/collections (e.g. one bucket per customer, one collection per day) — often a relational/SQL habit. Each adds overhead and forces cross-keyspace JOINs/`UNION`s.

**Use the hierarchy deliberately:**
- **Bucket** — top-level, has its own memory/replica/storage settings. Few per cluster. Split by *isolation/lifecycle*, not by entity.
- **Scope** — a namespace within a bucket. Good for **multi-tenant** separation or per-microservice grouping.
- **Collection** — holds one document type (like a SQL table). Split by *type*, not by value.

**Fix:** keep homogeneous data in one collection and distinguish rows by a field (and index it) or by key prefix; use bucketing/grouping or time-series patterns for time-partitioned data — not a new collection per period.

## 2. Excessive JOINs (over-normalization)

**Problem:** repeatedly JOINing the same related data on hot paths because the model was normalized like SQL. Each JOIN does extra work; without an index on the join key it can scan.

**Fix:** **denormalize** frequently-read-together data into the parent document (embed), or cache selected fields with the **extended-reference** pattern. Reserve JOINs for analytical/occasional access. Resolve simple references with KV `GET` by key instead of a JOIN where possible.

## 3. Redundant / unnecessary GSIs

**Problem:** indexes created without query evidence. Every index adds write/maintenance cost and memory use; overlapping indexes (one a prefix of another) duplicate cost.

**Fix:** index from real query evidence; audit `system:indexes` for unused indexes (null/stale `last_scan_time`) and drop them. **Deep index design and tuning belong to `couchbase-query-optimizer`** — this skill only flags obvious index bloat as a modeling smell.
