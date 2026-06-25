# Access patterns — modeling for query, FTS, and vector search

The single biggest lever for query performance isn't index choice — it's document shape. A query that fits the document's natural structure runs orders of magnitude faster than one that fights it. This reference covers how to model documents so the queries you actually run are fast.

## The fundamental tradeoff

You have three knobs that trade against each other:

1. **Read speed** — how fast a typical query returns
2. **Write speed / cost** — how expensive each write is (more denormalization = more places to update)
3. **Storage** — how much disk/memory the data takes (denormalization = duplication)

You don't get to optimize all three. Pick two; accept the third.

For most apps, the right answer is: **optimize reads, accept some write cost, accept some storage cost.** Reads dominate by 10-1000x in typical workloads.

## Modeling for SQL++ (N1QL) queries

### Index-friendly document shape

If you'll filter by a field, the field should be:

1. **At a stable path** — don't bury it under varying object structures. `user.tier` is good; `user.attributes[where name='tier'].value` is awful
2. **At the top level when possible** — `tier: "gold"` queries faster than `details.tier: "gold"` because index entries are smaller
3. **Consistently typed** — `age: 42` (number) vs `age: "42"` (string) breaks indexes

### Covering indexes

When `explain_sql_plus_plus_query` shows a `Fetch` operator after an `IndexScan`, the index doesn't cover the query — meaning the query had to fetch the full document just to read fields beyond the indexed ones.

Cover the query by indexing all fields in the SELECT and WHERE:

```sql
CREATE INDEX ix_user_tier_cover ON users(tier, name, email);
SELECT name, email FROM users WHERE tier = 'gold';  -- now covered
```

Document shape implication: keep fields you commonly project together near each other in your mental model so it's natural to include them in the same index.

### Composite predicates

If you frequently filter by A AND B, a composite index `ON collection(A, B)` is much faster than separate indexes on A and B.

Document shape implication: when you know two fields will always be queried together, make sure both are flat top-level fields (not nested inside different sub-objects).

### Array indexes

If a document has an array and you query by elements of that array:

```json
{ "id": "user::42", "tags": ["premium", "early-access", "us-west"] }
```

```sql
CREATE INDEX ix_user_tags ON users(DISTINCT ARRAY t FOR t IN tags END);
SELECT * FROM users WHERE ANY t IN tags SATISFIES t = "premium" END;
```

Cost: array indexes are larger and slower to update than scalar indexes. Use only if you'll actually query by array contents.

Document shape implication: design arrays for query frequency. Frequently-queried arrays should be flat (`tags: ["a", "b"]`), not array-of-objects (`tags: [{name: "a"}, {name: "b"}]`).

## Modeling for FTS (Full-Text Search)

FTS is for: free-form text matching, fuzzy matching, phrase queries, faceted search. NOT for: exact-match or range queries (use N1QL).

### Field design for FTS

- **Searchable text fields should be strings or arrays of strings**, not nested objects
- **Don't FTS-index every field** — pick the fields users actually search over
- **Use distinct fields for distinct purposes**: a `title` field separate from a `description` field lets you boost matches in the title

Example for a product catalog:

```json
{
  "name": "Pacific Northwest Cabernet 2020",
  "description": "Full-bodied red wine with notes of cherry...",
  "tags": ["red", "cabernet", "pacific northwest", "2020"],
  "tasting_notes": "cherry, oak, vanilla"
}
```

Index `name` and `description` as text with the standard analyzer; index `tags` as keyword (exact match, no tokenization); ignore `tasting_notes` for FTS if it's only for display.

### Analyzers and the multi-field pattern

The same field can be indexed multiple ways. Couchbase calls these "type mappings." For example, you might want `name`:
- Tokenized (so "Pacific" matches a search for "pacific")
- Lower-cased (so "pacific" matches "PACIFIC")
- And also keyword-indexed (so you can do exact-match facets like "show me all docs where name is exactly X")

Document shape implication: don't duplicate the field in the document just because you want multiple indexes on it. Use the FTS index's type mapping to handle multiple analyses of the same source field.

### Synonyms (8.x)

Couchbase 8.x supports declared synonym sets that the FTS index can reference. The synonym docs live in a regular collection. For modeling purposes:

- A synonym set is a separate document; don't denormalize synonyms into product documents
- Synonyms work for the entire FTS index, so design them at the index level (one synonym set per language / domain)

## Modeling for vector search

Couchbase 8.x adds vector indexes. The model: store the embedding vector as a field in the document, then create a vector index on that field.

### Where to put the embedding

```json
{
  "id": "product::sku-12345",
  "name": "Pacific Northwest Cabernet 2020",
  "description": "Full-bodied red wine...",
  "embedding": [0.012, -0.034, 0.156, ...]
}
```

The embedding is a top-level field, an array of floats. The vector index targets `embedding` by name.

### Embedding dimension

The dimension is set at index-create time and must match what the embedding model produces:
- OpenAI `text-embedding-3-small`: 1536
- OpenAI `text-embedding-3-large`: 3072 (or 1024 if you specify dimensions param)
- Voyage `voyage-3`: 1024
- Cohere `embed-english-v3.0`: 1024

Once the index is created, all documents must have embeddings of the same dimension. Insert with the wrong dimension = error.

### Embedding storage cost

A 1536-dim float32 embedding is 1536 × 4 bytes = 6144 bytes ≈ 6 KB per document. At 1M documents, that's 6 GB just for the embeddings. Plan storage accordingly.

If storage is a constraint, you can use lower-dimensional models or store embeddings only for documents that will actually be searched (skip embedding for archived docs).

### Hybrid retrieval pattern

Vector search alone is often not enough — you need to combine semantic similarity with hard filters. Two patterns:

**Pattern A — Pre-filter in N1QL, then vector rank:**

```sql
SELECT META().id, embedding FROM products WHERE category = 'wine' AND year > 2018;
```

Then compute similarity in the application code. Simple but doesn't scale well past ~10K candidate docs.

**Pattern B — Vector first, then re-filter:**

Use the vector index to get top-K most similar docs, then filter in N1QL by other predicates. Couchbase's hybrid scoring supports this via combined vector + scalar predicates in the search query.

Document shape implication: the scalar fields you'll filter by need to be top-level so they're index-friendly. Don't bury `category` under `metadata.classifications.category`.

### Multimodal embeddings

If a document has multiple things you want to search over (e.g., a product has a name embedding AND a description embedding AND a picture embedding), store each as a separate field and create a vector index per field:

```json
{
  "id": "product::sku-12345",
  "name_embedding": [...],         // index 1: vector search by name semantic
  "description_embedding": [...],  // index 2: vector search by description
  "image_embedding": [...]         // index 3: visual similarity
}
```

This is more storage but lets you search each modality independently or in combination.

## When to pre-aggregate

If a single read needs to combine many documents (e.g., "monthly sales totals" requires summing 100K orders), don't do that at read time. Pre-aggregate via:

- **Materialized summary documents** updated by Eventing functions
- **Periodic batch jobs** that compute aggregates and write summary docs
- **Couchbase Analytics service** for ad-hoc aggregation (doesn't impact OLTP)

Pre-aggregation is a denormalization pattern. See `document-shape.md` for the tradeoffs.

## Quick decision tree

- **Filter by exact value or range?** → N1QL with covering index; field needs to be top-level and stable-pathed
- **Free-form text search?** → FTS with appropriate analyzer; don't try to make N1QL do this
- **Semantic / similarity search?** → vector index on embedding field
- **"Find similar AND filter by tag"?** → hybrid: vector for similarity, scalar fields for filters
- **Need to aggregate many documents per read?** → pre-aggregate (Eventing, batch job, or Analytics)
- **Schema has fields that vary by record type?** → don't FTS or vector-index those; only index the stable fields
