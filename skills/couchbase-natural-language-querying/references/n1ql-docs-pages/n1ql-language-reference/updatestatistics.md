# UPDATE STATISTICS

The UPDATE STATISTICS statement collects statistics on expressions over a named keyspace.
These statistics are used by the cost-based optimizer when choosing the optimal plan to execute a query.

## Purpose

The [cost-based optimizer](n1ql-language-reference/cost-based-optimizer.adoc) uses statistics to generate a query plan with the lowest processing cost, for [SELECT](n1ql-language-reference/selectintro.adoc), [UPDATE](n1ql-language-reference/update.adoc), [DELETE](n1ql-language-reference/delete.adoc), [MERGE](n1ql-language-reference/merge.adoc), and [INSERT INTO with SELECT](n1ql-language-reference/insert.adoc) queries.

After creating the indexes, and before running a query, you must gather distribution statistics for the expressions used in the query.
The cost-based optimizer uses these distribution statistics, together with keyspace and index statistics, to select the optimal indexes and generate the query plan.

In Couchbase Server 7.6 and later, the Query service automatically gathers statistics whenever an index is created or built.
You can use the `UPDATE STATISTICS` statement to gather statistics at any time.

## Syntax

```ebnf
update-statistics ::= update-statistics-expr | update-statistics-index |
                      updated-statistics-indexes | update-statistics-delete
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/update-statistics.png)

The `UPDATE STATISTICS` statement provides several different syntaxes to enable you to manage statistics.
For further details, refer to the following links.

* [Update Statistics for Index Expressions](n1ql-language-reference/statistics-expressions.adoc)
* [Update Statistics for a Single Index](n1ql-language-reference/statistics-index.adoc)
* [Update Statistics for Multiple Indexes](n1ql-language-reference/statistics-indexes.adoc)
* [Delete Statistics](n1ql-language-reference/statistics-delete.adoc)

## Usage

When you use an index with a query, you typically create the index on the fields which the query uses to filter.
To use the cost-based optimizer with that query, you must collect statistics on the same fields that you used to create the index.

A query may have predicates on non-indexed fields, and you can collect statistics on those fields also to help the optimizer.

For a query which filters on an array or array of objects, you must collect the statistics using exactly the same expression that you used to create the index.

### When to Gather Statistics

How frequently you should run the `UPDATE STATISTICS` statement to gather statistics depends on the rate of data change.
For data that does not change frequently, there is no need to run `UPDATE STATISTICS`.
For data that changes constantly, you should run `UPDATE STATISTICS` more frequently.

To gather statistics automatically, consider running a `cron` job at regular intervals to execute the `UPDATE STATISTICS` statement via the [cbq shell](n1ql:n1ql-intro/cbq.adoc#executing-a-script).

## Result

If successful, the statement returns an empty array.

### Index Residency

Optimizer statistics for an index can only be gathered when the index is at least partially memory-resident.
The optimizer statistics are gathered from the memory-resident portion of an index.
A higher memory-resident ratio produces more accurate optimizer statistics for that index.

If an index has a memory-resident ratio of zero, then the statement returns the following warning:

```json
[
  {
    "code": 5390,
    "msg": "Index def_inventory_airport_faa is not in memory"
  }
]
```

Depending on the index storage settings, if an index has been scanned recently, it is more likely to be memory-resident; whereas if an index is not used for a long while, then it is more likely to be ejected from memory.
You may be able to improve the memory-resident ratio for an index (and avoid error 5390) by running one or more queries which use that index.
For further details, refer to [Storage Settings](indexes:storage-modes.adoc).

## Optimizer Statistics

For each bucket, the `UPDATE STATISTICS` command stores statistics in a collection called `_query` within a scope called `_system`.
The `_system` scope and its collections, including `_query`, are created automatically when you create a bucket, or when you migrate a bucket from a previous version of Couchbase Server.

### Security for Optimizer Statistics

Regular users do not have access to the `_system` scope or any of its collections, including `_query`.

Users with system administration privileges can access `_system` scope and its collections, including `_query`.
However, even with system administration privileges, you can’t drop or create the `_system` scope or any of its collections.

The `_system` scope and its collections are not listed in the **Explore Your Data** area in the Query Workbench.

### Optimizer Statistics for Multiple Query Nodes

When a cluster has multiple Query nodes, statistics gathered from one Query node via the `UPDATE STATISTICS` statement are automatically propagated to the other Query nodes.
You don’t need to run `UPDATE STATISTICS` with the same index expression for multiple query nodes.

### Monitoring Optimizer Statistics

To monitor the optimizer statistics, query the `system:dictionary` and `system:dictionary_cache` keyspaces.
For further details, refer to [n1ql:n1ql-manage/monitoring-n1ql-query.adoc](n1ql:n1ql-manage/monitoring-n1ql-query.adoc).

## Related Links

* [Cost-Based Optimizer](n1ql-language-reference/cost-based-optimizer.adoc)
