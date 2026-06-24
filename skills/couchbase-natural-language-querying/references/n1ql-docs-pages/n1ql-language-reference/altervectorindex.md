# ALTER VECTOR INDEX

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

The ALTER VECTOR INDEX statement moves the placement of an existing index or replica among different GSI nodes.

The [ALTER INDEX](n1ql-language-reference/alterindex.adoc) statement is a synonym for the ALTER VECTOR INDEX statement.
Both statements have the same functionality.

## Purpose

You can use the `ALTER VECTOR INDEX` statement to change the placement of an existing index or replica among different GSI nodes, to increase or decrease the number of replicas, or to drop a specified index replica temporarily.
You can also use it to perform the same alterations to a partitioned index and any replica partitions.
You may use this statement when you encounter any of the following situations:

* An imbalance occurs due to a particular index growing faster than expected and is needed on a different node.
* An imbalance occurs due to a cluster of indexes being dropped on a single node.
* A machine is scheduled for removal, so its indexes need to move off its current node.
* The automated process of rebalancing does not give the expected results.
* Other types of scaling up or scaling down are needed.

For example, if a node fails, you can use the `ALTER VECTOR INDEX` statement to move an index to another node.
See [Examples](#examples) below.

**📌 NOTE**\
The ALTER VECTOR INDEX move operation is asynchronous.
As soon as the move alter index command is executed, the command returns.
If there is no error in the input, the move operation can be tracked through the console UI and any error can be found in the Console logs and Indexer logs.

If a node goes down while an ALTER VECTOR INDEX operation is happening, then the index would rollback to its original node (not affecting queries) and a notification would appear.

**❗ IMPORTANT**\
It’s not possible to move an index or index replica and change the number of index replicas at the same time.

## Prerequisites

Only users with the RBAC role of `Administrator` are allowed to run the `ALTER VECTOR INDEX` statement.

This statement is applicable only for Standard GSI (Plasma) and MOI Indexes; and hence supported only for Couchbase Server Enterprise Edition nodes.
(Not applicable for Forest DB.)

Altering indexes is only supported in Couchbase Server 5.5 and later; if any nodes in the cluster are running a version of Couchbase Server earlier than 5.5, then this statement will not work.

In addition, altering the number of replicas or deleting an index replica is only supported in Couchbase Server 6.5 and later; if any nodes in the cluster are running a version of Couchbase Server earlier than 6.5, then these operations will not work.

## Syntax

```ebnf
alter-vector-index ::= 'ALTER' 'VECTOR' 'INDEX' ( index-path '.' index-name |
                       index-name 'ON' keyspace-ref ) index-using? index-with
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/alter-vector-index.png)

The ALTER VECTOR INDEX statement provides 2 possible syntaxes for specifying the index and the keyspace where the index is located.

* **index-name**\
(Required) A unique name that identifies the index.
* **index-path**\
(Optional) One possible syntax for specifying the keyspace.
See [Index Path](#index-path).
* **keyspace-ref**\
(Optional) The other possible syntax for specifying the keyspace.
See [Index Name ON Keyspace Reference](#index-name-on-keyspace-reference).
* **index-using**\
(Optional) Specifies the index type.
See [USING Clause](#using-clause).
* **index-with**\
(Required) Specifies options for the index.
See [WITH Clause](#with-clause).

### Index Path

```ebnf
index-path ::= keyspace-full | keyspace-prefix | keyspace-partial
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/index-path.png)

You can use a dotted notation to specify the index and the keyspace on which the index is built.
This syntax provides compatibility with legacy versions of Couchbase Server.
The index path may be a [full keyspace path](#index-path-full-keyspace), a [keyspace prefix](#index-path-keyspace-prefix), or a [keyspace partial](#index-path-keyspace-partial).

**📌 NOTE**\
If there is a hyphen (-) inside the index name or any part of the index path, you must wrap the index name or that part of the index path in backticks ({backtick}&#160;{backtick}).
See the examples on this page.

#### Index Path: Full Keyspace

```ebnf
keyspace-full ::= namespace ':' bucket '.' scope '.' collection
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/keyspace-full.png)

If the index is built on a named collection, the index path may be a full keyspace path, including namespace, bucket, scope, and collection, followed by the index name.
In this case, the [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context) is ignored.

* **namespace**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [namespace](n1ql:n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.
Currently, only the `default` namespace is available.
* **bucket**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [bucket name](n1ql:n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.
* **scope**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [scope name](n1ql:n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.
* **collection**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [collection name](n1ql:n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.

For example, `default:{backtick}travel-sample{backtick}.inventory.airline.{backtick}idx-name{backtick}` indicates the `idx-name` index on the `airline` collection in the `inventory` scope in the `default:{backtick}travel-sample{backtick}` bucket.

#### Index Path: Keyspace Prefix

```ebnf
keyspace-prefix ::= ( namespace ':' )? bucket
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/keyspace-prefix.png)

If the index is built on the default collection in the default scope within a bucket, the index path may be just an optional namespace and the bucket name, followed by the index name.
In this case, the [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context) should not be set.

* **namespace**\
(Optional) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [namespace](n1ql:n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.
Currently, only the `default` namespace is available.
If the namespace name is omitted, the default namespace in the current session is used.
* **bucket**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [bucket name](n1ql:n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.

For example, `default:{backtick}travel-sample{backtick}.def_type` indicates the `def_type` index on the default collection in the default scope in the `default:{backtick}travel-sample{backtick}` bucket.

#### Index Path: Keyspace Partial

```ebnf
keyspace-partial ::= collection
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/keyspace-partial.png)

Alternatively, if the keyspace is a named collection, the index path may be just the collection name, followed by the index name.
In this case, you must set the [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context) to indicate the required namespace, bucket, and scope.

* **collection**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [collection name](n1ql:n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.

For example, `airline.{backtick}idx-name{backtick}` indicates the `idx-name` index on the `airline` collection, assuming that the query context is set.

### Index Name ON Keyspace Reference

```ebnf
keyspace-ref ::= keyspace-path | keyspace-partial
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/keyspace-ref.png)

You can use the index name with the `ON` keyword and a keyspace reference to specify the keyspace on which the index is built.
The keyspace reference may be a [keyspace path](#keyspace-reference-keyspace-path) or a [keyspace partial](#keyspace-reference-keyspace-partial).

**📌 NOTE**\
If there is a hyphen (-) inside the index name or any part of the keyspace reference, you must wrap the index name or that part of the keyspace reference in backticks ({backtick}&#160;{backtick}).
See the examples on this page.

#### Keyspace Reference: Keyspace Path

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

For example, `def_type ON default:{backtick}travel-sample{backtick}` indicates the `def_type` index on the default collection in the default scope in the `default:{backtick}travel-sample{backtick}` bucket.

Similarly, `{backtick}idx-name{backtick} ON default:{backtick}travel-sample{backtick}.inventory.airline` indicates the `idx-name` index on the `airline` collection in the `inventory` scope in the `default:{backtick}travel-sample{backtick}` bucket.

#### Keyspace Reference: Keyspace Partial

```ebnf
keyspace-partial ::= collection
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/keyspace-partial.png)

Alternatively, if the keyspace is a named collection, the keyspace reference may be just the collection name.
In this case, you must set the [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context) to indicate the required namespace, bucket, and scope.

* **collection**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [collection name](n1ql:n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.

For example, `{backtick}idx-name{backtick} ON airline` indicates the `idx-name` index on the `airline` collection, assuming the query context is set.

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

Use the `WITH` clause to specify additional options.

* **expr**\
An object with the following properties.

| Name | Description | Schema |
| --- | --- | --- |
| ***action***<br> __required__ | A string denoting the operation to be performed. The possible values are: move::: Moves an index (or its replicas) to a different node while not making any changes to the index topology -- for example, the number of replicas remains the same. You must use the `nodes` property to specify the target node or nodes. replica_count::: Alters the number of replicas. You must use the `num_replica` property to specify the required number of replicas. You can use the `nodes` property to restrict the placement of index replicas to the specified nodes. The planner decides where to place any new index replicas on the available index nodes, based on the server load. drop_replica::: Drops a specified replica temporarily; for example, to repair a replica. You must use the `replicaId` property to specify the replica to drop. | enum (move, replica_count, drop_replica) |
| ***num_replica***<br> __optional__ | Required if `action` is set to `replica_count`. An integer specifying the number of replicas of the index. The index service will automatically distribute these indexes amongst the index nodes in the cluster for load balancing and high availability purposes. The index service attempts to distribute the replicas based on the server groups in use in the cluster where possible. (You can restrict the number of index nodes available for index and index replica placement using the `nodes` property, described below.) | Integer |
| ***nodes***<br> __optional__ | Required if `action` is set to `move`;<br> Optional if `action` is set to `replica_count`. An array of strings, specifying a list of nodes. If `action` is set to `move`, the node list determines the new destination nodes for the index and its replicas. If `action` is set to `replica_count` and you’re increasing the number of replicas, the node list restricts the set of nodes available for placement of the index and its replicas. However, if `action` is set to `replica_count` and you’re decreasing the number of replicas, the `nodes` property is ignored. NOTE: You cannot use this property if you have enabled file-based index rebalancing. See [Index Rebalance Methods](learn:clusters-and-availability/rebalance.adoc#index-rebalance-methods). | String array |
| ***replicaId***<br> __optional__ | Required if `action` is set to `drop_replica`. An integer, specifying a replica ID. | Integer |

## Usage

If you attempt to alter an index which is still scheduled for background creation, the request fails.

The statement will not work while the cluster is undergoing a rebalance.

### Moving an Index or Index Replicas

When moving an index or index replicas, the number of destination nodes must be the same as the number of nodes on which the index and any replicas are currently placed.
You must specify the full node list, even if you only need to move a single replica.

Likewise, when moving a partitioned index, the number of destination nodes must be the same as the number of nodes on which the index partitions and any replicas are currently placed.
You cannot use this statement to repartition an index across a different number of nodes.

The source and destination node ranges may overlap, for example you may move a partitioned index from `["192.168.0.15:9000", "27.0.0.1:9001"]` to `["192.168.0.15:9000", "127.0.0.1:9002"]`.

### Changing the Replica Count

When changing the number of replicas, the specified number of replicas must be less than the number of index nodes available for placement.
If the specified number of replicas is greater than or equal to the number of index nodes available for placement, then the operation will fail.

If you specify a node list when changing the number of replicas, the specified nodes must include all of the nodes on which the index or index partitions and any index replicas are currently placed.

When increasing the number of replicas, whether you specify a node list or not, no single index node will host more than 1 replica of the same index, or the same partition of the same index.
Replicas are distributed across the available server groups.

When reducing the number of replicas, the index service will first drop unhealthy replicas, where an unhealthy replica is a replica with missing partitions.
After all unhealthy replicas are dropped, the index service will if necessary drop replicas with the highest replica ID.
An unhealthy replica may not have the highest replica ID, so after an index reduction there may be gaps in the sequence of replica IDs -- for example, 1, 2, 4, where replica ID 3 was dropped.

### Dropping a Specific Replica

When dropping a replica, the index topology does not change.
The indexing service remembers the number of partitions and replicas specified for this index.
Given sufficient capacity, the dropped replica is rebuilt after the next rebalance -- although it may be placed on a different index node, depending on the resource usage statistics of the available nodes.

To find the ID of an index replica and see which node it’s placed on, you can use the [Indexes screen in the Couchbase Web Console](manage:manage-ui/manage-ui.adoc#console-indexes) or query the [system:indexes](n1ql-intro/sysinfo.adoc#querying-indexes) catalog.

When dropping a replica, it’s possible to leave a server group with no replica.
For a partitioned index, run a rebalance to move a replica into the vacant server group.

### Index Redistribution

Using this statement to move 1 index at a time may be cumbersome if there are a lot of indexes to be moved.
The index redistribution setting enables you to specify how Couchbase Server redistributes indexes automatically on rebalance.
For more information, see [Rebalance](learn:clusters-and-availability/rebalance.adoc#rebalancing-the-index-service).

## Return Value

If the statement succeeds, then:

* The query returns an empty array.
* The index alteration is visible in the Query Workbench.
* After the movement is complete, the new indexes begin to service query scans.
* The command line displays the new index nodes.

If the statement fails, then:

* The original indexes continue to service query scans.
* The UI Log and Query Workbench has the appropriate error message.
* Some common errors include:

  | Error Message | Possible Cause |
  | --- | --- |
  | `GSI index xxxxxxxx not found` | * Mistyped an index name |
  | `Missing Node Information For Move Index` | * Mistyped `"node"` instead of `"nodes"` * Mistyped punctuation or other item |
  | `No Index Movement Required for Specified Destination List` | * Entered the current node instead of the target node |
  | `syntax error - at \",\"` | * Missed a double-quote mark (`"`) |
  | `Unable to find Index service for destination xxx.xxx.xxx.xxx:8091 or destination is not part of the cluster` | * Address does not exist or was mistyped * Node is not running * Node not properly added to the cluster |
  | `Unsupported action value` | * Mistyped the `"action"` |

## Examples

To try the examples in this section, you must do the following:

1. Create a cluster of 3 nodes.
The examples in this section assume that the 3 nodes have the IP addresses 172.19.0.2, 172.19.0.3, and 172.19.0.4.
The nodes in your cluster may have different names or IP addresses.
2. Install the vector sample data as described in [Prerequisites](vector-index:hyperscale-vector-index.adoc#prerequisites).
3. Set the query context to the `color` scope in the vector sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Create and move an index from one node to another**

Create a Hyperscale Vector index on node 172.19.0.2.

```sqlpp
CREATE VECTOR INDEX hyperscale_idx_move
       ON rgb(embedding_vector_dot VECTOR)
       WITH {"dimension": 1536,
             "similarity": "L2",
             "description": "IVF8,SQ4",
             "nodes": "172.19.0.2:8091"}
```

Then move the index from its original node (172.19.0.**2** in this example) to a new node (172.19.0.**3** in this example).

```sqlpp
ALTER VECTOR INDEX hyperscale_idx_move ON rgb
WITH {"action": "move", "nodes": ["172.19.0.3:8091"]};
```

To check the node where the index is located, see [manage:manage-indexes/manage-indexes.adoc](manage:manage-indexes/manage-indexes.adoc).

**Create and move an index replica from one node to another**

Create a Hyperscale Vector index on node 172.19.0.2 with a replica on node 172.19.0.3, then move its replica from node 172.19.0.**3** to 172.19.0.**4**.

```sqlpp
CREATE VECTOR INDEX hyperscale_rep_move
       ON rgb(embedding_vector_dot VECTOR)
       WITH {"dimension": 1536,
             "similarity": "L2",
             "description": "IVF8,SQ4",
             "nodes": ["172.19.0.2:8091", "172.19.0.3:8091"]};

ALTER VECTOR INDEX hyperscale_rep_move ON rgb
WITH {"action": "move", "nodes": ["172.19.0.2:8091", "172.19.0.4:8091"]};
```

**Increase the number of replicas**

Create a Hyperscale Vector index on node 172.19.0.2 with a replica on nodes 172.19.0.**3**, then increase the number of replicas to 2 and specify that new replicas may be placed on any available index nodes in the cluster.

```sqlpp
CREATE VECTOR INDEX hyperscale_rep_multi
       ON rgb(embedding_vector_dot VECTOR)
       WITH {"dimension": 1536,
             "similarity": "L2",
             "description": "IVF8,SQ4",
             "nodes": ["172.19.0.2:8091", "172.19.0.3:8091"]};

ALTER VECTOR INDEX hyperscale_rep_multi ON rgb
WITH {"action": "replica_count", "num_replica": 2};
```

**Increase the number of replicas and specify the nodes**

Create a Hyperscale Vector index on node 172.19.0.2 with a replica on node 172.19.0.3, then increase the number of replicas to 2, and specify that replicas may be placed on nodes 172.19.0.**3** and 172.19.0.**4**.

```sqlpp
CREATE VECTOR INDEX hyperscale_rep_increase
       ON rgb(embedding_vector_dot VECTOR)
       WITH {"dimension": 1536,
             "similarity": "L2",
             "description": "IVF8,SQ4",
             "nodes": ["172.19.0.2:8091", "172.19.0.3:8091"]};

ALTER VECTOR INDEX hyperscale_rep_increase ON rgb
WITH {"action": "replica_count",
      "num_replica": 2,
      "nodes": ["172.19.0.2:8091",
                "172.19.0.3:8091",
                "172.19.0.4:8091"]};
```

**Decrease the number of replicas**

Create a Hyperscale Vector index on node 172.19.0.2 with replicas on nodes 172.19.0.**3** and 172.19.0.**4**, then decrease the number of replicas to 1.

```sqlpp
CREATE VECTOR INDEX hyperscale_rep_decrease
       ON rgb(embedding_vector_dot VECTOR)
       WITH {"dimension": 1536,
             "similarity": "L2",
             "description": "IVF8,SQ4",
             "nodes": ["172.19.0.2:8091", "172.19.0.3:8091", "172.19.0.4:8091"]};

ALTER VECTOR INDEX hyperscale_rep_decrease ON rgb
WITH {"action": "replica_count", "num_replica": 1};
```

**Drop a specific replica**

Create a Hyperscale Vector index with 2 replicas, and specify that nodes 172.19.0.2, 172.19.0.3, and 172.19.0.4 should be available for index and replica placement.
Then delete replica 2.

```sqlpp
CREATE VECTOR INDEX hyperscale_rep_drop
       ON rgb(embedding_vector_dot VECTOR)
       WITH {"dimension": 1536,
             "similarity": "L2",
             "description": "IVF8,SQ4",
             "num_replica": 2,
             "nodes": ["172.19.0.2:8091",
                       "172.19.0.3:8091",
                       "172.19.0.4:8091"]};

ALTER VECTOR INDEX hyperscale_rep_drop ON rgb
WITH {"action": "drop_replica", "replicaId": 2};
```

## Related Links

* [indexes:indexing-overview.adoc](indexes:indexing-overview.adoc)
* [vector-index:composite-vector-index.adoc](vector-index:composite-vector-index.adoc)
* [vector-index:hyperscale-vector-index.adoc](vector-index:hyperscale-vector-index.adoc)
* [CREATE PRIMARY INDEX](n1ql:n1ql-language-reference/createprimaryindex.adoc)
| [CREATE INDEX](n1ql:n1ql-language-reference/createindex.adoc)
| [CREATE VECTOR INDEX](n1ql:n1ql-language-reference/createvectorindex.adoc)
* [BUILD INDEX](n1ql:n1ql-language-reference/build-index.adoc)
* [ALTER INDEX](n1ql:n1ql-language-reference/alterindex.adoc)
* [DROP PRIMARY INDEX](n1ql:n1ql-language-reference/dropprimaryindex.adoc)
| [DROP INDEX](n1ql:n1ql-language-reference/dropindex.adoc)
| [DROP VECTOR INDEX](n1ql:n1ql-language-reference/dropvectorindex.adoc)
