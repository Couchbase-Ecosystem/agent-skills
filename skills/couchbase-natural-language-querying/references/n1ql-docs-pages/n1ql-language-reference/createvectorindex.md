# CREATE VECTOR INDEX

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

The `CREATE VECTOR INDEX` statement allows you to create Hyperscale Vector indexes.

To create secondary indexes or Composite Vector indexes, use the [CREATE INDEX](n1ql-language-reference/createindex.adoc) statement.

## Purpose

`CREATE VECTOR INDEX` allows you to make multiple concurrent index creation requests.
The command starts a task to create the index definition in the background.
If there is an index creation task already running, the Index Service queues the incoming index creation request.
`CREATE VECTOR INDEX` returns as soon as the index creation phase is complete.

By default, when the index creation phase is complete, the Index Service triggers the index build phase.
If you lose connectivity, the index build operation continues in the background.
You can defer the index build phase using the `defer_build` clause.
In deferred build mode, `CREATE VECTOR INDEX` creates the index definition, but does not trigger the index build phase.
You can then build the index using the [BUILD INDEX](n1ql-language-reference/build-index.adoc) command.

You can create multiple identical secondary indexes on a keyspace and place them on separate nodes for better index availability.
In Couchbase Server Enterprise Edition, the recommended way to do this is using the `num_replica` option.
In Couchbase Server Community Edition, you need to create multiple identical indexes and place them using the `nodes` option.
For more information, see [WITH Clause](#with-clause).

Hyperscale Vector indexes and Composite Vector indexes require a codebook for the vector field.
The codebook is the result of sampling the dataset and is saved as part of the index metadata.

The codebook is created as part of the [BUILD INDEX](n1ql-language-reference/build-index.adoc) process, and is not incrementally updated.
If the data set changes dramatically, you must drop and rebuild the index to update the codebook.

## Prerequisites

##### RBAC Privileges

To execute the CREATE VECTOR INDEX statement, you must have the `Query Manage Index` privilege granted on the keyspace.
For more information about user roles, see
[Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
create-vector-index ::= 'CREATE' 'VECTOR' 'INDEX' ( index-name ( 'IF' 'NOT' 'EXISTS' )? |
                        'IF' 'NOT' 'EXISTS' index-name ) 'ON' keyspace-ref
                        '(' index-key-and-attrib ')'
                        index-include? index-partition? where-clause? index-using? index-with?
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/create-vector-index.png)

* **index-name**\
(Required) A unique name that identifies the index.

  <a name="index-name"></a>Valid GSI index names can contain any of the following characters: `A-Z` `a-z` `0-9` `#` `_`, and must start with a letter, [`A-Z` `a-z`].
  The minimum length of an index name is 1 character and there is no maximum length set for an index name.
  When querying, if the index name contains a `#` or `_` character, you must enclose the index name within backticks.
* **keyspace-ref**\
(Required) Specifies the keyspace where the index is created.
See [Keyspace Reference](#keyspace-reference).
* **index-key-and-attrib**\
(Required) Specifies the index key and index key attribute.
See [Index Key and Attribute](#index-key-and-attribute).
* **index-include**\
(Optional) Specifies non-key fields to include in the index.
See [INCLUDE Clause](#include-clause).
* **index-partition**\
(Optional) Specifies index partitions.
See [PARTITION BY HASH Clause](#partition-by-hash-clause).
* **where-clause**\
(Optional) Specifies filters for a partial index.
See [WHERE Clause](#where-clause).
* **index-using**\
(Optional) Specifies the index type.
See [USING Clause](#using-clause).
* **index-with**\
(Optional) Specifies options for the index.
See [WITH Clause](#with-clause).

### IF NOT EXISTS Clause

The optional `IF NOT EXISTS` clause enables the statement to complete successfully when the specified index already exists.
If an index with the same name already exists within the specified keyspace, then:

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
(Optional) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [namespace](n1ql:n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.
Currently, only the `default` namespace is available.
If the namespace name is omitted, the default namespace in the current session is used.
* **bucket**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [bucket name](n1ql:n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.
* **scope**\
(Optional) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [scope name](n1ql:n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.
If omitted, the bucket’s default scope is used.
* **collection**\
(Optional) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [collection name](n1ql:n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.
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
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [collection name](n1ql:n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.

For example, `airline` indicates the `airline` collection, assuming the query context is set.

### Index Key and Attribute

```ebnf
index-key-and-attrib ::= index-key index-vector
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/index-key-and-attrib.png)

Hyperscale Vector indexes only have one key, which must be a vector field.
The index key takes one attribute, the VECTOR keyword.

* **index-key**\
(Required) Specifies an index key.
See [Index Key](#index-key).
* **index-vector**\
(Required) Specifies an attribute for the index key.
See [VECTOR Keyword](#vector-keyword).

#### Index Key

```ebnf
index-key ::= expr | array-expr
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/index-key.png)

The index key is a {sqlpp} [expression](n1ql-language-reference/index.adoc) referring to a vector field, or an ARRAY expression on the vector field.

* **expr**\
The name of a vector field in the document, or a [BASE64_DECODE()](n1ql:n1ql-language-reference/metafun.adoc#base64-decode) function on the vector field --
this is necessary if the embedded vectors are stored as a base64-encoded string.
* **array-expr**\
An array expression on a vector field in the document.
Only ALL ARRAY is supported.
The [FLATTEN_KEYS()](n1ql:n1ql-language-reference/metafun.adoc#flatten_keys) function is supported, but more than one key in [FLATTEN_KEYS()](n1ql:n1ql-language-reference/metafun.adoc#flatten_keys) is not permitted.
For details, see [n1ql-language-reference/indexing-arrays.adoc](n1ql-language-reference/indexing-arrays.adoc).

#### VECTOR Keyword

```ebnf
index-vector ::= 'VECTOR'
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/index-vector.png)

Indicates that the index key is a vector field.

### INCLUDE Clause

```ebnf
index-include ::= 'INCLUDE' '(' expr ( ',' expr )* ')'
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/index-include.png)

Used to include scalar fields in the index, which you can use to filter the vector search.
The INCLUDE clause cannot include a vector field.
For details, see [vector-index:hyperscale-filter.adoc](vector-index:hyperscale-filter.adoc).

* **expr**\
A {sqlpp} [expression](n1ql-language-reference/index.adoc) referring to any scalar field in the document.

### PARTITION BY HASH Clause

{enterprise}

Used to partition the index.
Index partitioning helps increase the query performance by dividing and spreading a large index of documents across multiple nodes, horizontally scaling out an index as needed.
For more information, see [Index Partitioning](n1ql-language-reference/index-partitioning.adoc).

With Hyperscale Vector indexes and Composite Vector indexes, training is done for each index node independently, and the codebook is provided to all partitions on that node.
If there are multiple partitions for an index on a node, training is only done once for all partitions.
See [The Importance of Index Training](vector-index:vectors-and-indexes-overview.adoc#index-training).

### WHERE Clause

```ebnf
where-clause ::= 'WHERE' cond
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/where-clause.png)

* **cond**\
Specifies WHERE clause predicates to qualify the subset of documents to include in the index.

### USING Clause

```ebnf
index-using ::= 'USING' 'GSI'
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/index-using.png)

The index type for a secondary index must be Global Secondary Index (GSI).
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
| ***nodes***<br> __optional__ | An array of strings, each of which represents a node name. ''' {community} In Couchbase Server Community Edition, a single secondary index of type `GSI` can be placed on a single node that runs the Indexing Service. The `nodes` property enables you to specify the node that the index is placed on. (((default index placement)))If `nodes` is not specified, the Index planner may place the index on any of the nodes running the Indexing Service. ''' {enterprise} In Couchbase Server Enterprise Edition, you can specify multiple nodes to distribute replicas of an index across nodes running the Indexing Service: for example, `WITH {"nodes": ["node1:8091", "node2:8091", "node3:8091"]}`. For more information and examples, see [Index Replication](indexes:index-replication.adoc#index-replication). (((default index placement)))If `nodes` is not specified, then the system places the new index and any replicas on any of the nodes running the Indexing Service, in order to achieve the best resource utilization. This is done by taking into account the current resource usage statistics of index nodes. If you specify the `nodes` property by itself, the index is placed on one of the destination nodes, and a replica is placed on each of the others. If you specify both `nodes` and `num_replica`, the Index planner chooses from the set of specified nodes to place the index and its replicas. In this case, the number of nodes in the array must be greater than the specified number of replicas. Otherwise, the index creation fails. ''' A node name passed to the `nodes` property must include the cluster administration port, by default 8091. ***Example:*** `["192.0.2.0:8091"]` | String array |
| ***defer_build***<br> __optional__ | Whether the index should be created in deferred build mode. When set to `true`, the `CREATE VECTOR INDEX` operation queues the task for building the GSI index but immediately pauses the building of the index. Index building requires an expensive scan operation. Deferring building of the index with multiple indexes can optimize the expensive scan operation. Admins can defer building multiple indexes and, using the `BUILD INDEX` statement, build multiple indexes efficiently with one efficient scan of bucket data. When set to `false`, the `CREATE VECTOR INDEX` operation queues the task for building the GSI index and immediately kicks off the building of the index. ***Default:*** `false` | Boolean |
| ***num_replica***<br> __optional__ | {enterprise} This property is only available in Couchbase Server Enterprise Edition. The number of [replicas](indexes:index-replication.adoc#index-replication) of the index to create. The indexer will automatically distribute these replicas amongst index nodes in the cluster for load-balancing and high availability purposes. The indexer will attempt to distribute the replicas based on the server groups in use in the cluster where possible. The number of replicas must be lower than the number of index nodes in the cluster. If `nodes` is specified, the number of replicas must be lower than the number of nodes in the array. Otherwise, the index creation fails. ***Default:*** `1` | Integer |
| ***dimension***<br> __required__ | The number of dimensions in the vector. The embedded model you use to embed the vectors determines the number of dimensions in the vector. | Integer |
| ***similarity***<br> __optional__ | Sets the distance metric to use when comparing vectors during index creation. Couchbase {product-name} uses the following strings to represent the distance metrics: COSINE:: [Cosine Similarity](vector-index:vectors-and-indexes-overview.adoc#cosine) DOT:: [Dot Product](vector-index:vectors-and-indexes-overview.adoc#dot) L2:: EUCLIDEAN:: [Euclidean Distance](vector-index:vectors-and-indexes-overview.adoc#euclidean) L2_SQUARED:: EUCLIDEAN_SQUARED:: [Euclidean Squared Distance](vector-index:vectors-and-indexes-overview.adoc#euclidean-squared) For the greatest accuracy, use the distance metric you plan to use to query the data. ***Default:*** `L2_SQUARED` | String |
| ***description***<br> __optional__ | The settings for the quantization and index algorithms. The string is made up of the following settings: IVF:: The number of centroids allocated for the index. SQ:: For scalar quantization -- the number of bits used to store the centroid for each bin. PQ:: For product quantization -- the number of subquantizers, and the number of bits in the centroid’s index value. For more information, see [Quantization and Centroid Settings](vector-index:hyperscale-vector-index.adoc#algo_settings). ***Pattern:*** `^IVF[0-9]**,(SQ[468]\|PQ[0-9]+x[0-9]+)$` **Default:*** `IVF,SQ8` | String |
| ***scan_nprobes***<br> __optional__ | The number of cells to search for each scan. ***Default:*** `1` | Integer |
| ***train_list***<br> __optional__ | The size of the sample set of vectors to be used for index training. If the index count is <&#160;10000, the default is to sample everything. Otherwise, the default value is 10% of the index count, or 10&#160;× the number of centroids, whichever is higher. ***Maximum:*** `1000000` | Integer |

Partitioned indexes support further options.
See [n1ql-language-reference/index-partitioning.adoc](n1ql-language-reference/index-partitioning.adoc).

## Usage

<dl><dt><strong>❗ IMPORTANT: Attention</strong></dt><dd>

Do not create (or drop) secondary indexes, Composite Vector indexes, or Hyperscale Vector indexes when any Index service node is down, as this may result in duplicate index names.
</dd></dl>

### Monitoring Indexes

Index metadata provides a state field.
This state field and other index metadata can be queried using [system:indexes](n1ql-intro/sysinfo.adoc#querying-indexes).
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

### Index Replicas

In the [Indexes screen in the Couchbase Web Console](manage:manage-ui/manage-ui.adoc#console-indexes), index replicas are marked with their replica ID.

!["The Indexes screen showing an index and index replica with replica ID"](../../assets/images/create-index-replica-id.png)

If you select `view by server node` from the drop-down menu, you can see the server node where each index and index replica is placed.

You can also query the [system:indexes](n1ql-intro/sysinfo.adoc#querying-indexes) catalog to find the ID of an index replica and see which node it’s placed on.

<dl><dt><strong>📌 NOTE</strong></dt><dd>

By default, index replicas are used to serve index scans.
The system automatically load-balances an index scan across the index and all its replicas.
Adding index replicas enables you to scale scan throughput, in addition to providing high availability.
</dd></dl>

With Hyperscale Vector indexes and Composite Vector indexes, training is done by each replica index independently, and the codebook is stored as part of index metadata.
See [The Importance of Index Training](vector-index:vectors-and-indexes-overview.adoc#index-training).

### Defer Index Builds by Default

Usually, the default setting for the `defer_build` option is `false`.
In Couchbase Server 7.6.2 and later, you can change the default setting for the `defer_build` option.

If you change the default setting for `defer_build` to `true`, index creation operates in deferred build mode by default.

To change the default setting for deferred builds, use the Index Settings REST API to set the `indexer.settings.defer_build` property.
For an example, see [Defer Index Builds by Default](index-rest-settings:index.adoc#ex-defer-build).

## Examples

To try the examples in this section, you must install the vector sample data as described in [Prerequisites](vector-index:hyperscale-vector-index.adoc#prerequisites).

<a name="ex-create-rgb-idx"></a>**Create a Hyperscale Vector index**

For this example, the path to the required keyspace is specified by the query, so you do not need to set the query context.

Create a Hyperscale Vector index for the vector column named `embedding-vector-dot`.

```sqlpp
CREATE VECTOR INDEX `color_desc_hyperscale` 
       ON `vector-sample`.`color`.`rgb`(`embedding_vector_dot` VECTOR)
       WITH { "dimension":1536, "similarity":"L2", "description":"IVF8,SQ4" }
```

<a name="ex-create-idx-brightness"></a>**Create a Hyperscale Vector index with included scalar values**

For this example, the path to the required keyspace is specified by the query, so you do not need to set the query context.

Create a Hyperscale Vector index for the vector column named `embedding-vector-dot`, including the scalar `brightness` field.

```sqlpp
CREATE VECTOR INDEX `color_desc_hyperscale_brightness` 
       ON `vector-sample`.`color`.`rgb`(`embedding_vector_dot` VECTOR)
       INCLUDE (`brightness`)
       WITH { "dimension":1536, "similarity":"L2", "description":"IVF8,SQ4" }
```

<a name="ex-create-rgb-no-persist"></a>**Create a Hyperscale Vector index with no reranking**

For this example, the path to the required keyspace is specified by the query, so you do not need to set the query context.

Create a Hyperscale Vector index from the example RGB dataset that does not persist the full vector value.

```sqlpp
CREATE VECTOR INDEX `color_desc_hyperscale_no_persist` 
       ON `vector-sample`.`color`.`rgb`(`embedding_vector_dot` VECTOR)
       WITH { "dimension":1536, "similarity":"L2", "description":"IVF8,SQ4", 
              "persist_full_vector": false};
```

## Related Links

* [indexes:indexing-overview.adoc](indexes:indexing-overview.adoc)
* [vector-index:composite-vector-index.adoc](vector-index:composite-vector-index.adoc)
* [vector-index:hyperscale-vector-index.adoc](vector-index:hyperscale-vector-index.adoc)
* [CREATE PRIMARY INDEX](n1ql:n1ql-language-reference/createprimaryindex.adoc)
| [CREATE INDEX](n1ql:n1ql-language-reference/createindex.adoc)
* [BUILD INDEX](n1ql:n1ql-language-reference/build-index.adoc)
* [ALTER INDEX](n1ql:n1ql-language-reference/alterindex.adoc)
| [ALTER VECTOR INDEX](n1ql:n1ql-language-reference/altervectorindex.adoc)
* [DROP PRIMARY INDEX](n1ql:n1ql-language-reference/dropprimaryindex.adoc)
| [DROP INDEX](n1ql:n1ql-language-reference/dropindex.adoc)
| [DROP VECTOR INDEX](n1ql:n1ql-language-reference/dropvectorindex.adoc)
