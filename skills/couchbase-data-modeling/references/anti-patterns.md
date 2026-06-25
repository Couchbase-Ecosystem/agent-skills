# Anti-patterns

A catalog of common modeling mistakes, what they look like, why they hurt, and what to do instead. When reviewing a model the user proposes, check against this list — these mistakes are common enough that they're worth a specific pass.

## The "one big document" mistake

```json
{
  "id": "company::acme",
  "name": "Acme Corp",
  "users": [...50000 users...],
  "orders": [...500000 orders...],
  "products": [...1000 products...]
}
```

**Why it's wrong:** Every read pulls the entire document. Every write rewrites the entire document. Document approaches the 20 MB hard limit. Writes serialize (all clients writing through one document means contention).

**Fix:** Separate documents per user / order / product, all referencing the company ID.

**Spot it by:** any document with an unbounded array.

## The "everything in `_default`" mistake

```
Bucket: app_data
  Scope: _default
    Collection: _default      ← every document type lives here
```

**Why it's wrong:** Loses per-collection TTL, loses per-collection access control, makes type-discriminating queries slower (must scan all docs and filter by a `type` field).

**Fix:** Use named scopes and collections. Per-domain collections at minimum: `users`, `orders`, `events`, etc. See `boundaries.md`.

**Spot it by:** the absence of scope/collection in any documentation or DDL.

## The "type field in the body, no key prefix" mistake

```json
{ "type": "user", "id": "42", ... }
{ "type": "order", "id": "ORD-00837", ... }
```

With key `42` and key `ORD-00837` in the same collection.

**Why it's wrong:** Without a type prefix in the key, you can't filter by type via key scan. Every type-discriminating query needs to use a secondary index. Operational tools (browsing keys, debugging) lose context.

**Fix:** Prefix the key: `user::42`, `order::ORD-00837`. Or put them in separate collections (better).

**Spot it by:** keys like `42`, `8237492`, or UUIDs without a type prefix.

## The "deeply nested array of arrays" mistake

```json
{
  "id": "tenant::acme",
  "departments": [
    {
      "name": "Engineering",
      "teams": [
        {
          "name": "Backend",
          "members": [
            { "name": "Alice", "roles": [{ "name": "lead", ... }, ...] }
          ]
        }
      ]
    }
  ]
}
```

**Why it's wrong:** Updating one member's role means rewriting the whole nested structure. Querying for "all leads across all teams" requires scanning everything. Indexes on deeply-nested array elements are large and slow.

**Fix:** Flatten. Each member is a separate document with foreign keys: `department_id`, `team_id`.

**Spot it by:** any document with > 3 levels of array nesting.

## The "key contains mutable state" mistake

```
order::OPEN::ORD-00837
```

State changes from OPEN to FULFILLED to CLOSED — the key has to change with it.

**Why it's wrong:** Changing a key = delete old + insert new. References to the old key break. Eventing functions / XDCR / backups see this as data loss.

**Fix:** Mutable state is a document field, not part of the key. `order::ORD-00837` with `{ status: "OPEN" }`.

**Spot it by:** any key containing words like "status," "state," "active," "current," "pending."

## The "timestamp as leading key component" mistake

```
event::2026-05-21T14:32:18::abc123
```

**Why it's wrong:** Every event written within the same time bucket hashes near the same vBucket → write hot spot at scale.

**Fix:** High-entropy prefix (source ID, hash of source, or ULID): `event::<source-id>::2026-05-21T14:32:18` or `event::01HXKZ7M8YQNT9N5J2VCABCDEF`. See `keys.md` and `time-series-and-ttl.md`.

**Spot it by:** any keying convention that starts with a date or timestamp.

## The "embedded list that grows forever" mistake

```json
{
  "id": "user::42",
  "email": "alice@example.com",
  "audit_log": [
    { "event": "login", "ts": "2024-..." },
    { "event": "login", "ts": "2024-..." },
    ... 10,000 entries ...
  ]
}
```

**Why it's wrong:** Each new audit event = rewriting the entire user document. Document size grows unbounded. Reading the user means deserializing the entire audit log.

**Fix:** Audit events are their own documents in a separate collection. Use Pattern B or Pattern C from `document-shape.md`. See `time-series-and-ttl.md` for retention.

**Spot it by:** any field name like `history`, `log`, `events`, `audit_*`, `recent_*` on a long-lived parent document.

## The "denormalize without an update plan" mistake

```json
{
  "id": "order::ORD-00837",
  "customer_name": "Alice Smith",      ← copied from user::42
  "customer_tier": "gold",              ← also copied
  "product_name": "Widget Pro",         ← copied from product::sku-12345
  "product_category": "Widgets"         ← also copied
}
```

This is fine — until Alice changes her name or "Widget Pro" gets renamed. Now every order document with the old name is stale.

**Why it's wrong:** Denormalization without a refresh plan creates silent staleness.

**Fix:** Either:
1. Accept the staleness as correct (order docs SHOULD show name-at-order-time)
2. Build an Eventing function that updates dependent docs when source changes
3. Don't denormalize; do the join at read time

**Spot it by:** any field whose source-of-truth lives in a different document, with no documented update mechanism.

## The "no version field" mistake

```json
{ "name": "Alice", "email": "alice@example.com" }
```

A year later you decide every user needs a `tier` field. Existing documents don't have it.

**Why it's wrong:** Code can't safely assume the field exists. Defaulting in code works, but you lose visibility into which records have been migrated.

**Fix:** Add a `_v` field from day one:

```json
{ "_v": 1, "name": "Alice", "email": "alice@example.com" }
```

When you migrate: `_v: 2, name, email, tier`. Code reads `_v`, applies migrations if needed, writes back.

**Spot it by:** the absence of any version/schema indicator in the document.

## The "primary index as a substitute for thinking" mistake

```sql
CREATE PRIMARY INDEX ON `mybucket`.`_default`.`mycollection`;
```

**Why it's wrong:** Primary indexes scan EVERYTHING for every query. They make slow queries possible but not fast. They're expensive to maintain (every write updates the index). The query service uses them as fallback when no other index matches — masking the underlying problem.

**Fix:** Create secondary indexes for the actual query patterns. Use `get_index_advisor_recommendations` to get suggestions for a specific query. See `couchbase-query-optimizer` for tuning guidance.

**Spot it by:** `PrimaryScan` in `explain_sql_plus_plus_query` output, or the user describing query performance as "OK but uses primary index."

## The "no thought given to read-vs-write ratio" mistake

A model designed purely for write-side cleanliness:

```json
{ "id": "user::42", "email": "alice@example.com" }
{ "id": "preferences::42", "user_id": 42, "theme": "dark", ... }
{ "id": "settings::42", "user_id": 42, "notifications": {...}, ... }
{ "id": "profile::42", "user_id": 42, "bio": "...", ... }
```

Looks clean. Every display of "the user" requires 4 KV reads.

**Why it's wrong:** Reads are typically 10-1000x writes. Optimizing writes at the cost of reads is usually backwards.

**Fix:** If these are read together >80% of the time, embed them: one user document with sub-objects. If their write patterns differ enough to warrant separation, keep them apart but consider a denormalized summary doc.

**Spot it by:** asking "to show the user's homepage, how many docs do we read?" If the answer is > 3 and they're always read together, the model is over-split.

## The "schema by accident" mistake

The application writes whatever fields it has at write time, no schema. Over years, the collection accumulates 47 distinct field shapes, including misspellings (`email`, `e_mail`, `emial`).

**Why it's wrong:** Queries that filter by a field miss records that have a differently-spelled version. Schema drift is invisible until something breaks.

**Fix:** 
- Document the intended schema (even informally — a markdown file in the repo works)
- Use `get_schema_for_collection` periodically to find drift
- Standardize at the application layer (a validator before write)

**Spot it by:** the user not being able to answer "what fields does this collection have?"

## The "scope per user" mistake (B2C)

```
Scope: user_42
  Collection: data
Scope: user_43
  Collection: data
... millions of scopes
```

**Why it's wrong:** Scopes have overhead. Hundreds of scopes per bucket are fine. Millions are not.

**Fix:** For B2C scale, use a single scope with user IDs in the key prefix or in a `user_id` field. Per-user access control via prefix-based roles.

**Spot it by:** "I'll just give each user their own scope."

## The "no TTL on session data" mistake

```json
{ "id": "session::abc123", "user_id": 42, "started": "..." }
```

No TTL. Session data accumulates forever.

**Why it's wrong:** Sessions are temporary by definition. Without TTL, the collection grows unbounded and you eventually have to delete-by-query, which is expensive.

**Fix:** Set TTL at write time (`expiry: 3600`) or default it at the collection level. See `time-series-and-ttl.md`.

**Spot it by:** any collection named `sessions`, `temp_*`, `cache_*` without a documented expiry mechanism.

## The "ID is also the email" mistake

```
Key: alice@example.com
```

**Why it's wrong:** Emails change. When Alice gets married and changes her email, the key has to change → delete + insert + update every reference.

**Fix:** Use a stable opaque ID (UUID, ULID, or sequence) as the key. Store the email as a field with a unique index for lookup-by-email.

**Spot it by:** any keying convention that uses a user-facing identifier directly.

## Quick "is this model OK?" checklist

When the user proposes a model, walk through:

- [ ] No document has an unbounded array
- [ ] No key contains mutable state
- [ ] No timestamp is the leading component of a high-rate key
- [ ] Type discrimination is in the key prefix or in the collection name
- [ ] Documents read together are stored together (or denormalized intentionally)
- [ ] Documents that change at very different rates are separated
- [ ] A version field exists for future migration
- [ ] Session/temporary data has a TTL
- [ ] Read-vs-write ratio was considered, not just write cleanliness
- [ ] Boundaries (bucket / scope / collection) reflect lifecycle differences, not just topic differences

If any check fails, point it out to the user and explain the consequence.
