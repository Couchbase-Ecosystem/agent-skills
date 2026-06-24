# Document-key design (Couchbase-specific)

Unlike systems that auto-generate an `_id`, **you design Couchbase document keys** — the single most important modeling decision. A well-chosen key turns a lookup into a direct KV `GET` (no query, no index).

- [Key strategies](#key-strategies)
- [Naming conventions](#naming-conventions)
- [Hash distribution (no range hot-shards)](#hash-distribution-no-range-hot-shards)
- [Counter keys](#counter-keys)
- [Keyspace placement & multi-tenancy](#keyspace-placement--multi-tenancy)

## Key strategies

| Strategy | Example | Works when | Fails when |
|----------|---------|-----------|------------|
| **Natural** (domain id) | `user::alice@x.com`, `book::9780201633610` | id is stable, unique, known by app | id is mutable (emails change!) or absent at write time |
| **Composite** (encode dimensions) | `tenant::user::123`, `route::SFO::JFK` | want direct `GET` + prefix enumeration | any component is mutable |
| **Generated UUID** | `user::3f5a8b2c-…` | no stable natural id; multi-writer, no coordination | opaque (debugging) → mitigate with type prefix |
| **Generated ULID** | `order::01HXKZ7M8YQNT9…` | want generated id **+ lexical sort by creation time** | (none significant; prefer over UUIDv4 if you ever want "most recent N" by key scan) |
| **Counter** (sequential) | `order::1001` | users must read/type the id (invoices) | high insert rate concentrates on the counter doc (see below) |

Rule of thumb: derive the key from data → KV `GET` directly. Mutable identifier → don't put it in the key; use a stable id + a lookup doc/index for the mutable field.

## Naming conventions

- **Type prefix + identifier**, delimited consistently: `user::123`, `order::2026-0001`, `hotel::sfo::42`.
- Keys are **UTF-8 strings, max 250 bytes**, case-sensitive, unique **within a collection** (same key in another collection is fine).
- Keep keys **deterministic/reconstructable** from app data so you can `GET` without a lookup.
- `::` is the convention; pick one **single-byte** delimiter and stay consistent (at billion-doc scale, key bytes are RAM — keys are held in memory for every document).
- Don't encode **mutable state** in the key (`order::OPEN::123` → on status change you must delete+reinsert and fix every reference). State is a field.

## Hash distribution (no range hot-shards)

Couchbase **CRC32-hashes the full key** into one of **1024 vBuckets** spread across nodes. Consequence — unlike range-sharded stores (DynamoDB / MongoDB / HBase), **sequential or timestamp-prefixed keys still distribute evenly**, as long as the full key varies (the unique suffix changes the hash). So "sequential keys cause hot shards" is largely **not** a Couchbase concern.

The real key-hotspot risks:
- A **single hot key** many writers hit at once (e.g. one counter, one aggregate doc).
- Mutable state in the key (correctness, not distribution).

## Counter keys

Need monotonic ids? Use a dedicated counter doc + the **atomic KV increment** op to hand out sequence values, then build the key from it:

```
increment counter::orders  ->  1001        # atomic, contention-safe
insert    order::1001 { ... }              # cost: 2 mutations per insert
```

The KV-native alternative to SQL `AUTO_INCREMENT`. The counter doc is a potential hot key — if insert rate is very high (>~10k/s), **shard the counter** into N docs (pick one at random per insert, take max when reading). For most workloads a single counter is fine; **ULIDs avoid the hot key entirely** when strict monotonic ordering isn't required.

## Keyspace placement & multi-tenancy

- **Collection** per document *type* (like a table). Split by type, not value.
- **Scope** to namespace a tenant or a service's collections.
- **Bucket** only for separate memory/replica/storage settings or lifecycle isolation.

**Multi-tenancy ladder** (isolation ↔ cost; numbers are guidance, vary by version/sizing):

| Approach | Rough scale ceiling | Isolation | TCO | Use when |
|----------|--------------------|-----------|-----|----------|
| Separate **cluster** | — | Highest (resources + blast radius) | Highest | strict compliance / very large tenants |
| Separate **bucket** | ~30 / cluster | Resource isolation (own RAM/replicas) | High | few big tenants with different SLAs |
| Separate **scope** | ~1000 / cluster | Access-control + index isolation, **no** resource isolation | Low | typical B2B/SaaS — **default** |
| **Key-prefix / field** in shared collection | unlimited | None (logical only) | Lowest | B2C scale, many small tenants |

See [`antipatterns.md`](antipatterns.md) for when *not* to split (e.g. scope-per-user in B2C), and [`patterns.md`](patterns.md) for bucketing/grouping & time-series key strategies.
