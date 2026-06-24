# CREATE INDEX

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

The `CREATE INDEX` statement allows you to create secondary indexes.
Secondary indexes contain a filtered or a full set of keys in a given keyspace.
Secondary indexes are optional but increase query efficiency on a keyspace.

In Couchbase Server 8.0 and later, the `CREATE INDEX` statement also allows you to create Composite Vector indexes.
To create Hyperscale Vector indexes, use the [CREATE VECTOR INDEX](n1ql-language-reference/createvectorindex.adoc) statement.

## Purpose

`CREATE INDEX` allows you to make multiple concurrent index creation requests.
The command starts a task to create the index definition in the background.
If there is an index creation task already running, the Index Service queues the incoming index creation request.
`CREATE INDEX` returns as soon as the index creation phase is complete.

By default, when the index creation phase is complete, the Index Service triggers the index build phase.
If you lose connectivity, the index build operation continues in the background.
You can defer the index build phase using the `defer_build` clause.
In deferred build mode, `CREATE INDEX` creates the index definition, but does not trigger the index build phase.
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

To execute the CREATE INDEX statement, you must have the `Query Manage Index` privilege granted on the keyspace.
For more information about user roles, see
[Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
create-index ::= 'CREATE' 'INDEX' ( index-name ( 'IF' 'NOT' 'EXISTS' )? |
                 'IF' 'NOT' 'EXISTS' index-name ) 'ON' keyspace-ref
                 '(' index-keys-and-attribs ')'
                 index-partition? where-clause? index-using? index-with?
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/create-index.png)

* **index-name**\
(Required) A unique name that identifies the index.

  <a name="index-name"></a>Valid GSI index names can contain any of the following characters: `A-Z` `a-z` `0-9` `#` `_`, `-`, and must start with a letter, [`A-Z` `a-z`].
  The minimum length of an index name is 1 character and there is no maximum length set for an index name.
  When querying, if the index name contains a `#` or `-` character, you must enclose the index name within backticks.
* **keyspace-ref**\
(Required) Specifies the keyspace where the index is created.
See [Keyspace Reference](#keyspace-reference).
* **index-keys-and-attribs**\
(Required) Specifies the index keys and index key attributes.
See [Index Keys and Attributes](#index-keys-and-attributes).
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

### Index Keys and Attributes

```ebnf
index-keys-and-attribs ::= index-key lead-key-attribs? ( ( ',' index-key key-attribs? )+ )?
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/index-keys-and-attribs.png)

Secondary indexes and Composite Vector indexes can have many keys.
Each key may have index attributes, which define the behavior of the index key.

* **index-key**\
(Required) Specifies an index key.
See [Index Key](#index-key).
* **lead-key-attribs**\
(Optional) Specifies attributes for the leading index key.
See [Index Key Attributes](#index-key-attributes).
* **key-attribs**\
(Optional) Specifies attributes for a non-leading index key.
See [Index Key Attributes](#index-key-attributes).

#### Index Key

```ebnf
index-key ::= expr | array-expr
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/index-key.png)

The index key is a {sqlpp} [expression](n1ql-language-reference/index.adoc) referring to a field in the document, or an ARRAY expression on the field.

For a Composite Vector index, one index key must refer to a vector field in the document.
The index key that refers to a vector field may be the only index key.
If there are multiple index keys, the index key referring to the vector field may be any of the index keys, including the leading index key.

* **expr**\
A field name or a scalar function over any field in the document.
This cannot use constant expressions, aggregate functions, or sub-queries.

  <a name="index-key-args"></a>For a vector field, the expression may be the field name, or a [BASE64_DECODE()](n1ql:n1ql-language-reference/metafun.adoc#base64-decode) function on the vector field --
  this is necessary if the embedded vectors are stored as a base64-encoded string.
* **array-expr**\
An array expression.
Array indexing enables you to create global indexes on array elements and optimize the execution of queries involving array elements.

  For a vector field, only ALL ARRAY is supported.
  The [FLATTEN_KEYS()](n1ql:n1ql-language-reference/metafun.adoc#flatten_keys) function is supported, but more than one key in [FLATTEN_KEYS()](n1ql:n1ql-language-reference/metafun.adoc#flatten_keys) is not permitted.
  For more information, see [n1ql-language-reference/indexing-arrays.adoc](n1ql-language-reference/indexing-arrays.adoc).

#### Index Key Attributes

```ebnf
lead-key-attribs ::= index-order include-missing? |
                     include-missing index-order? |
                     index-vector
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/lead-key-attribs.png)

```ebnf
key-attribs ::= index-order | index-vector
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/key-attribs.png)

Specifies attributes for the index key.

* **index-order**\
(Optional) Any index key on a non-vector field may include an index order clause.
See [Index Order](#index-order).
* **include-missing**\
(Optional) If the leading index key is a non-vector field, it may also include the `INCLUDE MISSING` clause.
See [INCLUDE MISSING Clause](#include-missing-clause).
* **include-vector**\
(Optional) In a Composite Vector index, one index key must include the `VECTOR` keyword.
See [VECTOR Keyword](#vector-keyword).

##### Index Order

```ebnf
index-order ::= 'ASC' | 'DESC'
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/index-order.png)

Specifies the sort order of the index key.
For non-vector fields only.

* **`ASC`**\
The index key is sorted in ascending order.
* **`DESC`**\
The index key is sorted in descending order.

This clause is optional; if omitted, the default is `ASC`.

##### INCLUDE MISSING Clause

```ebnf
include-missing ::= 'INCLUDE' 'MISSING'
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/include-missing.png)

The optional `INCLUDE MISSING` clause ensures that documents which do not include the index key field are indexed regardless.
If this clause is not present, then documents without the index key field are not indexed.

The `INCLUDE MISSING` clause can only be applied to the leading index key for non-vector fields.
The `INCLUDE MISSING` clause may be included before or after the `ASC` or `DESC` keyword.

##### VECTOR Keyword

```ebnf
index-vector ::= 'VECTOR'
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/index-vector.png)

Indicates that the index key is a vector field.

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
| ***defer_build***<br> __optional__ | Whether the index should be created in deferred build mode. When set to `true`, the `CREATE INDEX` operation queues the task for building the GSI index but immediately pauses the building of the index. Index building requires an expensive scan operation. Deferring building of the index with multiple indexes can optimize the expensive scan operation. Admins can defer building multiple indexes and, using the `BUILD INDEX` statement, build multiple indexes efficiently with one efficient scan of bucket data. When set to `false`, the `CREATE INDEX` operation queues the task for building the GSI index and immediately kicks off the building of the index. ***Default:*** `false` | Boolean |
| ***num_replica***<br> __optional__ | {enterprise} This property is only available in Couchbase Server Enterprise Edition. The number of [replicas](indexes:index-replication.adoc#index-replication) of the index to create. The indexer will automatically distribute these replicas amongst index nodes in the cluster for load-balancing and high availability purposes. The indexer will attempt to distribute the replicas based on the server groups in use in the cluster where possible. The number of replicas must be lower than the number of index nodes in the cluster. If `nodes` is specified, the number of replicas must be lower than the number of nodes in the array. Otherwise, the index creation fails. ***Default:*** `1` | Integer |

Composite Vector indexes support the following additional options.

|     |     |     |
| --- | --- | --- |
| Name | Description | Schema |
| ***dimension***<br> __required__ | The number of dimensions in the vector. The embedded model you use to embed the vectors determines the number of dimensions in the vector. | Integer |
| ***similarity***<br> __optional__ | Sets the distance metric to use when comparing vectors during index creation. Couchbase {product-name} uses the following strings to represent the distance metrics: COSINE:: [Cosine Similarity](vector-index:vectors-and-indexes-overview.adoc#cosine) DOT:: [Dot Product](vector-index:vectors-and-indexes-overview.adoc#dot) L2:: EUCLIDEAN:: [Euclidean Distance](vector-index:vectors-and-indexes-overview.adoc#euclidean) L2_SQUARED:: EUCLIDEAN_SQUARED:: [Euclidean Squared Distance](vector-index:vectors-and-indexes-overview.adoc#euclidean-squared) For the greatest accuracy, use the distance metric you plan to use to query the data. ***Default:*** `L2_SQUARED` | String |
| ***description***<br> __optional__ | The settings for the quantization and index algorithms. The string is made up of the following settings: IVF:: The number of centroids allocated for the index. SQ:: For scalar quantization -- the number of bits used to store the centroid for each bin. PQ:: For product quantization -- the number of subquantizers, and the number of bits in the centroid’s index value. For more information, see [Quantization and Centroid Settings](vector-index:composite-vector-index.adoc#algo_settings). ***Pattern:*** `^IVF[0-9]**,(SQ[468]\|PQ[0-9]+x[0-9]+)$` **Default:*** `IVF,SQ8` | String |
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

### Indexing Metadata

You can create indexes on metadata using the `META()` function.
For more information, see [n1ql-language-reference/indexing-meta-info.adoc](n1ql-language-reference/indexing-meta-info.adoc).

### Using Indexes for Aggregates

If you have an index on a simple expression, such as `geo.alt`, you can use that index to satisfy a query on an [aggregate](n1ql:n1ql-language-reference/aggregatefun.adoc) of that expression, such as `MIN(geo.alt)` or `MAX(geo.alt)`.
For more information and examples, see [Operator Pushdowns](indexes:index_pushdowns.adoc#operator-pushdowns).

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

To try the examples in this section, you must set the query context as described in each example.

<a name="ex-create-idx"></a>**Create an index in the default scope and collection**

For this example, unset the query context.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

Create a secondary index that contains airports with an `alt` value greater than 1000 on the node `127.0.0.1`.

```sqlpp
CREATE INDEX idx_default_over1000
  ON `travel-sample`(geo.alt)
  WHERE geo.alt > 1000
  USING GSI
  WITH {"nodes": ["127.0.0.1:8091"]};
```

<a name="ex-create-idx-collection"></a>**Create an index in a named scope and collection**

For this example, the path to the required keyspace is specified by the query, so you do not need to set the query context.

Create a secondary index that contains airports with an `alt` value greater than 1000 on the node `127.0.0.1`.

```sqlpp
CREATE INDEX idx_airport_over1000
  ON `travel-sample`.inventory.airport(geo.alt)
  WHERE geo.alt > 1000
  USING GSI
  WITH {"nodes": ["127.0.0.1:8091"]};
```

<a name="ex-create-idx-defer"></a>**Create a deferred index**

For this example, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

Create a secondary index with the `defer_build` option.

```sqlpp
CREATE INDEX idx_landmark_country
  ON landmark(country)
  USING GSI
  WITH {"defer_build":true};
```

Query `system:indexes` for the status of the index.

```sqlpp
SELECT * FROM system:indexes WHERE name="idx_landmark_country";
```

**Results**

```json
[
  {
    "indexes": {
      "bucket_id": "travel-sample",
      "datastore_id": "http://127.0.0.1:8091",
      "id": "d079aec40eb0c6cc",
      "index_key": [
        "`country`"
      ],
      "keyspace_id": "landmark",
      "name": "idx_landmark_country",
      "namespace_id": "default",
      "scope_id": "inventory",
      "state": "deferred", // ①
      "using": "gsi"
    }
  }
]
```

1. The index is in the deferred state.

<a name="ex-build-idx-defer"></a>**Build a deferred index**

For this example, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

Kick off a deferred build using the index name.

```sqlpp
BUILD INDEX ON landmark(idx_landmark_country) USING GSI;
```

Query `system:indexes` for the status of the index.

```sqlpp
SELECT * FROM system:indexes WHERE name="idx_landmark_country";
```

**Results**

```json
[
  {
    "indexes": {
      "bucket_id": "travel-sample",
      "datastore_id": "http://127.0.0.1:8091",
      "id": "d079aec40eb0c6cc",
      "index_key": [
        "`country`"
      ],
      "keyspace_id": "landmark",
      "name": "idx_landmark_country",
      "namespace_id": "default",
      "scope_id": "inventory",
      "state": "online", // ①
      "using": "gsi"
    }
  }
]
```

1. The index has now been created.

<a name="ex-create-idx-missing"></a>**Create index with missing leading key**

For this example, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

The following statement will not index airports where the `district` field is missing.

```n1ql
CREATE INDEX idx_airport_missing
ON airport(district, name);
```

The following statement will index all airports, even if the `district` field is not included in the document.

```n1ql
CREATE INDEX idx_airport_include
ON airport(district INCLUDE MISSING, name);
```

For more examples of indexes where the leading key may be missing, see [Index Selection](n1ql:n1ql-language-reference/selectintro.adoc#index-selection).

<a name="ex-create-rgb-idx"></a>**Create a Composite Vector index**

For this example, you must install the vector sample data as described in [Prerequisites](vector-index:composite-vector-index.adoc#prerequisites).
The path to the required keyspace is specified by the query, so you do not need to set the query context.

Create a Composite Vector index that indexes the vector field named `colorvect_l2`, as well as the scalar `color` and `brightness` fields.

```sqlpp
CREATE INDEX `color_vectors_idx` ON `vector-sample`.`color`.`rgb`
       (`colorvect_l2` VECTOR, color, brightness)
       WITH {  "dimension":3 , "similarity":"L2", "description":"IVF,SQ8"};
```

<a name="ex-create-vectors-idx"></a>**Create a Composite Vector index using embedded vectors**

For this example, you must install the vector sample data as described in [Prerequisites](vector-index:composite-vector-index.adoc#prerequisites).
The path to the required keyspace is specified by the query, so you do not need to set the query context.

Create a Composite Vector index that indexes the vector field named `embedding-vector-dot`, as well as the scalar `color` and `brightness` fields.

```sqlpp
CREATE INDEX `color_desc_idx` ON `vector-sample`.`color`.`rgb` 
     (`embedding_vector_dot` VECTOR, color, brightness) 
     WITH { "dimension":1536, "similarity":"DOT", "description":" IVF,SQ8" }
```

<a name="ex-create-colors-idx"></a>**Create a Composite Vector index with a scalar leading key**

For this example, you must install the vector sample data as described in [Prerequisites](vector-index:composite-vector-index.adoc#prerequisites).
The path to the required keyspace is specified by the query, so you do not need to set the query context.

Create a Composite Vector index that indexes the scalar `color` and `brightness` fields, as well as the vector field named `embedding-vector-dot`.

```sqlpp
CREATE INDEX `color_name_idx` ON `vector-sample`.`color`.`rgb`
     (color, brightness, `embedding_vector_dot` VECTOR)
     WITH { "dimension":1536, "similarity":"DOT", "description":" IVF,SQ8" }
```

## Related Links

* [indexes:indexing-overview.adoc](indexes:indexing-overview.adoc)
* [vector-index:composite-vector-index.adoc](vector-index:composite-vector-index.adoc)
* [vector-index:hyperscale-vector-index.adoc](vector-index:hyperscale-vector-index.adoc)
* [CREATE PRIMARY INDEX](n1ql:n1ql-language-reference/createprimaryindex.adoc)
| [CREATE VECTOR INDEX](n1ql:n1ql-language-reference/createvectorindex.adoc)
* [BUILD INDEX](n1ql:n1ql-language-reference/build-index.adoc)
* [ALTER INDEX](n1ql:n1ql-language-reference/alterindex.adoc)
| [ALTER VECTOR INDEX](n1ql:n1ql-language-reference/altervectorindex.adoc)
* [DROP PRIMARY INDEX](n1ql:n1ql-language-reference/dropprimaryindex.adoc)
| [DROP INDEX](n1ql:n1ql-language-reference/dropindex.adoc)
| [DROP VECTOR INDEX](n1ql:n1ql-language-reference/dropvectorindex.adoc)
