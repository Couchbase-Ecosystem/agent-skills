# Field shape & conventions (Couchbase-specific)

How to shape values, name fields, and trim bytes — the non-obvious parts.

- [JSON state semantics](#json-state-semantics)
- [Field naming gotchas](#field-naming-gotchas)
- [Metadata fields & the Sync Gateway caveat](#metadata-fields--the-sync-gateway-caveat)
- [Type discrimination](#type-discrimination)
- [Size-optimization tricks](#size-optimization-tricks)

## JSON state semantics

SQL++ distinguishes **four** states of a field — predicates an LLM often forgets exist:

| State | Doc looks like | Predicate |
|-------|----------------|-----------|
| **Valued** (has a non-empty value) | `{"geo": "US"}` | `geo IS VALUED` |
| **Empty** (present, zero-length) | `{"geo": ""}` | `geo IS NOT VALUED` |
| **Missing** (key absent) | `{}` | `geo IS [NOT] MISSING` |
| **Null** (explicit null) | `{"geo": null}` | `geo IS [NOT] NULL` |

`MISSING` ≠ `NULL` ≠ `""`. Use `IFMISSING()`, `IFNULL()`, `IFMISSINGORNULL()` to coalesce. **Best practice: omit a property entirely rather than store `null`/`""`** — SQL++ handles missing fields cleanly and you save bytes. This is what makes "just start writing a new field" work: old docs simply have it `MISSING`.

## Field naming gotchas

- **Avoid N1QL reserved words** as field names: `user`, `bucket`, `cluster`, `role`, `select`, `insert`, `type`(ok but careful), … — if used, they must be backtick-escaped in every query (`` `user` ``).
- **Avoid hyphens** in field names — `first-name` needs backtick-escaping; use `firstName` or `first_name`. Stick to letters/numbers/underscore.
- **Plural for arrays, singular for objects/scalars:** `phones: [...]`, `address: {...}`, `genre: "..."`. Model a field as an **array if it could ever hold more than one** value (even if it holds one today) — object→array is a breaking shape change later.
- **Pick one case convention** (`camelCase` *or* `snake_case`) and hold it — schema-by-accident starts with `email` / `e_mail` / `emial`.
- **Brevity matters at scale:** field names are stored in every document. `geo` vs `countryCode` × 1B docs is real RAM/disk. Don't sacrifice readability for trivial counts, but trim verbose names on huge collections.

## Metadata fields & the Sync Gateway caveat

Common convention — a small set of housekeeping fields:

```jsonc
{ "type": "user", "schemaVersion": 2,           // type discriminator + schema evolution
  "createdAt": 1544734688923, "updatedAt": 1544759124478 }   // epoch ms (see size tricks)
```

Some teams prefix these with `_` (`_type`, `_schema`, `_created`) to group them. **Caveat:** if you use **Couchbase Mobile / Sync Gateway**, avoid **leading-underscore properties at the document root** — the v1.0 replication protocol rejects root `_`-prefixed fields. Nest them under a non-`_` object (e.g. `meta: { type, schema, created }`) if mobile sync is in play.

## Type discrimination

- With **named collections**, the collection *is* the type — you usually **don't** need a `type` field or `WHERE type = '…'`; indexes are collection-scoped automatically.
- A `type` field (or **key prefix**) matters mainly when multiple types share the `_default` collection, or for XDCR/Eventing filtering. Keep the discriminator **flat at the root** (`{"type":"track", ...}`), not wrapped (`{"track": {...}}`) — flat indexes smaller and queries simpler.

## Size-optimization tricks

Only worth it at scale; the payoff is bytes × document-count. Example: 500M docs × 2 timestamps × 11 B ≈ **11 GB** saved.

| Trick | Before → after | Saving |
|-------|----------------|--------|
| Timestamps as **epoch**, not ISO-8601 | `"2018-12-14T03:45:24.478Z"` (24 B) → `1544759124478` (13 B) | ~11 B each |
| Drop epoch precision you don't need | ÷1000 = s (10 B) · ÷60000 = min (8 B) · ÷3.6M = hr (6 B) | a few B each |
| **Strip dashes** from GUIDs | `3f5a8b2c-7d8e-…` → `3f5a8b2c7d8e…` | 4 B each |
| **Drop** null / empty / default-valued fields | `{"x": null}` → omit | whole field |
| Don't store the **doc key inside the body** | the key *is* the access path; only store it if you query it via `META().id` | whole field |
| Don't repeat a **non-unique value across array elements** | hoist the constant to a top-level field | per element |
| Shorter field names on huge collections | `countryCode` → `geo` | per doc |

Trade-off: epoch timestamps and stripped GUIDs are less human-readable — fine for high-volume machine data, skip for low-volume docs you debug by eye. (The guide also notes a time-component array `[Y, M, D, h, m, s]` as a grouping-friendly date form; for genuine time-series prefer Couchbase 7.2+ time-series — see [`patterns.md`](patterns.md).)
