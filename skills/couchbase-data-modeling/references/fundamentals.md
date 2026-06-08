# Data-modeling fundamentals

## Document model + KV-first

Model around how data is **accessed**, not around normalized tables. Data read together should live in one document so it can be fetched with a single **KV `GET` by key** — the fastest path in Couchbase. Coming from relational/Mongo, stop mapping one table → one collection; identify what's always read together and unify it.

## Embed vs. reference (by cardinality + access pattern)

| Relationship | Default | Why |
|--------------|---------|-----|
| **1:1** | Embed | Always accessed together; one `GET`. |
| **1:few** (bounded, e.g. ≤ dozens) | Embed a bounded array | Stays well under 20 MB; atomic updates. |
| **1:many** (unbounded) | Reference (child holds parent key) | Avoids unbounded growth; fetch children by key/query. |
| **many:many** | Reference on the most-queried side | Use a key list; resolve with KV `GET` or JOIN. |

The Couchbase twist: a reference is a **key you resolve with a cheap KV `GET`**, not only a SQL++ JOIN — so referencing costs less than in systems where every lookup is a join. Embed when the data is bounded and read together; reference when it's unbounded, large, independently accessed, or shared.

## Document size

Hard limit **20 MB** per document; in practice keep documents small (large values hurt cache density and KV throughput). Drivers of bloat: unbounded arrays, embedding cold data, large binary blobs, deep nesting. Verify real sizes with SQL++ `ENCODED_SIZE(doc)` and array bounds with `ARRAY_LENGTH(arr)` (there is no `$bsonSize`/stats tool — query for it). If a document trends large, split cold/unbounded data into referenced documents.

## Schema-validation reality (important divergence)

**Couchbase has no server-side JSON Schema validation** — there is no `$jsonSchema` equivalent that rejects non-conforming writes at the database. Enforce structure instead by:
- **Application layer** — validate in code / your SDK models before writing (primary approach).
- **Eventing service** — an `OnUpdate` function can inspect mutations and flag/route violations (near-real-time, server-side compute, but not a hard write-time reject).
- **A `schemaVersion` field** + the schema-versioning pattern to manage evolution.

Be honest about this gap — don't present a `$jsonSchema`-style validator as if Couchbase enforces it.
