# CREATE PRIMARY INDEX

<style type="text/css">
  /* DOC-10177 */
  .hdlist table tr td.hdlist1,
  .hdlist table tr td.hdlist2 {
    padding: 1.5rem 0 0;
  }

  /* Compact horizontal definition lists */
  .hdlist.compact,
  .hdlist.compact {
    padding-top: 1rem;
  }
  .hdlist.compact table tr td.hdlist1,
  .hdlist.compact table tr td.hdlist2 {
    padding: 0.5rem 0 0;
  }

  /* Descriptions in horizontal description lists should have left padding */
  .hdlist table tr td.hdlist2,
  .hdlist.compact table tr td.hdlist2 {
    padding-left: 1rem;
  }

  /* Paragraphs in horizontal description lists should not have left margin */
  .hdlist table .hdlist1 + .hdlist2 p {
    margin-left: 0; !important
  }

  /* Horizontal definitions should match style of vertical definitions */
  td.hdlist1 {
    font-weight: 600;
  }
</style>

The `CREATE PRIMARY INDEX` statement allows you to create a primary index.
Primary indexes contain a full set of keys in a given keyspace.
Primary indexes are optional -- they enable you to run ad hoc queries on a keyspace that’s not supported by a secondary index.

## Purpose

`CREATE PRIMARY INDEX` allows you to make multiple concurrent index creation requests.
The command starts a task to create the primary index definition in the background.
If there is an index creation task already running, the Index Service queues the incoming index creation request.
`CREATE PRIMARY INDEX` returns as soon as the index creation phase is complete.

By default, when the index creation phase is complete, the Index Service triggers the index build phase.
If you lose connectivity, the index build operation continues in the background.
You can defer the index build phase using the `defer_build` clause.
In deferred build mode, `CREATE PRIMARY INDEX` creates the index definition, but does not trigger the index build phase.
You can then build the index using the [BUILD INDEX](n1ql-language-reference/build-index.adoc) command.

You can create multiple identical primary indexes on a keyspace and place them on separate nodes for better index availability.
In Couchbase Server Enterprise Edition, the recommended way to do this is using the `num_replicas` option.
In Couchbase Server Community Edition, you need to create multiple identical indexes and place them using the `nodes` option.
For more information, see [WITH Clause](#with-clause).

## Prerequisites

##### RBAC Privileges

To execute the `CREATE PRIMARY INDEX` statement, you must have the `Query Manage Index` privilege granted on the keyspace.
For more information about user roles, see
[Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
create-primary-index ::= 'CREATE' 'PRIMARY' 'INDEX' ( index-name? ( 'IF' 'NOT' 'EXISTS' )? |
                         'IF' 'NOT' 'EXISTS' index-name )
                         'ON' keyspace-ref index-partition? index-using? index-with?
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/create-primary-index.png)

* **index-name**\
(Optional) A unique name that identifies the index.
If a name is not specified, the default name of `#primary` is applied.

  Valid GSI index names can contain any of the following characters: `A-Z` `a-z` `0-9` `#` `_`, and must start with a letter, [`A-Z` `a-z`].
  The minimum length of an index name is 1 character and there is no maximum length set for an index name.
  When querying, if the index name contains a `#` or `_` character, you must enclose the index name within backticks.
* **keyspace-ref**\
[Required] Specifies the keyspace where the index is created.
See [Keyspace Reference](#keyspace-reference).
* **index-partition**\
(Optional) Specifies index partitions.
See [PARTITION BY HASH Clause](#partition-by-hash-clause).
* **index-using**\
(Optional) Specifies the index type.
See [USING Clause](#using-clause).
* **index-with**\
(Optional) Specifies options for the index.
See [WITH Clause](#with-clause).

### IF NOT EXISTS Clause

The optional `IF NOT EXISTS` clause enables the statement to complete successfully when the specified primary index already exists.
If a primary index with the same name already exists within the specified keyspace, then:

* If this clause is not present, an error is generated.
* If this clause is present, the statement does nothing and completes without error.

### Keyspace Reference

```ebnf
keyspace-ref ::= keyspace-path | keyspace-partial
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/keyspace-ref.png)

Specifies the keyspace for which the index needs to be created.
The keyspace reference may be a [keyspace path](#keyspace-path) or a [keyspace partial](#keyspace-partial).

**📌 NOTE**\
If there is a hyphen (-) inside any part of the keyspace reference, you must wrap that part of the keyspace reference in backticks ({backtick}&#160;{backtick}).
See the examples on this page.

#### Keyspace Path

```ebnf
keyspace-path ::= ( namespace ':' )? bucket ( '.' scope '.' collection )?
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/keyspace-path.png)

If the keyspace is a named collection, or the default collection in the default scope within a bucket, the keyspace reference may be a keyspace path.
In this case, the [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context) should not be set.

* **namespace**\
(Optional) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [namespace](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.
Currently, only the `default` namespace is available.
If the namespace name is omitted, the default namespace in the current session is used.
* **bucket**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [bucket name](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.
* **scope**\
(Optional) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [scope name](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.
If omitted, the bucket’s default scope is used.
* **collection**\
(Optional) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [collection name](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.
If omitted, the default collection in the bucket’s default scope is used.

For example, `default:{backtick}travel-sample{backtick}` indicates the default collection in the default scope in the `travel-sample` bucket in the `default` namespace.

Similarly, `default:{backtick}travel-sample{backtick}.inventory.airline` indicates the `airline` collection in the `inventory` scope in the `travel-sample` bucket in the `default` namespace.

#### Keyspace Partial

```ebnf
keyspace-partial ::= collection
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/keyspace-partial.png)

Alternatively, if the keyspace is a named collection, the keyspace reference may be just the collection name with no path.
In this case, you must set the [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context) to indicate the required namespace, bucket, and scope.

* **collection**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [collection name](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.

For example, `airline` indicates the `airline` collection, assuming the query context is set.

### PARTITION BY HASH Clause

{enterprise}

Used to partition the index.
Index partitioning helps increase the query performance by dividing and spreading a large index of documents across multiple nodes, horizontally scaling out an index as needed.
For more information, see [Index Partitioning](n1ql-language-reference/index-partitioning.adoc).

### USING Clause

```ebnf
index-using ::= 'USING' 'GSI'
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/index-using.png)

The index type for a primary index must be Global Secondary Index (GSI).
The `USING GSI` keywords are optional and may be omitted.

### WITH Clause

```ebnf
index-with ::= 'WITH' expr
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/index-with.png)

Use the WITH clause to specify additional options.

* **expr**\
An object with the following properties.

| Name | Description | Schema |
| --- | --- | --- |
| ***nodes***<br> __optional__ | An array of strings, each of which represents a node name. ''' {community} In Couchbase Server Community Edition, a single primary index of type `GSI` can be placed on a single node that runs the Indexing Service. The `nodes` property enables you to specify the node that the index is placed on. (((default index placement)))If `nodes` is not specified, the Index planner may place the index on any of the nodes running the Indexing Service. ''' {enterprise} In Couchbase Server Enterprise Edition, you can specify multiple nodes to distribute replicas of an index across nodes running the Indexing Service: for example, `WITH {"nodes": ["node1:8091", "node2:8091", "node3:8091"]}`. For more information and examples, see [Index Replication](indexes:index-replication.adoc#index-replication). (((default index placement)))If `nodes` is not specified, then the system places the new index and any replicas on any of the nodes running the Indexing Service, in order to achieve the best resource utilization. This is done by taking into account the current resource usage statistics of index nodes. If you specify the `nodes` property by itself, the index is placed on one of the destination nodes, and a replica is placed on each of the others. If you specify both `nodes` and `num_replica`, the Index planner chooses from the set of specified nodes to place the index and its replicas. In this case, the number of nodes in the array must be greater than the specified number of replicas. Otherwise, the index creation fails. ''' A node name passed to the `nodes` property must include the cluster administration port, by default 8091. ***Example:*** `["192.0.2.0:8091"]` | String array |
| ***defer_build***<br> __optional__ | Whether the index should be created in deferred build mode. When set to `true`, the `CREATE PRIMARY INDEX` operation queues the task for building the GSI index but immediately pauses the building of the index. Index building requires an expensive scan operation. Deferring building of the index with multiple indexes can optimize the expensive scan operation. Admins can defer building multiple indexes and, using the `BUILD INDEX` statement, build multiple indexes efficiently with one efficient scan of keyspace data. When set to `false`, the `CREATE PRIMARY INDEX` operation queues the task for building the GSI index and immediately kicks off the building of the index. ***Default:*** `false` | Boolean |
| ***num_replica***<br> __optional__ | {enterprise} This property is only available in Couchbase Server Enterprise Edition. The number of [replicas](indexes:index-replication.adoc#index-replication) of the index to create. The indexer will automatically distribute these replicas amongst index nodes in the cluster for load-balancing and high availability purposes. The indexer will attempt to distribute the replicas based on the server groups in use in the cluster where possible. The number of replicas must be lower than the number of index nodes in the cluster. If `nodes` is specified, the number of replicas must be lower than the number of nodes in the array. Otherwise, the index creation fails. ***Default:*** `1` | Integer |

Partitioned indexes support further options.
See [n1ql-language-reference/index-partitioning.adoc](n1ql-language-reference/index-partitioning.adoc).

## Usage

### Monitoring Primary Indexes

Index metadata provides a state field.
You can query this state field and other index metadata using [system:indexes](n1ql-intro/sysinfo.adoc#querying-indexes).
The index state may be `scheduled for creation`, `deferred`, `building`, `pending`, `online`, `offline`, or `abridged`.
You can also monitor the index state using the Couchbase Web Console.

<dl><dt><strong>❗ IMPORTANT</strong></dt><dd>

If you kick off multiple index creation operations concurrently, you may sometimes see transient errors similar to the following.
If this error occurs, the Index Service tries to run the failed operation again in the background until it succeeds, up to a maximum of 1000 retries.

```json
[
  {
    "code": 5000,
    "msg": "GSI CreateIndex() - cause: Encountered transient error.  Index creation will be retried in background.  Error: Index ... will retry building in the background for reason: Build Already In Progress. Keyspace ...",
    "query": "..."
  }
]
```

If the Index Service still cannot create the index after the maximum number of retries, the index state is marked as `offline`.
You must drop the failed index using the `DROP INDEX` command.
</dd></dl>

### Primary Scan Timeout

For a primary index scan on any keyspace size, the query engine guarantees that the client is not exposed to scan timeout if the indexer throws a scan timeout after it has returned a greater than zero sized subset of primary keys.
To complete the scan, the query engine performs successive scans of the primary index until all the primary keys have been returned.
It’s possible that the indexer may throw scan timeout without returning any primary keys, and in this event the query engine returns scan timeout to the client.

For example, if the indexer cannot find a snapshot that satisfies the consistency guarantee of the query within the timeout limit, it will timeout without returning any primary keys.

For secondary index scans, the query engine does not handle scan timeout, and returns index scan timeout error to the client.
You can handle scan timeout on a secondary index by increasing the indexer timeout setting (see
[Query Settings](manage:manage-settings/query-settings.adoc)) or preferably by defining and using a more selective index.

## Examples

To try the examples in this section, you must set the query context as described in each example.

<a name="ex-create-primary"></a>**Create a primary index in the default scope and collection**

For this example, unset the query context.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

Create a named primary index on the default collection in the default scope within the `travel-sample` bucket.

```sqlpp
CREATE PRIMARY INDEX idx_default_primary ON `travel-sample` USING GSI;
```

<a name="ex-create-primary-name"></a>**Create a primary index in a named scope and collection**

For this example, the path to the required keyspace is specified by the query, so you do not need to set the query context.

This example is similar to [Create a primary index in the default scope and collection](#ex-create-primary), but creates a named primary index on the `airport` collection.

```sqlpp
CREATE PRIMARY INDEX idx_airport_primary ON `travel-sample`.inventory.airport USING GSI;
```

**Create a deferred primary index**

For this example, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

Create a named primary index using the `defer_build` option.

```sqlpp
CREATE PRIMARY INDEX idx_hotel_primary
  ON hotel
  USING GSI
  WITH {"defer_build":true};
```

Query `system:indexes` for the status of the index.

```sqlpp
SELECT * FROM system:indexes WHERE name="idx_hotel_primary";
```

The output from `system:indexes` shows the `idx_hotel_primary` in the deferred state.

**Build a deferred primary index**

For this example, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

Kick off the deferred build on the named primary index.

```sqlpp
BUILD INDEX ON hotel(idx_hotel_primary) USING GSI;
```

Query `system:indexes` for the status of the index.

```sqlpp
SELECT * FROM system:indexes WHERE name="idx_hotel_primary";
```

The output from `system:indexes` shows that the index has now been created.

## Related Links

* [indexes:indexing-overview.adoc](indexes:indexing-overview.adoc)
* [vector-index:composite-vector-index.adoc](vector-index:composite-vector-index.adoc)
* [vector-index:hyperscale-vector-index.adoc](vector-index:hyperscale-vector-index.adoc)
* [CREATE INDEX](n1ql:n1ql-language-reference/createindex.adoc)
| [CREATE VECTOR INDEX](n1ql:n1ql-language-reference/createvectorindex.adoc)
* [BUILD INDEX](n1ql:n1ql-language-reference/build-index.adoc)
* [ALTER INDEX](n1ql:n1ql-language-reference/alterindex.adoc)
| [ALTER VECTOR INDEX](n1ql:n1ql-language-reference/altervectorindex.adoc)
* [DROP PRIMARY INDEX](n1ql:n1ql-language-reference/dropprimaryindex.adoc)
| [DROP INDEX](n1ql:n1ql-language-reference/dropindex.adoc)
| [DROP VECTOR INDEX](n1ql:n1ql-language-reference/dropvectorindex.adoc)
