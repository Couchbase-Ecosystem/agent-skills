# Data-modeling fundamentals

Guiding tenet: **data accessed together → stored together**. Model around access, not normalized tables.

- [Document model + KV-first](#document-model--kv-first)
- [Embed vs. reference](#embed-vs-reference)
- [Document size](#document-size)
- [Schema-validation reality](#schema-validation-reality)

## Document model + KV-first

Data read together should live in one document, fetched in a single **KV `GET` by key** — the fastest path. Coming from a relational schema, stop mapping one table → one collection; unify what's always read together.

**Two access paths, very different cost:**

| Path | Latency | Needs | Use when |
|------|---------|-------|----------|
| KV `GET`/sub-doc by key | µs–ms | the key | you can derive the key from what the app knows |
| SQL++ query | ms–sec | an index | filtering by non-key fields, ranges, aggregates |

Design so hot reads are key lookups. The Couchbase twist: a **reference is a key you resolve with a cheap KV `GET`**, not only a SQL++ JOIN — so referencing costs far less than in systems where every lookup is a join. (For the `SELECT META().id … ` + bulk KV-multi-get idiom and index tuning, that's query work → `couchbase-natural-language-querying` / `couchbase-query-optimizer`.)

**Value type:** a stored value is either **JSON** (parsed → indexable & queryable) or **raw binary** (opaque blob — fast and compact by key, but **not** indexable or queryable; sub-doc ops don't apply). Use binary only for data you always fetch by key and never query: session state, encrypted blobs, compact telemetry.

## Embed vs. reference

**By cardinality + access pattern** (start here):

| Relationship | Default | Why |
|--------------|---------|-----|
| **1:1** | Embed | Always read together; one `GET`. |
| **1:few** (bounded, ≤ dozens) | Embed a bounded array | One `GET`; no N+1 child fetches; stays well under 20 MB. |
| **1:many** (unbounded) | Reference (child holds parent key) | Avoids unbounded growth; fetch children by key/query. |
| **many:many** | Reference on the most-queried side | Key list resolved by KV `GET`, or a JOIN. |

**Decision rules** (when cardinality alone doesn't settle it):

| If… | → |
|-----|---|
| reads are mostly **parent-only** fields | reference children |
| reads usually need **parent + child** together | embed children |
| writes touch **parent OR child** independently | reference |
| writes usually touch **both** together | embed |
| child array could grow **unbounded / past ~1 MB** | reference (overrides "read together") |
| child changes **much more often** than parent (e.g. 100×) | reference (don't rewrite parent each time) |

Also embed for a deliberate **point-in-time snapshot**: an order should keep the shipping address *as it was at order time* even if the customer later edits their profile — here divergence is the feature, not staleness.

> Atomicity is **not** a reason to embed. Couchbase has multi-document **ACID transactions** (SDK 6.6+, SQL++ 7.0+), so referenced docs can be updated atomically. Embed for **single-`GET` read efficiency** and to **avoid N+1 fetches** — not for atomicity.

Heuristic: *try to embed first; reference when it makes sense.* Trap — people answer "read together?" optimistically and forget size-at-maturity and update-frequency.

## Document size

**20 MB** is the hard ceiling, not a target. Keep documents well under **~1 MB** (sweet spot ~1 KB–100 KB). Large values hurt cache density and KV throughput, inflate network/replication/XDCR cost, and slow JSON (de)serialization on every read. Drivers of bloat: unbounded arrays, embedded cold data, large blobs, deep nesting.

```sql
-- verify real sizes & array bounds (no $bsonSize/stats tool exists — query for it)
SELECT META().id, ENCODED_SIZE(d) AS bytes, ARRAY_LENGTH(d.items) AS n
FROM mycollection d ORDER BY bytes DESC LIMIT 20;
```

`ENCODED_SIZE(doc)` = **JSON-encoded byte size** (upper-bound proxy; the Magma backend compresses on disk). If a document trends large, split cold/unbounded data into referenced documents. For per-field byte tricks see [`fields-and-conventions.md`](fields-and-conventions.md).

## Schema-validation reality

**Couchbase has no server-side JSON Schema validation** — no `$jsonSchema` equivalent that rejects non-conforming writes at the database. Enforce structure instead by:

- **Application layer** — validate in code / SDK models before writing (primary approach).
- **Eventing service** — an `OnUpdate` function inspects mutations and flags/routes violations (near-real-time, server-side compute; *not* a hard write-time reject).
- A **`schemaVersion`/`_schema` field** + the schema-versioning pattern to manage evolution ([`patterns.md`](patterns.md)).

Be honest about this gap — don't present a `$jsonSchema`-style validator as if Couchbase enforces it.
