# Data-modeling antipatterns (review checklist)

When reviewing a proposed model, scan for these. Each: **smell → why it hurts → fix.**

- [Catalog](#catalog)
- ["Is this model OK?" checklist](#is-this-model-ok-checklist)

## Catalog

| Smell | Why it hurts | Fix |
|-------|--------------|-----|
| **Unbounded embedded array** (`history`/`log`/`events`/`orders` that grows forever) | every append rewrites the whole doc; trends toward 20 MB; reads deserialize it all | children become their own docs, linked by parent key/prefix or secondary index |
| **One giant document per tenant/company** (embeds all users/orders) | write contention, huge reads, hits size limit | separate docs per entity referencing the tenant id |
| **Deeply nested arrays-of-arrays** (>3 levels) | updating one leaf rewrites the tree; can't target inner elements; bloated array indexes | flatten — each leaf a separate doc with FK-style fields |
| **Mutable state in the key** (`order::OPEN::123`, key = email) | state/email changes ⇒ delete+reinsert + every reference breaks; XDCR/Eventing see data loss | stable opaque key; mutable value is a **field** (`{status:"OPEN"}`); index it for lookup |
| **Type in body, no key prefix, in shared `_default`** | can't filter type by key scan; every type query needs a secondary index | prefix the key (`user::42`) **or** (better) put each type in its own **collection** |
| **Everything in `_default`** scope/collection | loses per-collection TTL & access control; type queries must scan+filter | named scopes/collections per domain (`users`, `orders`, …) |
| **Denormalize with no update plan** (copied `customerName` in orders) | source changes ⇒ silent staleness everywhere | choose: accept point-in-time copy · Eventing fan-out update · or join at read time — and document it |
| **No `schemaVersion` field** | can't tell which docs are migrated; code can't branch safely | stamp `schemaVersion` from day one (see [`patterns.md`](patterns.md)) |
| **No TTL on session/temp data** (`sessions`, `cache_*`) | grows unbounded; cleanup later = expensive delete-by-query | per-doc `expiry` at write or a collection `maxTTL` |
| **Excessive JOINs** (re-joining the same hot data; SQL-normalized model) | extra work per query; unindexed join key ⇒ scan | denormalize/embed read-together data, or extended-reference; resolve simple refs by KV `GET` |
| **Scope-per-user** (B2C) | scopes are heavyweight; thousands+ don't scale (~1000/cluster) | one scope, user id in key prefix/field; per-tenant scopes are for B2B/SaaS |
| **Schema-by-accident** (drift: `email`/`e_mail`/`emial`) | filters miss mis-shaped records; invisible until it breaks | validate at app layer; periodically `get_schema_for_collection` (INFER) to detect drift |
| **Redundant / unused GSIs** (no query evidence; one a prefix of another) | every index adds write + memory cost | index from real query evidence; audit `system:indexes` for null/stale `last_scan_time` and drop |

> Note: Couchbase **hash-distributes keys** (CRC32 → 1024 vBuckets), so sequential/timestamp-prefixed keys are **not** a hot-shard antipattern the way they are in range-sharded stores — see [`document-keys.md`](document-keys.md). The real key risks are *mutable state in the key* and a *single hot key/counter*.

> Deep index design & "why is my query slow" belong to **`couchbase-query-optimizer`** — this skill only flags obvious index bloat as a modeling smell.

## "Is this model OK?" checklist

- [ ] No document has an **unbounded array**
- [ ] No key contains **mutable state**; keys derive from stable data
- [ ] Type discrimination is in the **key prefix or collection name**
- [ ] Docs **read together are stored together** (or denormalized *with* an update plan)
- [ ] Docs that **change at very different rates** are separated
- [ ] A **`schemaVersion`** field exists for future migration
- [ ] **Session/temp data has a TTL**
- [ ] **Read-vs-write ratio** was considered, not just write cleanliness
- [ ] Bucket/scope/collection boundaries reflect **lifecycle/isolation**, not just topic

Any failed check → name it to the user and explain the consequence.
