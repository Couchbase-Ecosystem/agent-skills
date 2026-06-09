# Full-text (lexical) search

Couchbase full-text search is provided by the **Search Service** (FTS) via a Search index, then queried from SQL++ with `SEARCH()` (or the Search SDK).

## Define the index (Capella UI / Search REST API)

The MCP server can't create this — provide the JSON for the user to create in **Search → Add Index** (Capella UI) or `PUT /api/index/<name>` (Search REST API). Shape:
- **Source:** the bucket.
- **Type mappings:** map the target scope/collection and the fields to index, each with a **type** (`text`, `keyword`, `number`, `datetime`, `geopoint`) and an **analyzer**.
- **Analyzers:** `standard` (tokenize + lowercase + stopwords — the usual choice for prose), `keyword` (index the whole value, for exact/faceting), or a **language analyzer** (stemming, e.g. `en`).
- Set `store`/`include in _all` as needed for highlighting/scoring.

## Query with `SEARCH()`

```sql
SELECT h.name, SEARCH_SCORE() AS score
FROM `travel-sample`.inventory.hotel AS h
WHERE SEARCH(h, {"match": "beachfront", "field": "description"})
ORDER BY score DESC
LIMIT 10;
```

Query types (inside the `SEARCH()` object):
- `match` — analyzed term match (the default for prose).
- `match_phrase` — ordered phrase.
- `prefix` — autocomplete / starts-with.
- `fuzzy` (with `fuzziness`) — typo tolerance.
- `wildcard` / `regexp` — pattern match *within the FTS index* (still indexed, unlike SQL++ `LIKE`).
- `conjuncts` / `disjuncts` — boolean AND/OR of sub-queries.
- `numeric`/`date` range, `geo` distance/bounding-box.

Use `SEARCH_SCORE()` for relevance ordering and `SEARCH_META()` for score/highlight metadata. Faceting and result highlighting are configured on the search request.

## Don't use `LIKE` / `REGEXP` for search

SQL++ `LIKE '%term%'` / `REGEXP_*` have **no relevance scoring, no fuzzy matching, and no language-aware tokenization**, and a leading wildcard can't use an index. For any relevance/fuzzy/text-search need, use `SEARCH()` against an FTS index. (A pure prefix filter `LIKE 'term%'` on structured data can still be a plain query — that's `couchbase-natural-language-querying`'s job.)
