# Monitoring a Couchbase connection

Couchbase SDKs do **not** expose a client-side connection pool with checkout-queue events (no "wait queue size", no "checkout failed"). Connections are persistent and multiplexed, so you diagnose connection health from **operation behavior and SDK telemetry**, not pool counters.

## What to watch (and what it means)

| Signal | Where | What it tells you |
|--------|-------|-------------------|
| **Operation latency percentiles** (p50/p99) | SDK metrics (Micrometer / OpenTelemetry) | Rising p99 → cluster pressure, undersized connections, or WAN latency |
| **Timeout counts** (`*Timeout` exceptions) by service | App logs / metrics | Sustained timeouts → timeouts set too low for the workload, or the cluster is overloaded |
| **Orphaned-response reports** | SDK orphan-response logger | Responses arriving after the op already timed out → timeouts too tight or server too slow; a leading indicator before user-visible timeouts |
| **Threshold (slow-op) logs** | SDK threshold logging | Periodic summaries of the slowest ops per service — turn this on first |
| **Reconnection / retry events** | SDK logs | Frequent reconnects → network instability or per-request `Cluster` creation |

## Enable SDK telemetry

- **Threshold logging** (slow-operation reporting) — usually on by default; ensure it's surfaced in your logs. It's the cheapest, highest-signal first step.
- **Orphaned-response reporting** — surfaces responses that arrived too late; watch the count trend.
- **Request tracing / metrics** — export via Micrometer or OpenTelemetry to your existing dashboards for latency percentiles and per-service counts.

## Diagnose connectivity with `sdk-doctor`

`sdk-doctor` is Couchbase's standalone diagnostic tool. Point it at the connection string + credentials to validate DNS, TLS, port reachability (KV 11210/11207, Query 8093/18093, management 8091/18091), and bucket access **independently of your app** — useful for isolating whether a problem is your connection config vs. the network/cluster.

## Capella

Use the **Capella metrics** dashboards for the cluster-side view (per-node ops/sec, memory/quota, queue depths, request latency). Pair cluster-side metrics with the SDK-side signals above: SDK timeouts + healthy cluster metrics usually means a client-side config issue (timeouts, `Cluster` reuse, `wan_development`); SDK timeouts + saturated cluster metrics means the cluster needs attention.

## Reading the signals together

- Timeouts/orphans rising while cluster metrics look healthy → **client-side**: timeouts too low, missing `wan_development`, or per-request `Cluster` creation.
- Latency rising on both sides → **cluster pressure**: scale or optimize the workload (see `couchbase-query-optimizer`).
- Frequent reconnects → network instability, or you're creating `Cluster`s per request (fix the lifecycle first).
