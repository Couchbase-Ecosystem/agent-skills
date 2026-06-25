# Boundaries — bucket vs scope vs collection

Couchbase has three levels of container: bucket → scope → collection. Picking the right level for each separation is one of the most consequential modeling decisions because it determines memory allocation, access control, replication, indexing scope, and backup granularity.

## What each boundary actually controls

### Bucket — the unit of memory and operations

- Has its own RAM quota — buckets compete for memory but don't share
- Has its own replica count
- Has its own eviction policy (valueOnly vs fullEviction)
- Has its own bucket type (couchbase / ephemeral / memcached)
- Is the unit of XDCR replication (you replicate a bucket, not a scope or collection)
- Is the unit of backup (typically — backup tools can filter but bucket is the primary boundary)
- Is the unit of cross-cluster reference: a bucket on cluster A can be different from a bucket of the same name on cluster B

A node can serve ~10 buckets reasonably; more than that and memory overhead starts to dominate. Plan for 1-5 buckets in most clusters.

### Scope — the unit of logical separation

- Lives inside a bucket
- Has no independent memory quota (memory is bucket-level)
- Is the unit of multi-tenancy isolation: per-tenant scopes give per-tenant access control
- Is the unit of N1QL query default: `SELECT * FROM users` in scope X resolves to `bucket.X.users`
- Indexes can be scope-scoped (an index in scope A can't see data in scope B)

Default scope is `_default`. You can have hundreds of scopes per bucket reasonably.

### Collection — the unit of grouping

- Lives inside a scope
- Has no independent memory quota
- Maps roughly to "a table" in relational thinking
- Can have a per-collection TTL (documents in collection A auto-expire after N seconds; collection B doesn't)
- Can have per-collection history retention (8.x feature)
- Indexes are collection-scoped: a `CREATE INDEX` on collection A only indexes A's documents

Default collection is `_default`. You can have hundreds of collections per scope reasonably.

## The 3-question framework

Three questions decide whether two things go in the same bucket, the same scope, or the same collection:

1. **Do they need the same memory budget and replica strategy?** If no → different buckets.
2. **Do they need the same access control and indexing scope?** If no → different scopes.
3. **Do they need the same lifecycle (TTL, history retention)?** If no → different collections.

If all three are "yes," they belong in the same collection.

## Common patterns

### Pattern: Single-app, multi-domain

A typical web app with users, products, orders, and reviews.

```
Bucket: app_data           (single RAM budget, single backup, single replica policy)
  Scope: _default
    Collection: users
    Collection: products
    Collection: orders
    Collection: reviews
```

All four collections share memory but are logically separated for indexing and access control. Each can have its own TTL if relevant (sessions in a separate collection from durable user records).

### Pattern: Multi-tenant SaaS

```
Bucket: tenants            (one bucket for all tenant data)
  Scope: tenant_001
    Collection: users
    Collection: orders
  Scope: tenant_002
    Collection: users
    Collection: orders
  Scope: tenant_003
    ...
```

Each tenant gets a scope. Per-tenant access control via roles like `data_reader[tenants:tenant_001:*]`. Queries are scope-scoped so tenant data doesn't leak.

**Alternative:** Bucket-per-tenant if tenants have wildly different sizes or need different SLAs. Cost: bucket overhead per tenant, plus you can only have ~10 buckets per node.

### Pattern: Hot / cold / archive

```
Bucket: hot                (RAM-heavy, fast nodes, replica=2)
  Scope: _default
    Collection: active_sessions   (TTL = 3600)
    Collection: live_orders

Bucket: cold               (disk-heavy, slower nodes, replica=1)
  Scope: _default
    Collection: completed_orders
    Collection: historical_events
```

Different buckets because the memory/disk/replica tradeoffs are fundamentally different.

### Pattern: Mixed-workload single tenant

```
Bucket: app_data
  Scope: operational
    Collection: users
    Collection: orders
  Scope: analytics
    Collection: aggregates    (TTL = 86400, rebuilt daily)
    Collection: events
```

Separating analytical from operational at the scope level lets you put analytical indexes on the `analytics` scope without polluting the operational query plans. Same bucket, same memory budget, but logical isolation.

### Pattern: Time-series

```
Bucket: timeseries
  Scope: metrics
    Collection: metrics_2026_05   (TTL or manual drop after 90 days)
    Collection: metrics_2026_04   (current month)
    Collection: metrics_2026_03
```

Collection-per-month gives you the ability to drop an entire collection when its retention window expires (faster than per-doc deletion). See `time-series-and-ttl.md` for the full pattern.

## When NOT to use scopes

Scopes were added in Couchbase 7.0. Pre-7.0 code and tools often don't understand them. If you're integrating with older clients, scopes can cause friction. For most modern setups this isn't an issue, but check your SDK versions.

Also: don't use scopes purely for namespacing of completely unrelated data. That's what buckets are for. Scope is for "same memory budget, different access boundary."

## When NOT to use collections

If everything in a "would-be collection" has identical TTL and is queried alongside everything else in the bucket, you don't strictly need separate collections. They add a layer of indirection.

That said: the cost is low. Collections cost essentially nothing structurally; they make future re-organization easier. Default to using them for type separation unless you have a specific reason not to.

## Migration: moving between boundaries

These moves are painful — design carefully up front to avoid them.

**Moving from single collection to multiple collections** (most common):
1. Create the new collections
2. Run an Eventing function or external script that copies documents to their right collection based on a discriminator
3. Update application reads to query the new collections
4. Update application writes to target the new collections
5. Drop the old collection

**Moving from single bucket to multiple buckets** (much harder):
- Different memory budgets means you need to provision more cluster capacity first
- XDCR can be used to mirror data while you cut over
- Plan downtime or read-only periods for the cutover

## Anti-patterns

- **One scope per user** in a B2C app — scopes are heavyweight enough that this doesn't scale. Per-tenant in B2B/SaaS = yes; per-user in B2C = no
- **Hundreds of buckets** — bucket count has overhead; large counts hurt cluster stability. Use scopes for fine-grained separation
- **Using `_default` for everything** — works fine but loses you per-collection TTL and access control. Default to named collections even for single-collection use cases
- **Putting unrelated data in the same collection just because "it's all small"** — small now isn't small later, and untangling co-mingled data is hard

## Quick decision tree

- **Two things need different RAM/replica/eviction config?** → different buckets
- **Two things need different access control or different indexing scope?** → different scopes
- **Two things need different TTL or different history retention?** → different collections
- **Multi-tenant SaaS?** → scope per tenant (until tenants get big enough to need their own bucket)
- **Time-series with retention windows?** → collection per time partition
- **Mixed operational + analytical workload?** → scope-level separation, same bucket
