---
name: couchbase-data-modeling
description: >-
  Design and review Couchbase JSON data models: embedding vs referencing,
  document-key design, the bucket/scope/collection hierarchy, document sizing,
  and the design-pattern library — grounded in real data via the MCP server. Use
  when the user asks to design a data model, "embed vs reference", choose
  document keys, do a schema review, model one-to-many / polymorphic / multi-tenant
  data, handle unbounded arrays or TTL/archive/time-series, or migrate a
  relational/Mongo schema to Couchbase. Does NOT do GSI/query-index tuning or
  "why is my query slow" (use couchbase-query-optimizer); does NOT write queries
  (use couchbase-natural-language-querying). Requires the Couchbase MCP server
  for verification.
license: Apache-2.0
metadata:
  version: "0.1.0"
allowed-tools: mcp__couchbase__*
---

# Couchbase Data Modeling

Guide Couchbase JSON data modeling and ground recommendations in the real cluster. Guiding tenet: **data that is accessed together should be stored together** — but in Couchbase a *reference* is resolved by a cheap **KV `GET` by key**, so referencing is often cheaper than it is elsewhere.

> **Read to verify; writes need approval.** Inspect freely (read-only). Any migration write or DDL requires explicit user approval — and is blocked by the MCP server's read-only default anyway.

## Step 1 — Assess the situation
New design? Migration (from relational/Mongo)? A performance problem caused by schema? Relationship modeling? Document-key design? This routes the rest.

## Step 2 — Apply the fundamentals
"Accessed together → stored together"; **embed vs reference** by cardinality + access pattern (references = KV `GET` by key); the **20 MB** document limit (keep documents small); and the **schema-validation reality** — Couchbase has no server-side `$jsonSchema`, so validation is app-level or via the Eventing service. → [`references/fundamentals.md`](references/fundamentals.md).

## Step 3 — Spot antipatterns
Unnecessary buckets/scopes/collections; excessive SQL++ JOINs (denormalize); oversized documents / unbounded arrays; redundant GSIs. → [`references/antipatterns.md`](references/antipatterns.md).

## Step 4 — Design document keys & placement (Couchbase-specific)
Unlike auto-generated `_id`s, Couchbase keys are designer-chosen and central: naming conventions, composite/natural keys (`tenant::user::123`), counter keys, and KV-first access. Decide bucket vs scope vs collection placement. → [`references/document-keys.md`](references/document-keys.md).

## Step 5 — Recommend a pattern
Match the schema shape to the library: approximation, computed, extended-reference, outlier, polymorphic, schema-versioning, document-versioning, attribute, archive, **bucketing/grouping**, time-series. → [`references/patterns.md`](references/patterns.md).

## Step 6 — Verify with real data (read-only MCP)
Ground the advice: `get_schema_for_collection` (INFER) for structure; `run_sql_plus_plus_query` with **`ENCODED_SIZE(doc)`** for document sizes and **`ARRAY_LENGTH(arr)`** for array bounds; `list_indexes` for index usage.

## Step 7 — Changes require approval
Present migrations/restructurings as recommendations. Execute a write or DDL only after explicit user "yes" (and only if write mode is enabled). Re-measure after any change.

## Scope

- **In:** document structure, embed vs reference, keys, bucket/scope/collection placement, sizing, schema-validation strategy, the pattern library, schema migrations.
- **Out (hand off):** GSI/query-index tuning and "why is my query slow" → `couchbase-query-optimizer`; writing queries → `couchbase-natural-language-querying`.

## References

- [`references/fundamentals.md`](references/fundamentals.md) — document model + KV-first, 20 MB sizing, embed vs reference, schema-validation reality.
- [`references/antipatterns.md`](references/antipatterns.md) — unnecessary buckets/scopes/collections, excessive JOINs, redundant GSIs.
- [`references/document-keys.md`](references/document-keys.md) — key naming, composite/counter keys, KV-first access, keyspace placement.
- [`references/patterns.md`](references/patterns.md) — the design-pattern library.
