---
name: couchbase-connection
description: >-
  Help a developer configure and tune their APPLICATION's Couchbase SDK
  connection — the long-lived Cluster object, per-service timeouts, IO settings,
  durability, and what to monitor — matched to their deployment (serverless,
  OLTP/KV, analytical, high-traffic). Use when a user asks how to set up or
  optimize their app's connection to Couchbase, sees connection timeouts or
  churn under load, or asks about Cluster lifecycle, the wan_development profile,
  or connection sizing. NOT for configuring the agent's MCP server connection —
  use couchbase-mcp-setup for that.
license: Apache-2.0
metadata:
  version: "0.1.0"
allowed-tools: Bash
---

# Couchbase Connection Tuning

Advisory skill: recommend how a developer's **application** should connect to Couchbase via the SDK, tuned to their workload. This is **language-agnostic** — give the principles and knob names (consistent across Couchbase SDKs); for exact per-language API/syntax, point to docs-search or the language's `server-connection-<lang>` skill rather than writing code here.

> **This is not the MCP server connection.** If the user is trying to connect *the agent* to Couchbase (set up `CB_*`, the MCP server won't connect), use **`couchbase-mcp-setup`** instead.

> **Couchbase is not a tunable client "pool."** It's one long-lived, multiplexed `Cluster` with per-service connections. The biggest wins come from **reusing a single `Cluster`** and **right-sizing per-service timeouts** for the workload — not from "pool sizing."

## Step 1 — Gather context (ask before recommending)

Don't give numbers until you know:
- **Deployment:** serverless/function (cold-start sensitive) vs. long-running service/container.
- **Workload:** KV/OLTP (low-latency point ops) vs. query/analytical (long-running SQL++/Analytics).
- **Concurrency / throughput** expected.
- **Where the cluster lives:** local/on-prem vs. **Capella / across a WAN** (latency matters).
- **Typical operation durations** (do any legitimately run long?).
- **SDK + Server/Capella version.**
- **Language** — only to route exact syntax to docs-search; not to write code here.

## Step 2 — Core principles (apply to every recommendation)

1. **One long-lived `Cluster` per process.** Initialize once at startup and reuse it for the app's lifetime. Creating a `Cluster` per request costs ~50–500 ms and leaks connections.
2. **Serverless:** initialize the `Cluster` **outside the handler** (module/global scope) so warm invocations reuse it; never connect per invocation.
3. **Capella / remote:** apply the **`wan_development`** connection config profile (raises timeouts for cloud latency) and use a `couchbases://` (TLS) connection string.

## Step 3 — Tune for the deployment context

Match settings to the workload (details, with values, in [`references/deployment-scenarios.md`](references/deployment-scenarios.md)):

| Context | Key adjustments |
|---------|-----------------|
| **Serverless / Lambda** | `Cluster` outside handler; `wan_development`; modest timeouts; consider warmup |
| **OLTP / KV-heavy** | one long-lived `Cluster`; default `kvTimeout` (2.5s) usually fine; raise `numKvConnections` for high concurrency |
| **OLAP / analytical** | raise `queryTimeout` / `analyticsTimeout` well above the 75s default (minutes if needed); consider a separate `Cluster` from OLTP |
| **High-traffic / bursty** | one shared `Cluster` (never per request); raise `numKvConnections` / `maxHttpConnections`; watch timeouts/orphans |

Knobs you'll reference: timeouts (`connectTimeout` 10s, `kvTimeout` 2.5s, `queryTimeout`/`searchTimeout`/`analyticsTimeout`/`managementTimeout` 75s), IO (`numKvConnections`, `maxHttpConnections`), durability level, and the `wan_development` profile. (Names shown in canonical form; casing varies per SDK.)

## Step 4 — Language-specific code

Give the **agnostic recommendation** — which knobs to set and to what values. For the **exact API/syntax** in the user's SDK, use docs-search or the couchbaselabs `server-connection-<language>` skill. **Do not fabricate detailed per-language code here** — the timeout/IO concepts are consistent across SDKs; only the API shape differs.

## Step 5 — Monitor and validate

Point to [`references/monitoring.md`](references/monitoring.md). In short: there are **no pool checkout-queue events** to watch (Couchbase multiplexes). Instead watch **operation-latency percentiles, timeout counts, orphaned-response reports, and reconnects**; enable **threshold (slow-op) logging**; run **`sdk-doctor`** for connectivity diagnosis; and use **Capella metrics** dashboards.

## Scope

- **In scope:** `Cluster` lifecycle, per-service timeouts, IO knobs, durability tuning, connection monitoring signals.
- **Out of scope (route elsewhere):** configuring the agent's MCP server (→ `couchbase-mcp-setup`); DNS/SRV resolution; TLS certificate setup; firewall/VPC/network reachability; Capella allowed-IP (→ `couchbase-mcp-setup`).

## References

- [`references/deployment-scenarios.md`](references/deployment-scenarios.md) — per-context settings with concrete Couchbase values.
- [`references/monitoring.md`](references/monitoring.md) — SDK health signals, `sdk-doctor`, Capella metrics.
