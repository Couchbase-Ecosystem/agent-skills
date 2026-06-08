# Document-key design (Couchbase-specific)

Unlike systems that auto-generate an `_id`, **you design Couchbase document keys**, and a good key is the single most important modeling decision — a well-chosen key turns lookups into a direct KV `GET` (no query, no index).

## Prefer KV access by key

If you can derive the key from what the app already knows, fetch the document directly by key (`GET`/sub-doc) instead of querying. This is the fastest, cheapest path and needs no GSI. Design keys so your common reads are key lookups.

## Key naming conventions

- Use a **type prefix + identifier**, delimited consistently: `user::123`, `order::2026-0001`, `hotel::sfo::42`.
- Keep keys deterministic and reconstructable from app data (so you can `GET` without a lookup).
- Keys are UTF-8 strings, max 250 bytes; they're case-sensitive.

## Composite / natural keys

Encode the identifying dimensions into the key: `tenant::user::123` (multi-tenant), `cart::user::123` (one cart per user), `route::SFO::JFK`. This gives uniqueness, enables direct `GET`, and lets you enumerate by key prefix.

## Counter keys (sequential ids)

Need monotonic ids? Use a dedicated counter document and the atomic KV **increment** operation to hand out sequence values (`counter::orders` → 1001), then build the document key from it (`order::1001`). Atomic and contention-safe — the KV-native alternative to auto-increment.

## Keyspace placement (bucket / scope / collection)

- **Collection** per document *type* (like a table).
- **Scope** to namespace a tenant or a service's collections.
- **Bucket** only when you need separate memory/replica/storage settings or lifecycle isolation.

See [`antipatterns.md`](antipatterns.md) for when *not* to split, and the bucketing/grouping & time-series entries in [`patterns.md`](patterns.md) for key strategies that encode time/grouping.
