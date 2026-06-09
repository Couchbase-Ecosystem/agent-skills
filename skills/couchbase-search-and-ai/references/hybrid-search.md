# Hybrid search

Hybrid search combines **keyword precision** (FTS) with **semantic recall** (vector) in one request — strong for RAG retrieval and "search that just works." Requires Couchbase **7.6+**.

## One index, both modalities

Define a **single Search index** that maps both:
- the **text field(s)** with analyzers (as in `full-text-search.md`), and
- a **vector field** with its `dimension` + similarity metric (as in `vector-search.md`),
- optionally **geo**/scalar fields for filtering.

Using the `Search` vector index type keeps semantic + keyword in the same index so one query can use both.

## Query: knn + text, weighted

A hybrid query combines a `knn` (vector) clause with a text query in the same Search request and **weights** the contributions, so results ranked highly by *both* meaning and keywords float to the top. Conceptually:
- a text `match`/`disjuncts` clause over the analyzed fields, plus
- a `knn` clause over the vector field with the query embedding and `k`,
- with per-component **weights** (and optional pre-filters).

Tune the weights per query (e.g. lean more semantic for vague queries, more lexical for exact terms).

## Fusion differs from MongoDB

MongoDB's `$rankFusion` uses a fixed reciprocal-rank-fusion constant. Couchbase combines the lexical and vector contributions with **adjustable weighting** rather than a fixed RRF constant — so you control the balance directly per query instead of relying on a fixed formula.

## When to use

Reach for hybrid when pure keyword misses paraphrases and pure vector returns topically-close-but-wrong matches — e.g. product/site search and RAG retrieval where both exact terms and meaning matter. For purely keyword needs use FTS; for purely conceptual needs use vector.
