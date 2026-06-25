# Document shape — embed vs reference, denormalization, sizing

The single hardest call in document modeling: when to embed data inside a parent document vs when to store it as a separate document with a reference. This reference walks through the decision framework, the patterns, and the limits.

## The four-question test

When deciding whether to embed B inside A or keep them separate, answer these in order:

1. **Read together?** If you fetch A and B together >80% of the time, embedding wins. The read is one KV op instead of two.
2. **Write together?** If updating B requires also reading A's current state, embedding makes the update atomic. Otherwise, you'll need a transaction (slower) or accept brief inconsistency.
3. **Size at maturity?** Estimate the worst-case size of an A with all its embedded Bs over the document's lifetime. If that exceeds ~1 MB, embedding starts hurting (memory, network, write amplification).
4. **Update frequency mismatch?** If B changes 100× per update of A, embedding means rewriting A 100× more than necessary. Separate them.

Embed when 1 and 2 are yes AND 3 and 4 are no. Reference when 3 or 4 are yes regardless of 1 and 2.

The trap: people often answer 1 (read together) optimistically and forget about 3 and 4. A user's "list of orders" sounds embeddable until you realize the user might have 50,000 orders over a decade.

## Document size limits and targets

- **Hard limit:** 20 MB per document (Couchbase enforces this)
- **Practical target:** keep documents under 1 MB
- **Sweet spot:** 1 KB to 100 KB

Why the practical limit matters:
- Every read pulls the entire document over the network (no partial reads unless you use `cb_lookup_in`)
- Every write replicates the entire document to replicas (and across XDCR if configured)
- Memory pressure: hot documents stay in RAM; big hot documents waste a lot of RAM
- JSON parsing cost: 10 MB of JSON is slow to deserialize on every read

If documents are growing toward 1 MB, that's the signal to split.

## The "is this one document or many" test

A useful mental check: **would a reasonable application ever need ONLY a subset of this document's fields?**

If yes, those fields are probably their own document. Examples:

- `user` doc with `recent_purchases: [...50 items]` — if the app ever shows a profile without the purchase list, the purchases should be separate documents (or a separate "user_summary" doc).
- `order` doc with `customer_full_record: {...}` — if you ever update customer info, you don't want to rewrite every order. Customer is a reference.

If no — every field is accessed every time — embedding is correct.

## Patterns by relationship cardinality

### One-to-one

Almost always embed. If two things have a 1:1 relationship and the same lifecycle, they're one document.

Exception: privacy / access control. If half of a user's data is PII (legal, financial) and the other half is public (profile, preferences), splitting along the access boundary may be worth it for compliance — the PII doc gets stricter audit and read-only roles for most readers.

### One-to-few (bounded N, small)

Embed as an array. Example: `user.addresses: [...up to ~10]`, `product.variants: [...up to ~20]`.

The threshold for "few" is the size at maturity (#3 above). If the array can grow to >100 items, treat as one-to-many.

### One-to-many (unbounded N)

Don't embed. Use one of these patterns:

**Pattern A — Parent + child documents with type prefix:**

```
user::42                            { name, email, ... }
user_order::42::ORD-00837           { product, qty, ... }
user_order::42::ORD-00838           { product, qty, ... }
```

Fetch all orders for user 42 via `cb_query` with `WHERE META().id LIKE 'user_order::42::%'`. Faster than a secondary index if the dataset is hot.

**Pattern B — Index by parent ID:**

```
user::42                            { name, email, ... }
order::ORD-00837                    { user_id: 42, product, qty, ... }
order::ORD-00838                    { user_id: 42, product, qty, ... }
```

With a `CREATE INDEX ix_orders_user ON orders(user_id)`, you can `SELECT * FROM orders WHERE user_id = 42` efficiently. More flexible (orders are addressable by their own ID, not bound to the user's key).

Use Pattern A when orders are conceptually "part of" the user and rarely accessed independently. Use Pattern B when orders have their own lifecycle and are queried in many ways (by date range, by product, by status).

### Many-to-many

Don't embed both sides. Three sub-patterns:

**Pattern X — Bridge documents:** the classic relational join-table approach, ported.

```
follow::user_42::user_99       { followed_at: "..." }
follow::user_99::user_42       { followed_at: "..." }
```

Query "who does user 42 follow?" via `LIKE 'follow::user_42::%'` or via a secondary index on `follower_id`.

**Pattern Y — Embed IDs on both sides** (when N is small on at least one side):

```
user::42      { name, ..., following_ids: [99, 103, 207] }
user::99      { name, ..., followers_ids: [42, 88, 199] }
```

Caveats: keeping both sides in sync is the application's job (or use a transaction). And if `following_ids` can grow unbounded, you're back to the one-to-many problem.

**Pattern Z — Asymmetric: embed one side, reference the other.** When one side is bounded and the other isn't.

```
user::42      { name, ..., following_ids: [99, 103, 207] }   // following is "who I picked", capped
user::99      { name, ... }                                   // no followers list — query computed via index
```

Pick `Y` for small-and-bounded both ways, `Z` for asymmetric, `X` otherwise.

## Denormalization patterns

Denormalization means: store the same data in multiple places to make reads faster, at the cost of having to update it in multiple places.

### Pattern: cached summary

```
user::42 { name, ..., recent_orders_summary: { count: 837, total_spent: 12943.21, last_order: "2026-05-21" } }
order::ORD-00837 { user_id: 42, ..., total: 142.10 }
```

Reading a user gets you the summary "for free." Maintaining it requires updating user::42 every time an order is created — typically done via an Eventing function, or accepting it'll be slightly stale and recompute periodically.

**When this is correct:** the summary is read 100× more often than orders are created.

### Pattern: copy of source-of-truth field

```
order::ORD-00837 { customer_name: "Alice Smith", customer_id: 42, ... }
```

Even though `customer_name` lives on `user::42`, copying it into the order means displaying an order list doesn't require N user lookups.

**Cost:** when Alice changes her name, every order doc needs updating. Either accept the staleness (orders show the name at order time, which is often correct anyway) or use Eventing to update.

### Pattern: per-relationship copy

Highest write cost, lowest read cost. Each user has a per-user view of every other user. Almost never the right answer; included for completeness.

## Versioning patterns

When the application schema changes, what happens to existing documents?

**Pattern: version field + read-time migration**

```
user::42 { _v: 3, name, email, preferences: {...} }
```

Code reads the document, sees `_v: 1`, applies migrations 1→2 and 2→3, writes back. No big-bang migration; documents migrate as they're touched.

**Pattern: bulk migration via Eventing**

For changes that ALL documents need (new required field, etc.), an Eventing function iterating the collection is cleaner than waiting for read-time migrations to cover everything.

**Pattern: parallel versions during transition**

Big shape changes: write both old and new shape for the transition window, switch readers to new, decommission old. Highest cost but lowest risk.

## Anti-patterns

- **One giant document per tenant** — appealing simplicity, ruins performance. The first time you have a tenant with 50K records, the tenant doc becomes a write bottleneck
- **Deeply nested arrays of arrays of arrays** — every read pays the deserialize cost; queries can't easily target inner elements; updates are awkward
- **Documents that grow forever** (logs appended to a user doc, comments on a post embedded as array) — split into separate documents addressed by composite keys or queried via index
- **No type discrimination** — if multiple "types" of documents share a collection without any `type` field or key prefix, you can't query for "all orders" without scanning everything

## Quick decision tree

- **1:1 relationship, same lifecycle?** → embed
- **1:few (bounded < ~50)?** → embed as array
- **1:many (unbounded)?** → separate documents, link via key prefix or secondary index
- **Many:many?** → bridge documents or asymmetric embed
- **Field is read with parent 95%+ of the time AND doesn't change independently?** → embed/denormalize
- **Document approaching 1 MB?** → split
- **Schema evolving?** → version field + migrate on read, or Eventing for bulk
