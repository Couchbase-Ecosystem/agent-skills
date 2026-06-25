# Key design

Couchbase's document key is the primary access path. Get this wrong and everything else suffers — bad keys mean hot shards, slow lookups, and migration pain. Get it right and the rest of the modeling is easier.

## What a Couchbase key is and isn't

A key is:
- A string up to 250 bytes
- Unique within a collection (NOT within a bucket — same key in different collections is fine)
- The fastest possible lookup path (`cb_get` by key is sub-millisecond on hot data)
- Permanent: changing a key means delete + insert; references to the old key break

A key is NOT:
- A primary index entry (that's separate; the key IS the access path for KV ops)
- A searchable / queryable field unless you also store it in the document body
- An auto-generated number unless you choose that pattern

## Three key strategies

### Strategy 1 — Natural keys

Use a domain identifier the application already has: email, ISBN, SKU, UUID-from-elsewhere, customer-ID-from-CRM.

```
user::alice@example.com
book::9780201633610
order::ORD-2026-05-21-00837
```

**When this works:** the identifier is stable (won't change), unique, and meaningfully addressable from the app.

**When it doesn't:** the identifier can change (emails are notoriously unstable), is too long, or doesn't exist yet at write time.

### Strategy 2 — Composite keys

Combine multiple fields into one key with a separator:

```
session::user_42::2026-05-21
metric::cpu::node-7::2026-05-21T14:00
order::user_42::ORD-00837
```

The separator `::` is conventional. Underscores or pipes also work — pick one and use it consistently.

**When this works:** you frequently want to scan a key range (`session::user_42::*`), and the separator lets you do that via `cb_query` with a `LIKE` predicate or via key-pattern iteration.

**When it doesn't:** any component of the key is mutable. If `user_42` becomes `user_43`, every dependent key has to be rewritten.

### Strategy 3 — Generated IDs

Use a UUID or a sequence:

```
3f5a8b2c-7d8e-4f1a-9c3b-1e8f6d7a2b9c    (UUIDv4)
01HXKZ7M8YQNT9N5J2VCABCDEF              (ULID — sortable!)
```

**When this works:** you don't have a stable natural key, you want to avoid hot-shard issues, OR you want collision-proof IDs from multiple clients without coordination.

**When it doesn't:** debugging — opaque IDs are unfriendly. Mitigate by prefixing: `user::3f5a8b2c-...`.

**ULID over UUIDv4:** ULIDs are lexicographically sortable by creation time. If you ever want "give me the most recent N keys," ULIDs let you do it via key scan; UUIDv4s don't.

## The hot-shard problem

Couchbase hashes the key to determine which vBucket it lives in, and vBuckets distribute across nodes. **Predictable, sequential keys can cluster writes onto one vBucket / node.**

Bad: `user::1`, `user::2`, `user::3`, `user::4`, ... sequential auto-increment

This is fine for low write rates, but at 10K+ writes/sec the hashing still produces a roughly even distribution because the input strings differ enough. The real hot-shard problem appears with:

Worst: timestamps as the LEADING key component: `2026-05-21::*` — every write within a millisecond hashes near the same place.

**Mitigation patterns:**

- Add high-entropy prefix to time-based keys: `<hash-of-user>::2026-05-21::event_id` instead of `2026-05-21::user_42::event_id`
- Use ULIDs (entropy is built in)
- Use random UUIDs (maximally random, less debuggable)

## Key length tradeoffs

Couchbase stores the key in memory for every active document. A 50-byte key vs a 200-byte key on a billion documents = 150 GB of difference.

| Key length | When acceptable |
|---|---|
| < 50 bytes | Default target. Most natural and composite keys fit here |
| 50-100 bytes | OK for moderate document counts (< 100M) |
| 100-200 bytes | Justified by debuggability/readability requirements |
| > 200 bytes | Only if there's no alternative. At 250 bytes hard limit |

If keys are getting long, consider:
- Hash the long parts: `user::<sha256(email).hex()[:16]>` instead of full email
- Drop redundant prefixes if the collection already disambiguates (`user::42` becomes `42` if it's in the `users` collection)

## Prefix conventions

A common pattern that aids debugging without adding much length:

```
<type>::<id>
<type>::<subtype>::<id>
```

Examples:
- `user::42`
- `order::ORD-00837`
- `event::login::user_42::2026-05-21T14:32:00`

This is purely convention — Couchbase doesn't care. But it makes log lines, monitoring queries, and ad-hoc investigation MUCH easier. The 5-byte cost of `user::` is worth the operability win.

## Counters: when you need monotonically-increasing IDs

If the app needs `order::1`, `order::2`, `order::3`, ... use Couchbase's atomic counter:

```json
{
  "tool": "cb_mutate_in",
  "arguments": {
    "id": "counter::orders",
    "specs": [{"op": "increment", "path": "value", "value": 1}]
  }
}
```

This is atomic across all writers — no race condition. Use the returned value as your new ID.

**Caveat:** the counter document becomes a write hot spot. If you have very high creation rates (>10K/sec), shard the counter into N counter documents and pick one randomly per insert; recombine when reading max.

For most workloads, a single counter is fine. ULIDs avoid the hot spot entirely if you don't need strict monotonic ordering.

## Anti-patterns

- **Mutable field as part of key**: don't put `status` or `current_owner` in the key — these change, and changing them means a delete + insert plus updating every reference
- **Putting the entire document key into the document body verbatim**: redundant. The key IS the access path. Store it in the body only if you need to query by it via N1QL using `META().id`
- **Using `:` (single colon) as separator**: ambiguous with URLs and other systems. `::` is the convention; stick with it
- **Encoding business meaning in key length**: short keys for "important" docs and long for "less important" — confuses the next person

## Quick decision tree

- **Have a stable natural identifier?** → use it: `<type>::<id>`
- **Need collision-proof generated ID, want sortability?** → ULID with type prefix
- **Need pure random ID?** → UUIDv4 with type prefix
- **Need scannable groupings?** → composite key: `<type>::<group>::<id>`
- **Need monotonically increasing IDs?** → atomic counter via `cb_mutate_in` increment
- **Worried about hot shards?** → high-entropy prefix or ULID, never timestamp-as-leading-component
