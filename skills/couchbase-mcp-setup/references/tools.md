# MCP tool catalog

Exact tool names the server exposes (verified on v1.0; re-check with `get_server_configuration_status` after upgrading). Use these for verification, and for `CB_MCP_DISABLED_TOOLS` / `CB_MCP_CONFIRMATION_REQUIRED_TOOLS` lists (names must match exactly). `[W]` = write tool, not loaded when `CB_MCP_READ_ONLY_MODE=true` (the bundled default; the server's own default is `false` on `1.0+`). See [`safety.md`](safety.md).

- [Cluster health](#cluster-health) · use for verification
- [Schema discovery](#schema-discovery)
- [KV document ops](#kv-document-ops)
- [Query & indexing](#query--indexing)
- [Query performance analysis](#query-performance-analysis)

## Cluster health
| Tool | Does |
|------|------|
| `get_server_configuration_status` | MCP server status + config (read-only mode, loaded tools) |
| `test_cluster_connection` | Verify credentials by connecting |
| `get_cluster_health_and_services` | Cluster health + running services |

## Schema discovery
| Tool | Does |
|------|------|
| `get_buckets_in_cluster` | List buckets |
| `get_scopes_in_bucket` | List scopes in a bucket |
| `get_collections_in_scope` | List collections in a scope |
| `get_scopes_and_collections_in_bucket` | List scopes + collections together |
| `get_schema_for_collection` | Infer document structure for a collection |

## KV document ops
| Tool | Does |
|------|------|
| `get_document_by_id` | Fetch a document by ID |
| `upsert_document_by_id` `[W]` | Insert or update by ID |
| `insert_document_by_id` `[W]` | Insert new (fails if exists) |
| `replace_document_by_id` `[W]` | Replace existing (fails if absent) |
| `delete_document_by_id` `[W]` | Delete by ID |

## Query & indexing
| Tool | Does |
|------|------|
| `run_sql_plus_plus_query` | Run SQL++. Loaded in read-only mode but write DML (INSERT/UPDATE/DELETE/MERGE/DDL) is rejected |
| `explain_sql_plus_plus_query` | Execution plan: scans, joins, index usage, cost estimates |
| `list_indexes` | List indexes + definitions; `return_raw_index_stats=true` for raw stats. **Requires Server 8.0+** |
| `get_index_advisor_recommendations` | Index Advisor recommendations for a query |

## Query performance analysis
All query `system:completed_requests`:
| Tool | Surfaces |
|------|----------|
| `get_longest_running_queries` | Slowest by avg service time |
| `get_most_frequent_queries` | Most frequently executed |
| `get_queries_not_selective` | Non-selective queries |
| `get_queries_not_using_covering_index` | Queries missing a covering index |
| `get_queries_using_primary_index` | Queries hitting the primary index (perf smell) |
| `get_queries_with_largest_response_sizes` | Largest response sizes |
| `get_queries_with_large_result_count` | Largest result counts |
