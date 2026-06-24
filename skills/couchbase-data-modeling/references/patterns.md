# Design-pattern library

Match the schema shape to a pattern. Each: *problem → Couchbase approach → use / avoid.*

- [Approximation](#approximation) · [Computed](#computed) · [Extended reference](#extended-reference) · [Outlier](#outlier)
- [Polymorphic](#polymorphic) · [Schema versioning](#schema-versioning) · [Document versioning](#document-versioning)
- [Attribute](#attribute) · [Archive](#archive) · [Bucketing / grouping](#bucketing--grouping) · [Time-series](#time-series)

## Approximation
High-frequency counters (views, likes) where exact real-time precision isn't needed. Increment in memory and flush periodically (or sample an atomic KV counter), cutting writes ~100×. Use for tolerant metrics; avoid for financial/regulated counts.

## Computed
Pre-calculate expensive aggregates and store the result so reads are cheap. Update on write (low write volume) or via a background `MERGE`/Eventing job (high volume); include a `computedAt` timestamp. Use for repeated expensive rollups; avoid when strong consistency is required.

## Extended reference
Cache a few display fields of a referenced entity in the parent (e.g. `customerName` in an order) to avoid a JOIN/lookup on hot paths. The flip side of "array of keys → N+1 `GET`s": store a small **summary object** per element instead. Sync on change via `UPDATE … WHERE`; track `cachedAt`. Cache slowly-changing, non-sensitive fields; avoid for volatile or sensitive data, and always have an update plan (see [`antipatterns.md`](antipatterns.md)).

## Outlier
Most documents are small but a few have huge arrays (the bestseller with 50k buyers). Keep typical docs inline; for outliers, cap the array, set a flag (`hasOverflow: true`), and move overflow to separate referenced documents. Use for long-tail distributions; avoid when sizes are uniform.

## Polymorphic
Store related-but-different shapes in one collection with a flat `type` discriminator + shared common fields. Enables one keyspace/index for cross-type queries plus type-specific fields. Use for product variants, events, CMS; avoid when types have conflicting access patterns or must be isolated (then use separate collections).

## Schema versioning
Manage schema evolution **without downtime** — Couchbase enforces no shape, so old and new coexist. Stamp each document with `schemaVersion`. Three migration approaches:

| Approach | How | Use when |
|----------|-----|----------|
| **Version-keyed coexistence** | app reads `schemaVersion`, handles each shape | always (baseline) |
| **Big-bang** | one batch `UPDATE`/Eventing pass migrates all docs at once | small collection, or a required field everything needs now |
| **Cooperative re-versioning** ("Strangler Fig") | migrate each doc lazily as it's read/written in normal traffic | large collection, gradual cutover, no maintenance window |

No NULL-column padding needed (unlike RDBMS `ALTER TABLE`): a missing field just reads as `MISSING`. Bump the version on breaking changes (rename, type change, restructure).

## Document versioning
Keep an audit trail by snapshotting full documents into a `revisions` collection on each change; the current document holds the latest + a version number. Optionally TTL old revisions. Use for compliance/audit/rollback; avoid for many-per-second changes (use event sourcing).

## Attribute
Many sparse, variable optional fields → collapse them into an array of `{name, value}` pairs and index `(name, value)` with one array index, instead of dozens of sparse indexes. Query with `ANY … SATISFIES`/`UNNEST`. Use for flexible/evolving attributes; avoid for a fixed, stable schema.

## Archive
Move cold/old data off the hot working set: a separate collection/bucket, a lower tier, external object storage, or TTL-based expiry; the **Magma** storage backend suits large, mostly-cold datasets. Keep archive documents self-contained (denormalized). Use when most data is rarely read; avoid if access is uniform.

## Bucketing / grouping
*(a.k.a. the "bucket pattern" — renamed to avoid confusion with Couchbase **Buckets**.)* Group many small related items into one document with a **bounded** array (e.g. N events per doc, keyed `device::123::2026-06-08`) to cut document count and align with how data is read. Use for streams/logs read in ranges; avoid for random single-item access or highly variable group sizes.

## Time-series
Append-only measurements (IoT, metrics). Use Couchbase **time-series support (7.2+)** and/or bucketed time-series documents (one doc per series per window) with rollups for older data. Choose a key encoding the series + time window; bound each window so the doc stays < ~1 MB. Use for high-volume time-stamped data; avoid for low volumes or frequent historical updates.
