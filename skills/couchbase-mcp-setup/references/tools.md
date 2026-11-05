# MCP tool catalog

Exact tool names the server exposes (verified on v1.1.0 by listing tools over stdio; re-check with `get_server_configuration_status` after upgrading). Use these for verification, and for `CB_MCP_DISABLED_TOOLS` / `CB_MCP_CONFIRMATION_REQUIRED_TOOLS` lists (names must match exactly). `[W]` = write tool, not loaded when `CB_MCP_READ_ONLY_MODE=true` (the default, both in the bundled `mcp.json` and in the server itself). See [`safety.md`](safety.md).

- [Cluster health & diagnostics](#cluster-health--diagnostics) · use for verification
- [Schema discovery](#schema-discovery)
- [Scope & collection management](#scope--collection-management)
- [KV document ops](#kv-document-ops)
- [Query & indexing](#query--indexing)
- [Query performance analysis](#query-performance-analysis)
- [Search & vector search](#search--vector-search)

## Cluster health & diagnostics
| Tool | Does |
|------|------|
| `get_server_configuration_status` | MCP server status + config (read-only mode, loaded tools) |
| `test_cluster_connection` | Verify credentials by connecting |
| `get_cluster_health_and_services` | Cluster health + running services |
| `get_cluster_health_snapshot` | Per-node service topology, membership, orchestrator, and health in one call |
| `get_client_connectivity_report` | Whether the client's connections were already broken, and for how long |
| `get_cluster_metrics` | One or more cluster statistics over a historic time window |
| `get_cluster_tasks` | Tasks running now: rebalance, compaction, XDCR, index build |
| `get_cluster_system_events` | System event log: what changed on the cluster, and when |
| `get_bucket_config` | A bucket's configuration and live state (all buckets if `bucket_name` is omitted) |
| `discover_tool_input_values` | Exact input values another tool requires, from reference data bundled with the server |

## Schema discovery
| Tool | Does |
|------|------|
| `get_buckets_in_cluster` | List buckets |
| `get_scopes_in_bucket` | List scopes in a bucket |
| `get_collections_in_scope` | List collections in a scope |
| `get_scopes_and_collections_in_bucket` | List scopes + collections together |
| `get_schema_for_collection` | Infer document structure for a collection |

## Scope & collection management
| Tool | Does |
|------|------|
| `create_scope` `[W]` | Create a scope in a bucket |
| `create_collection` `[W]` | Create a collection in an existing scope |
| `delete_scope` `[W]` | Delete a scope from a bucket |
| `delete_collection` `[W]` | Delete a collection from a scope |

## KV document ops
| Tool | Does |
|------|------|
| `get_document_by_id` | Fetch a document by ID |
| `lookup_subdocument` | Read parts of a document without fetching the whole thing |
| `upsert_document_by_id` `[W]` | Insert or update by ID |
| `insert_document_by_id` `[W]` | Insert new (fails if exists) |
| `replace_document_by_id` `[W]` | Replace existing (fails if absent) |
| `delete_document_by_id` `[W]` | Delete by ID |
| `mutate_subdocument` `[W]` | Modify parts of an existing document without rewriting it |

## Query & indexing
| Tool | Does |
|------|------|
| `run_sql_plus_plus_query` | Run SQL++. Loaded in read-only mode but write DML (INSERT/UPDATE/DELETE/MERGE/DDL) is rejected |
| `explain_sql_plus_plus_query` | Execution plan: scans, joins, index usage, cost estimates |
| `list_indexes` | List indexes + definitions; `return_raw_index_stats=true` for raw stats. **Requires Server 8.0+** |
| `get_index_advisor_recommendations` | Index Advisor recommendations for a query |
| `get_index_stats` | Per-index statistics (size, fragmentation, scan traffic) from the Index Service |
| `create_query_index` `[W]` | Create a GSI index (scalar, Hyperscale vector, or Composite vector) via SQL++ |
| `create_index` `[W]` | **Deprecated**: create a scalar GSI index. Use `create_query_index` |
| `build_index` `[W]` | Build all deferred indexes on a collection |
| `drop_index` `[W]` | Drop a GSI index (scalar or vector) |

## Query performance analysis
These query `system:completed_requests`:
| Tool | Surfaces |
|------|----------|
| `get_longest_running_queries` | Slowest by avg service time |
| `get_most_frequent_queries` | Most frequently executed |
| `get_queries_not_selective` | Non-selective queries |
| `get_queries_not_using_covering_index` | Queries missing a covering index |
| `get_queries_using_primary_index` | Queries hitting the primary index (perf smell) |
| `get_queries_with_largest_response_sizes` | Largest response sizes |
| `get_queries_with_large_result_count` | Largest result counts |

Live query state:
| Tool | Does |
|------|------|
| `get_active_queries` | Queries executing right now, across every query-service node |
| `get_cluster_query_vitals` | Query-engine health (vitals) from every query-service node |
| `delete_active_query` `[W]` | Cancel an in-flight query by its request ID |

## Search & vector search
| Tool | Does |
|------|------|
| `list_search_indexes` | List Search (FTS) indexes, optionally filtered by bucket and scope |
| `get_search_index_definition` | Full definition of one Search index |
| `run_search` | Run an FTS query against a Search index, or fetch its execution plan |
| `run_vector_search` | Search-service vector search, including hybrid and prefiltered search |
| `run_vector_query` | Embed a query and run a similarity search against a GSI vector index |
| `upsert_search_index` `[W]` | Create or update a Search index definition |
| `drop_search_index` `[W]` | Drop a Search index |

`run_vector_search` and `run_vector_query` embed the query text, so they need an embedding provider (`CB_MCP_EMBEDDING_MODEL_PROVIDER` plus model/key settings, see `couchbase-mcp-server --help`). Without one they stay loaded but fail with an actionable error when called.
