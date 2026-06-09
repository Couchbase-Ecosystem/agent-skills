---
name: couchbase-search-and-ai
description: >-
  Build full-text (lexical), vector (semantic), and hybrid search on Couchbase's
  Search Service. Use when the user wants keyword / fuzzy / autocomplete / faceted
  search, semantic similarity / embeddings / "find similar" / RAG, or a combined
  hybrid approach — or asks for relevance-ranked text matching ("contains",
  "search for", "like X"). Helps choose the search type, define the Search index,
  construct SQL++ SEARCH()/vector queries, and run them. Does NOT do exact-match
  or structured filtering (use couchbase-natural-language-querying), or GSI /
  query tuning (use couchbase-query-optimizer). Requires the Couchbase MCP server.
license: Apache-2.0
metadata:
  version: "0.1.0"
allowed-tools: mcp__couchbase__*
---

# Couchbase Search & AI

Build **full-text**, **vector**, and **hybrid** search on the Couchbase **Search Service**.

> **MCP scope (important).** The MCP server can **run** Search queries (SQL++ `SEARCH()` / `APPROX_VECTOR_DISTANCE()`) but **cannot create or inspect Search indexes** (`list_indexes` is GSI-only). So **index creation is instructional**: emit the index JSON and have the user create it in the **Capella UI** or via the **Search REST API**. Query construction and execution are grounded via the MCP server.

> **Never use `LIKE` / `REGEXP` for search.** They have no relevance scoring, no fuzzy matching, and no language-aware tokenization, and a leading-wildcard `LIKE '%x%'` can't use an index. Use the Search Service and explain why.

## Step 1 — Discovery
Inspect the keyspace and sample docs (`get_schema_for_collection`, a small `SELECT`). Ask: what are they searching, which field(s), what match type (exact / fuzzy / semantic), what filters, and is autocomplete needed? (You can't enumerate existing Search indexes via MCP — ask the user or point them to the UI.)

## Step 2 — Determine the search type
- **Lexical (full-text)** — keywords, phrases, fuzzy/typo tolerance, autocomplete, faceting. → [`references/full-text-search.md`](references/full-text-search.md)
- **Vector (semantic)** — similarity, embeddings, "find similar", RAG. → [`references/vector-search.md`](references/vector-search.md)
- **Hybrid** — keyword precision + semantic recall together. → [`references/hybrid-search.md`](references/hybrid-search.md)

## Step 3 — Version-gate
**Vector and hybrid search require Couchbase 7.6+.** Confirm via `get_cluster_health_and_services` or by asking. If unmet, don't proceed — recommend upgrading. (FTS is broadly available.)

## Step 4 — Define the Search index (instructional)
Produce the index definition JSON: for FTS, type mappings + analyzers on the target fields; for vector, the vector field with its **dimension** (matching the embedding model) and **similarity metric** (`l2_norm` / `dot_product` / `cosine`), and the right **index type** (Hyperscale / Composite / Search). Tell the user to create it in the **Capella UI** or via the **Search REST API** — the MCP server can't create it.

## Step 5 — Construct the query
- FTS → SQL++ `SEARCH()` with the right query type (match / match_phrase / prefix / fuzzy / wildcard).
- Vector → `APPROX_VECTOR_DISTANCE()` in `ORDER BY … LIMIT k` (or the Search SDK `knn`).
- Hybrid → one Search query mixing `knn` + text, with weights.

## Step 6 — Run it read-only & refine
If the index exists, run the query via `run_sql_plus_plus_query` (read-only) and iterate on results/relevance. If the index isn't created yet, hand over the index JSON + the query and instruct the user to create the index first.

## Scope

- **In:** choosing a search type, defining FTS/vector/hybrid indexes (as JSON), constructing and running `SEARCH()`/vector queries, relevance tuning, RAG retrieval.
- **Out (hand off):** exact-match / structured filtering → `couchbase-natural-language-querying`; GSI / query performance tuning → `couchbase-query-optimizer`.

## References

- [`references/full-text-search.md`](references/full-text-search.md) — FTS index JSON, analyzers, `SEARCH()` query types, faceting/scoring.
- [`references/vector-search.md`](references/vector-search.md) — vector index (dimension/metric/type), `APPROX_VECTOR_DISTANCE`, quantization, the RAG pipeline.
- [`references/hybrid-search.md`](references/hybrid-search.md) — combining vector + text (+ geo) in one index, weighting.
