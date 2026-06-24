# Migrating from a relational database

The shift: relational defaults to 3NF and denormalizes when forced; document defaults to **modeling the access pattern** and normalizes when forced (by write patterns). Don't translate tables 1:1 — re-model what's read together.

- [Concept mapping](#concept-mapping)
- [Feature mapping](#feature-mapping)
- [Migration strategy ladder](#migration-strategy-ladder)
- [How to actually do it](#how-to-actually-do-it)
- [Easier in Couchbase](#easier-in-couchbase)

## Concept mapping

Use the modern (Couchbase 7.0+, Collections) mapping:

| Relational | Couchbase | Notes |
|-----------|-----------|-------|
| Server | Cluster | |
| Database | Bucket | container with its own RAM/replica/storage settings |
| Schema | Scope | namespacing within a bucket |
| Table | **Collection** | type-grouping of documents (not "bucket per table" — that's pre-7.0) |
| Row | Document | one JSON doc |
| Primary key | **Document key** (`META().id`) | the key *is* the PK; no separate column |
| Column | JSON field | free shape; absent ≠ NULL |
| Foreign key | field holding another doc's key | **not enforced** — app's job |
| JOIN | SQL++ JOIN · denormalize · KV multi-get | pick by access pattern |
| Index | GSI | similar concept, different mechanics |

## Feature mapping

| Relational feature | Couchbase equivalent |
|--------------------|----------------------|
| Stored procedure | Eventing function (JS) **or** SQL++ UDF |
| Trigger | Eventing function (on mutation) |
| **Schema enforcement** (CHECK/NOT NULL) | post-write **Eventing** validation (no server-side reject) |
| ACID transaction | multi-document **ACID transaction** (SDK 6.6+, SQL++ 7.0+) |
| Replication (Always-On, mirroring) | **XDCR** (bidirectional possible; configurable conflict resolution) |
| Change Data Capture | Eventing function |
| Materialized view | maintained summary docs (computed pattern) or Analytics service |
| Full-text search | FTS service |
| `SERIAL` / `AUTO_INCREMENT` | **ULID** (preferred) or atomic counter ([`document-keys.md`](document-keys.md)) |
| `ALTER TABLE add column` | just start writing the field; old docs read it `MISSING` |
| `ENUM` | string field + app-level validation |

## Migration strategy ladder

| Strategy | Denormalization | Timeline | Payoff | What it is |
|----------|-----------------|----------|--------|------------|
| **Rehost** (lift & shift) | none/light | shortest | low | tables → collections as-is; rebuild indexes |
| **Refactor** | light | short–med | medium | code tweaks, light denorm on hot paths |
| **Redesign** | moderate | longer | high | re-model app logic; stored procs → Eventing/UDF |
| **Rewrite** | broad | longest | highest | full re-model around access patterns |

Rehost is fastest but you keep a relational design in a document DB (JOIN-equivalent queries, no speedup) — the most common and most-regretted outcome. Re-modeling is where the wins are.

## How to actually do it

- **Re-model hot paths, translate cold paths.** For each high-traffic read: list the tables involved → "could these be one document?" → embed if 1:1 / bounded 1:few; reference if unbounded 1:many or m:m. Low-traffic admin/batch reads can stay near-relational.
- **Don't big-bang.** Migrate slice-by-slice: pick one feature → re-model it → **dual-write** old DB + Couchbase → read from Couchbase and verify → cut over → drop the old tables for that slice → repeat. Keeps blast radius small.
- Result: **fewer collections than tables**, each document richer.

## Easier in Couchbase

- **Nest instead of join:** `user → addresses → city → country` is one nested document, one `GET`.
- **Optional/varying fields:** just omit them; check with `IS MISSING` (no NULL columns). See [`fields-and-conventions.md`](fields-and-conventions.md).
- **Polymorphic data:** prefer a **collection per type** over one sparse "polymorphic table" — keeps indexes and queries clean.
