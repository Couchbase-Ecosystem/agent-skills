# Vector (semantic) search

Couchbase Vector Search (Search Service, **7.6+**) finds documents whose embedding is nearest a query embedding. Define a vector index, then query with SQL++ `APPROX_VECTOR_DISTANCE()` (or the Search SDK `knn`).

## Define the vector index (Capella UI / Search REST API)

The MCP server can't create this — provide the JSON for the user. Key settings on the vector field:
- **`dimension`** — must match the embedding model exactly (e.g. 1536 for `text-embedding-3-small`).
- **similarity metric** — `cosine` (general, handles non-normalized vectors), `dot_product` (fast; needs unit-length vectors), or `l2_norm` (Euclidean).
- **quantization** — trades storage/recall for accuracy (none → scalar → binary); use when the index is large.
- Index any scalar fields you'll **pre-filter** on alongside the vector.

**Choose the index type:**
- **Hyperscale** — billion-scale datasets.
- **Composite** — high-speed filtered search (vector + scalar predicates).
- **Search** — when you also want keyword/hybrid in the same index.

## Query

```sql
SELECT h.name,
       APPROX_VECTOR_DISTANCE(h.embedding, $queryVector, "cosine") AS dist
FROM `travel-sample`.inventory.hotel AS h
WHERE h.country = "France"                 -- pre-filter narrows candidates
ORDER BY dist
LIMIT 5;                                    -- k nearest
```

- Order by the distance and `LIMIT k` to get the k nearest. **Pre-filter** with `WHERE` (or filters inside the search request) to scope candidates.
- ANN is approximate — tune the candidate/`nprobes` setting for the recall-vs-latency trade-off; use exact search for small sets or baselines.

## RAG pipeline

The retrieval half of RAG: **chunk** documents → **embed** each chunk with your model → **store** the chunk + its vector in Couchbase → **retrieve** the top-k by vector search at query time → **augment** the LLM prompt with the retrieved chunks. Couchbase Vector Search integrates with **LangChain** and **LlamaIndex** as a vector store. Keep the embedding model (and its `dimension`/metric) consistent between indexing and querying.
