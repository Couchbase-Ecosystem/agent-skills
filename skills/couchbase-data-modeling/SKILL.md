---
name: couchbase-data-modeling
description: >-
  Design document models, choose document boundaries, and pick access patterns for
  Couchbase — grounded in real cluster data via the MCP server. Use whenever the user
  asks about document model, schema design, key design, document shape, embed vs
  reference, denormalization, scope vs collection vs bucket, modeling for query / index
  / FTS / vector search, time-series in Couchbase, TTL strategies, anti-patterns,
  migrating from SQL / MongoDB / DynamoDB / DocumentDB, or general 'how should I
  structure this data.' Also use when the user wants to create or seed a new collection
  or bucket (advise on document and key design first, then create and seed it with
  explicit approval). Does NOT do GSI/query-index tuning or "why is my query slow"
  (use couchbase-query-optimizer); does NOT write queries (use
  couchbase-natural-language-querying). Requires the Couchbase MCP server for
  verification.
license: Apache-2.0
---

# Couchbase Data Modeling

Design what to put in Couchbase and ground recommendations in the real cluster. Guiding tenet: **data that is accessed together should be stored together** — but in Couchbase a *reference* is resolved by a cheap **KV `GET` by key**, so referencing is often cheaper than it is elsewhere.

> **Read to verify; writes need approval.** Inspect freely (read-only). Any write or DDL — including creating or seeding a collection — requires explicit user approval, and is blocked by the MCP server's read-only default anyway.

## When this skill applies

Use this skill whenever the conversation is about *what shape the data should take*, not *what tool to call*. Concrete signals:

- "How should I model X in Couchbase?"
- "Should I embed this or use references?"
- "What's the right key format?"
- "Bucket vs scope vs collection?"
- "I'm coming from [MongoDB / Postgres / DynamoDB] — how do I think about this?"
- "How do I model time-series / events / logs?"
- "Where do I put the embedding vector?"
- "Schema migration in Couchbase?"
- "Create a collection / seed some documents"

## Pick the right reference

| Question | Read |
|---|---|
| "What should my keys look like?" | `references/keys.md` |
| "Should I embed or reference?" / "How big should one document be?" | `references/document-shape.md` |
| "Bucket vs scope vs collection?" | `references/boundaries.md` |
| "How do I model for fast queries / FTS / vector search?" | `references/access-patterns.md` |
| "Time-series, event logs, anything with timestamps and TTL" | `references/time-series-and-ttl.md` |
| "I think I'm doing something wrong" | `references/anti-patterns.md` |
| "I'm coming from a relational DB" | `references/migration-from-relational.md` |
| "Field naming, MISSING/NULL semantics, Sync Gateway caveats" | `references/fields-and-conventions.md` |

Each reference is self-contained with a decision tree at the end.

## Step 0 — Confirm the connection (pre-flight)

This skill can advise without a live cluster, but before your **first cluster tool call** (verification in Step 6, or any create/seed in Step 7) verify connectivity once — so a missing connection fails fast and clearly instead of surfacing as a slow timeout deep in a data call:

1. Call `get_server_configuration_status` — it returns server status and `connections.cluster_connected` **without opening a connection** (instant, no timeout).
2. If it isn't already connected, call `test_cluster_connection` **once**. It returns a structured `{status, message}` rather than throwing a long `UnambiguousTimeoutException`.
3. If the cluster isn't reachable (`status: "error"` / not connected), **stop — do not retry cluster tools.** Tell the user the MCP server is installed but not connected, then hand off to **`couchbase-mcp-setup`** to configure the connection string and credentials.
4. Continue only once the connection is confirmed.

## The five-question design pass

Before reaching for any reference, walk the user through these five questions. The answers determine which references matter and which patterns apply:

1. **What does the application read most often?** Read patterns drive denormalization. The data you fetch together should live together.
2. **What changes together?** Write patterns drive document boundaries. Things that change together should be in the same document, OR separate documents with a transactional update path.
3. **What's the unit of access?** A document is the atomic unit in Couchbase. If you frequently need a subset of a "document," it's probably actually multiple documents.
4. **What's the lifespan?** Permanent data, session data with TTL, time-series with rolling windows — these belong in different collections or even buckets.
5. **What's the worst-case query?** The slowest legitimate query in your workload defines your indexing strategy and possibly your modeling choices.

Don't skip this pass even on "simple" cases. The most common modeling failure is jumping to "I'll just put it all in one document" before thinking about (1) and (4).

## Three core principles

**Principle 1 — Model the read, not the write.**
If you fetch user + their last 10 orders together 95% of the time, embed (or denormalize) the orders. The 5% write cost is worth the 95% read win. The opposite is also true: if you write to orders 100× per read of user+orders, separate them so you're not rewriting the user doc on every order.

**Principle 2 — A document is the atomic unit.**
Couchbase guarantees atomicity at the document level (KV ops) or across multiple documents only via Couchbase transactions (slower than KV ops). If two things MUST stay consistent, either put them in one document or accept the transaction overhead.

**Principle 3 — Boundaries are about lifecycle, not topic.**
Use buckets for fundamentally different lifecycles (different backup schedules, different TTL behavior, different access patterns). Use scopes for multi-tenant or multi-environment separation. Use collections for type-grouped documents within a tenant. See `references/boundaries.md`.

## Common shapes to recognize

The user is often describing one of these shapes without knowing the canonical name:

| User says | Pattern name | Reference |
|---|---|---|
| "Each user has a list of orders" | One-to-many (embed vs reference) | `document-shape.md` |
| "Each order has line items" | Nested aggregate | `document-shape.md` |
| "Users follow other users" | Many-to-many | `document-shape.md` |
| "I want to query by [field X]" | Index-friendly modeling | `access-patterns.md` |
| "Search across descriptions / text" | FTS modeling | `access-patterns.md` |
| "Semantic search over docs" | Vector modeling | `access-patterns.md` |
| "Log entries / metrics / events" | Time-series | `time-series-and-ttl.md` |
| "Session data that expires" | TTL-bounded | `time-series-and-ttl.md` |
| "User profiles with versioned history" | Versioned aggregate | `document-shape.md` |

## Step 1 — Assess the situation

New design? Migration (from a relational/normalized schema)? A performance problem caused by schema? Relationship modeling? Document-key design? This routes the rest. Coming from a relational DB → [`references/migration-from-relational.md`](references/migration-from-relational.md) (concept/feature mapping, strategy ladder, re-model-don't-translate).

## Step 2 — Apply the fundamentals

"Accessed together → stored together"; **embed vs reference** by cardinality + access pattern (references = KV `GET` by key); the **20 MB** hard document limit (aim well under ~1 MB); and the **schema-validation reality** — Couchbase has no server-side `$jsonSchema`, so validation is app-level or via the Eventing service. → [`references/document-shape.md`](references/document-shape.md). For field-level shape — naming gotchas (N1QL reserved words, hyphens), `MISSING`/`NULL`/`VALUED` semantics, metadata fields + the Sync Gateway `_`-prefix caveat, and byte-trimming at scale → [`references/fields-and-conventions.md`](references/fields-and-conventions.md).

## Step 3 — Spot antipatterns

Unnecessary buckets/scopes/collections; excessive SQL++ JOINs (denormalize); oversized documents / unbounded arrays; redundant GSIs. → [`references/anti-patterns.md`](references/anti-patterns.md).

## Step 4 — Design document keys & placement (Couchbase-specific)

Unlike auto-generated IDs, Couchbase keys are designer-chosen and central: naming conventions, composite/natural keys (`tenant::user::123`), counter keys, and KV-first access. Decide bucket vs scope vs collection placement. → [`references/keys.md`](references/keys.md).

## Step 5 — Recommend a pattern

Match the schema shape to the library: approximation, computed, extended-reference, outlier, polymorphic, schema-versioning, document-versioning, attribute, archive, bucketing/grouping, time-series. → [`references/document-shape.md`](references/document-shape.md) for structural patterns; [`references/access-patterns.md`](references/access-patterns.md) for query/FTS/vector patterns; [`references/time-series-and-ttl.md`](references/time-series-and-ttl.md) for time-series and TTL.

## Step 6 — Verify with real data (read-only MCP)

Ground the advice: `get_schema_for_collection` (INFER) for structure; `run_sql_plus_plus_query` with **`ENCODED_SIZE(doc)`** for document sizes and **`ARRAY_LENGTH(arr)`** for array bounds; `list_indexes` for index usage.

## Step 7 — Writes require approval

Present migrations/restructurings as recommendations. Before any write, **summarize the exact operation** (target keyspace, estimated documents affected) and get an explicit "yes". Couchbase has no create-collection MCP tool: create a collection/scope with `CREATE COLLECTION`/`CREATE SCOPE` DDL via `run_sql_plus_plus_query`, and seed documents with `insert_document_by_id` (or `INSERT`). Writes and DDL run only with `CB_MCP_READ_ONLY_MODE=false`; otherwise output the statements for the user to run. Re-measure after any change.

## What this skill won't help with

- **GSI/query-index tuning and "why is my query slow"** — use `couchbase-query-optimizer`.
- **Writing queries** — use `couchbase-natural-language-querying`.
- **Connection setup** — if the MCP server isn't connected, hand off to `couchbase-mcp-setup`.
- **Application code** — modeling is database-side; how your app code consumes the model is out of scope here.

Hand off explicitly when a conversation crosses these lines.

## References

- [`references/keys.md`](references/keys.md) — key strategies, naming, hot-shard avoidance, composite/natural keys, counter keys.
- [`references/document-shape.md`](references/document-shape.md) — embed vs reference (cardinality + decision rules), 20 MB sizing, denormalization patterns, versioning.
- [`references/boundaries.md`](references/boundaries.md) — bucket vs scope vs collection decisions, multi-tenancy, hot/cold/archive patterns.
- [`references/access-patterns.md`](references/access-patterns.md) — index-friendly modeling, covering indexes, FTS modeling, vector search, pre-aggregation.
- [`references/time-series-and-ttl.md`](references/time-series-and-ttl.md) — time-series modeling, TTL strategies (per-doc, per-collection, collection rotation), aggregation.
- [`references/anti-patterns.md`](references/anti-patterns.md) — modeling-smell catalog + "is this model OK?" review checklist.
- [`references/migration-from-relational.md`](references/migration-from-relational.md) — RDBMS→Couchbase concept/feature mapping, strategy ladder, slice-by-slice migration.
- [`references/fields-and-conventions.md`](references/fields-and-conventions.md) — JSON state semantics (`MISSING`/`NULL`/`VALUED`), field-naming gotchas, metadata fields + Sync Gateway caveat, type discrimination, byte-trimming tricks.
