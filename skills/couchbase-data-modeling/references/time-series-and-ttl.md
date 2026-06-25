# Time-series and TTL

Workloads dominated by time-stamped writes — metrics, events, logs, sessions, IoT data, audit trails — have their own modeling patterns. Couchbase is not a dedicated time-series database, but with the right model it handles time-series workloads competently up to ~hundreds of millions of points per day per cluster.

## What makes time-series workloads different

- **Write-heavy:** typically 95%+ writes
- **Append-only or near-append-only:** existing data rarely changes
- **Time-windowed queries:** "last 24 hours of metrics for node X"
- **Retention-bounded:** old data has declining value; eventually it's deleted
- **Aggregate-friendly:** the user typically wants downsampled views, not raw points

Modeling for these workloads requires thinking about: key design (to avoid hot shards), document granularity (one-point-per-doc vs bucketed), TTL strategy (per-doc vs collection-rotation), and aggregation strategy (read-time vs precomputed).

## Key design for time-series

The naive key — `metric::cpu::2026-05-21T14:32:18.473Z` — works at low write rates but fails at scale: all writes within the same millisecond hash near the same vBucket → hot shard.

**Pattern: high-entropy prefix**

```
metric::<hash-of-source>::cpu::<timestamp>
```

The source (node, host, sensor ID) provides natural entropy. As long as you have many concurrent sources, the hash distributes evenly.

**Pattern: ULID-based keys**

```
metric::cpu::01HXKZ7M8YQNT9N5J2VCABCDEF
```

ULIDs are time-sortable AND have built-in randomness. The first chunk is the timestamp; the rest is entropy. Best of both worlds.

**Pattern: bucket-stable keys for downsampled summaries**

```
metric_minute::cpu::node-7::2026-05-21T14:32  (one doc per minute per source)
metric_hour::cpu::node-7::2026-05-21T14      (one doc per hour per source)
```

These are bigger windows, so the write rate per key is naturally lower and hot-sharding is less of a concern.

## Document granularity: per-point vs bucketed

The single biggest sizing decision in time-series modeling.

### Pattern A — One document per data point

```json
// metric::cpu::node-7::2026-05-21T14:32:18.473Z
{ "metric": "cpu", "node": "node-7", "ts": "2026-05-21T14:32:18.473Z", "value": 0.73 }
```

**Pros:**
- Simple model, easy to reason about
- Per-point access via direct KV
- Per-point TTL is straightforward

**Cons:**
- Massive document count (1 metric × 10 nodes × 1 point/sec = 864K docs/day per metric)
- High per-document overhead (metadata, key storage)
- Storage cost dominated by overhead, not data

Use Pattern A when: write rates are modest (< 1K/sec total) and per-point access is needed.

### Pattern B — Time-bucketed documents

```json
// metric::cpu::node-7::2026-05-21T14:32
{
  "metric": "cpu",
  "node": "node-7",
  "bucket_start": "2026-05-21T14:32:00Z",
  "bucket_end": "2026-05-21T14:32:59Z",
  "points": [
    { "ts": "...:00.123Z", "value": 0.71 },
    { "ts": "...:01.045Z", "value": 0.73 },
    ...
  ],
  "count": 60,
  "min": 0.69, "max": 0.81, "avg": 0.74   // optional pre-aggregates
}
```

One document per minute per metric per node. 60 points become one doc.

**Pros:**
- 60× fewer documents (or whatever your bucket size is)
- Pre-aggregates available without scanning
- Better RAM utilization (fewer keys in memory)

**Cons:**
- Append within bucket = read-modify-write (use `cb_mutate_in` with array_append to mitigate)
- Bucket boundaries are arbitrary — queries spanning a boundary need to read 2 docs
- More complex code

Use Pattern B when: write rate is high (> 1K/sec) and per-point access isn't needed.

### The bucket size question

Pick the smallest bucket that satisfies your reads without exceeding ~1 MB per document:

- 1-minute buckets for second-resolution metrics with retention < 7 days
- 1-hour buckets for second-resolution metrics with retention 1-30 days
- 1-day buckets for minute-resolution metrics with retention up to a year

Math: at 1 point per second with ~100 bytes per point, a 1-hour bucket is 360 KB — fine. A 1-day bucket would be 8.6 MB — exceeds the practical limit, won't work.

## TTL strategies

Three approaches, in increasing order of operational sophistication.

### Strategy 1 — Per-document TTL

Set TTL at write time via the SDK or `cb_upsert` with `expiry` argument:

```json
{
  "tool": "cb_upsert",
  "arguments": {
    "id": "session::42::abc123",
    "value": {...},
    "expiry": 3600   // seconds
  }
}
```

The document auto-deletes at `now + 3600 seconds`. Couchbase handles cleanup as a background process.

**Use for:** sessions, short-lived caches, rate-limit counters — anything with a known short lifespan set at write time.

**Limit:** per-doc TTL adds overhead. At very high write rates with very short TTLs, the expiry-cleaner can fall behind.

### Strategy 2 — Per-collection TTL

A collection can have a default TTL applied to all writes:

```
admin_collection_settings_set with maxTTL = 86400  (24h)
```

Now every write to that collection gets a 24-hour TTL unless overridden at write time.

**Use for:** ephemeral collections like `sessions`, `temp_data`, where everything in the collection has the same lifecycle.

### Strategy 3 — Collection rotation

For long-running time-series with month-scale retention, neither per-doc nor per-collection TTL is efficient — the cluster spends real CPU expiring billions of docs.

Better: rotate collections by time window.

```
metrics_2026_05    (current month — writes go here)
metrics_2026_04    (previous month — reads only)
metrics_2026_03    (2 months ago — reads only)
metrics_2026_02    (3 months ago — about to drop)
```

On the first of each month: create the new collection, point writes at it, drop the oldest. Collection-level drop is essentially instant compared to per-doc deletion of millions of items.

Application code needs to know which collection(s) to query for a given time range. Typical: maintain a small config doc mapping time ranges to collections.

**Use for:** anything with retention > 30 days and steady write rate.

## Aggregation strategies

### Pattern: query-time aggregation

```sql
SELECT date_trunc('hour', ts) AS hour, AVG(value)
FROM metrics
WHERE metric = 'cpu' AND node = 'node-7' AND ts >= '...' AND ts < '...'
GROUP BY date_trunc('hour', ts);
```

Simple, flexible. Slow on millions of points. Fine for ad-hoc analysis; bad for dashboards refreshing every 10 seconds.

### Pattern: pre-aggregated bucket documents

Store hour-level and day-level summary docs alongside the raw points:

```
metric_minute::cpu::node-7::2026-05-21T14:32     { raw points + min/max/avg/count }
metric_hour::cpu::node-7::2026-05-21T14          { aggregated from minutes }
metric_day::cpu::node-7::2026-05-21              { aggregated from hours }
```

Maintained via Eventing function triggered on minute-doc writes, or via a periodic batch job.

Query at the right granularity: dashboards over the last hour use minute docs; reports over the last week use hour docs; quarterly trends use day docs.

### Pattern: downsample-then-discard

After computing hour and day aggregates, optionally delete the raw minute docs to save storage. Keep aggregates indefinitely (cheap, small).

## Events / audit logs

Audit logs are time-series with different requirements:

- Per-event-doc model (Pattern A) because per-event access matters (for an investigation)
- Long retention (months to years for compliance)
- Indexable by event type, user, target resource

Model:

```json
// event::login::user_42::01HXKZ7M8YQNT9N5J2VCABCDEF
{
  "type": "login",
  "user_id": 42,
  "ts": "2026-05-21T14:32:18.473Z",
  "ip": "10.0.0.42",
  "user_agent": "...",
  "success": true
}
```

Indexes:
- `CREATE INDEX ix_event_user ON events(user_id, ts)` — "all events for user X in time range"
- `CREATE INDEX ix_event_type ON events(type, ts)` — "all login events in time range"

Use Strategy 3 (collection rotation) for the actual retention, because you'll be retaining millions of these.

## IoT-specific patterns

If devices report telemetry at high rate, every device should produce its own key prefix to avoid hot-sharding:

```
telemetry::<device_id>::<bucket_start_ts>
```

If you have 10K devices each reporting once per second, that's 10K writes/sec spread across 10K distinct keys → naturally balanced.

For per-device queries, the key prefix makes the query trivially efficient via `LIKE 'telemetry::device_42::%'` patterns.

For cross-device queries (e.g., "what was the average temperature across all devices in the last hour?"), maintain a pre-aggregated summary collection updated by Eventing or batch.

## Anti-patterns

- **One document per metric type that grows forever** (`metric::cpu` with all CPU points ever appended to it) — write hot spot, exceeds size limit quickly
- **Sequential timestamps as full key** — guaranteed hot-sharding
- **Per-doc TTL on millions of high-rate docs** — expiry cleanup falls behind; use collection rotation
- **No retention strategy** — disk fills, ops gets paged
- **Indexing every field of every event doc** — index bloat. Index only the fields you query

## Quick decision tree

- **Low write rate, per-point access needed?** → Pattern A (per-point docs), per-doc TTL
- **High write rate, no per-point access?** → Pattern B (bucketed docs), collection-level TTL or rotation
- **Retention > 30 days at steady write rate?** → Collection rotation strategy
- **Need dashboards over recent data?** → Pre-aggregated minute / hour / day summary docs
- **Need ad-hoc analytical queries?** → Couchbase Analytics service (doesn't impact OLTP)
- **IoT with many sources?** → Per-device key prefix for natural sharding
- **Audit / compliance logs?** → Per-event docs, secondary indexes by user/type/resource, collection rotation
