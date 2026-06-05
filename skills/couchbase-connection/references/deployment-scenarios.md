# Connection settings by deployment context

Canonical knob names (casing varies per SDK). Defaults: `connectTimeout` 10s, `kvTimeout` 2.5s, `queryTimeout`/`searchTimeout`/`analyticsTimeout`/`managementTimeout` 75s. Tune *from* these — don't set values blindly.

## Serverless / Functions (Lambda, Cloud Functions)

The dominant cost is connection setup on cold starts, so the goal is to **avoid reconnecting**.

- **Initialize the `Cluster` outside the handler** (module/global scope) and reuse it across warm invocations. Connecting inside the handler reconnects every call (~50–500 ms each) and leaks connections.
- Apply the **`wan_development`** config profile (functions usually talk to Capella over a WAN).
- Keep timeouts modest so a failed call fails fast rather than holding the invocation open; size them above your real p99 operation latency.
- If cold-start latency matters, warm the connection (a cheap KV/ping op) at module load.

## OLTP / KV-heavy services

Low-latency point operations from a long-running process.

- **One long-lived `Cluster`** for the process lifetime.
- Default `kvTimeout` (2.5s) is usually right; only raise it if you have evidence of legitimately slow ops.
- For high concurrency, raise **`numKvConnections`** (more KV sockets per node) rather than creating more `Cluster`s.
- Use durability deliberately (see below) — durable writes add latency.

## OLAP / Analytical

Long-running SQL++ Query or Analytics workloads.

- **Raise `queryTimeout` / `analyticsTimeout`** well above the 75s default — analytical jobs can legitimately run for minutes.
- Consider a **separate `Cluster`** (or environment) for analytical work so long timeouts don't bleed into latency-sensitive OLTP paths.
- Stream/iterate large result sets rather than materializing them.

## High-traffic / bursty

High request rates with spikes.

- **Exactly one shared `Cluster`** — never create one per request. Per-request `Cluster` creation is the most common cause of connection storms and timeouts under load.
- Raise **`numKvConnections`** (KV) and **`maxHttpConnections`** (Query/Search/management) to give bursts more concurrent capacity.
- Watch **timeout counts and orphaned-response reports** under load (see `monitoring.md`); rising orphans/timeouts signal undersized connections or an overloaded cluster.

## Durability (write-path knob)

Tune per write, not globally: `none` (fastest) → `majority` → `majorityAndPersistToActive` → `persistToMajority` (safest, slowest). Higher durability adds latency and needs an adequate durable-write timeout. Use stronger levels only for writes that require it.

## Connection string & profile reminders

- `couchbase://` = local/non-TLS; `couchbases://` = Capella/TLS (required for Capella).
- Apply `wan_development` for any cloud/remote target to avoid spurious timeouts from WAN latency.
