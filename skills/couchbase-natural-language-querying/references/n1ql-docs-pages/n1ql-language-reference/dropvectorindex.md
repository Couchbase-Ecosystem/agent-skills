# DROP VECTOR INDEX

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

The DROP VECTOR INDEX statement allows you to drop a Hyperscale Vector index, a Composite Vector index, or a secondary index.
Dropping an index that has replicas will drop all of the replica indexes too.

The [DROP INDEX](n1ql-language-reference/dropindex.adoc) statement is a synonym for the DROP VECTOR INDEX statement.
Both statements have the same functionality.

To drop a primary index, use the [DROP PRIMARY INDEX](n1ql-language-reference/dropprimaryindex.adoc) statement.
For compatibility with legacy versions of Couchbase Server, you can also use DROP INDEX or DROP VECTOR INDEX to drop a named primary index.

## Prerequisites

##### RBAC Privileges

To use the DROP VECTOR INDEX statement, you must have the `Query Manage Index` privilege on the keyspace or bucket.
For more information about user roles, see
[Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
drop-vector-index ::= 'DROP' 'VECTOR' 'INDEX' ( index-path-and-name | index-name-on-keyspace )
                      index-using?
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/drop-vector-index.png)

The DROP VECTOR INDEX statement provides two possible syntaxes for specifying the index and the keyspace where the index is located.

* **index-path-and-name**\
(Optional) One possible syntax for specifying the index and keyspace.
See [Index Path and Name](#index-path-and-name).
* **index-name-on-keyspace**\
(Optional) The other possible syntax for specifying the index and keyspace.
See [Index Name ON Keyspace Reference](#index-name-on-keyspace-reference).
* **index-using**\
(Optional) Specifies the index type.
See [USING Clause](#using-clause).

### Index Path and Name

```ebnf
index-path-and-name ::= index-path '.' index-name ( 'IF' 'EXISTS' )? |
                        'IF' 'EXISTS' index-path '.' index-name
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/index-path-and-name.png)

You can use a dotted notation to specify the index and the keyspace on which the index is built.
This syntax provides compatibility with legacy versions of Couchbase Server.

* **index-name**\
(Required) A unique name that identifies the index.
* **index-path**\
(Required) See [Index Path](#index-path).

**📌 NOTE**\
If there is a hyphen (-) inside the index name or any part of the index path, you must wrap the index name or that part of the index path in backticks ({backtick}&#160;{backtick}).
See the examples on this page.

#### Index Path

```ebnf
index-path ::= keyspace-full | keyspace-prefix | keyspace-partial
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/index-path.png)

The index path may be a [full keyspace path](#index-path-full-keyspace), a [keyspace prefix](#index-path-keyspace-prefix), or a [keyspace partial](#index-path-keyspace-partial).

##### Index Path: Full Keyspace

```ebnf
keyspace-full ::= namespace ':' bucket '.' scope '.' collection
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/keyspace-full.png)

If the index is built on a named collection, the index path may be a full keyspace path, including namespace, bucket, scope, and collection, followed by the index name.
In this case, the [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context) is ignored.

* **namespace**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [namespace](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.
Currently, only the `default` namespace is available.
* **bucket**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [bucket name](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.
* **scope**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [scope name](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.
* **collection**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [collection name](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.

For example, `default:{backtick}travel-sample{backtick}.inventory.airline.{backtick}idx-name{backtick}` indicates the `idx-name` index on the `airline` collection in the `inventory` scope in the `default:{backtick}travel-sample{backtick}` bucket.

##### Index Path: Keyspace Prefix

```ebnf
keyspace-prefix ::= ( namespace ':' )? bucket
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/keyspace-prefix.png)

If the index is built on the default collection in the default scope within a bucket, the index path may be just an optional namespace and the bucket name, followed by the index name.
In this case, the [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context) should not be set.

* **namespace**\
(Optional) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [namespace](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.
Currently, only the `default` namespace is available.
If the namespace name is omitted, the default namespace in the current session is used.
* **bucket**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [bucket name](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.

For example, `default:{backtick}travel-sample{backtick}.def_type` indicates the `def_type` index on the default collection in the default scope in the `default:{backtick}travel-sample{backtick}` bucket.

##### Index Path: Keyspace Partial

```ebnf
keyspace-partial ::= collection
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/keyspace-partial.png)

Alternatively, if the keyspace is a named collection, the index path may be just the collection name, followed by the index name.
In this case, you must set the [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context) to indicate the required namespace, bucket, and scope.

* **collection**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [collection name](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.

For example, `airline.{backtick}idx-name{backtick}` indicates the `idx-name` index on the `airline` collection, assuming that the query context is set.

### Index Name ON Keyspace Reference

```ebnf
index-name-on-keyspace ::= ( index-name ( 'IF' 'EXISTS' )? | 'IF' 'EXISTS' index-name )
                           'ON' keyspace-ref
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/index-name-on-keyspace.png)

You can use the index name with the `ON` keyword and a keyspace reference to specify the index and the keyspace on which the index is built.

* **index-name**\
(Required) A unique name that identifies the index.
* **keyspace-ref**\
(Required) See [Keyspace Reference](#keyspace-reference).

**📌 NOTE**\
If there is a hyphen (-) inside the index name or any part of the keyspace reference, you must wrap the index name or that part of the keyspace reference in backticks ({backtick}&#160;{backtick}).
See the examples on this page.

#### Keyspace Reference

```ebnf
keyspace-ref ::= keyspace-path | keyspace-partial
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/keyspace-ref.png)

The keyspace reference may be a [keyspace path](#keyspace-reference-keyspace-path) or a [keyspace partial](#keyspace-reference-keyspace-partial).

##### Keyspace Reference: Keyspace Path

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

For example, `def_type ON default:{backtick}travel-sample{backtick}` indicates the `def_type` index on the default collection in the default scope in the `default:{backtick}travel-sample{backtick}` bucket.

Similarly, `{backtick}idx-name{backtick} ON default:{backtick}travel-sample{backtick}.inventory.airline` indicates the `idx-name` index on the `airline` collection in the `inventory` scope in the `default:{backtick}travel-sample{backtick}` bucket.

##### Keyspace Reference: Keyspace Partial

```ebnf
keyspace-partial ::= collection
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/keyspace-partial.png)

Alternatively, if the keyspace is a named collection, the keyspace reference may be just the collection name.
In this case, you must set the [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context) to indicate the required namespace, bucket, and scope.

* **collection**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [collection name](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.

For example, `{backtick}idx-name{backtick} ON airline` indicates the `idx-name` index on the `airline` collection, assuming the query context is set.

### IF EXISTS Clause

The optional `IF EXISTS` clause enables the statement to complete successfully when the specified index does not exist.
If the index does not exist within the specified keyspace, then:

* If this clause is not present, an error is generated.
* If this clause is present, the statement does nothing and completes without error.

### USING Clause

```ebnf
index-using ::= 'USING' 'GSI'
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/index-using.png)

The index type for a secondary index must be Global Secondary Index (GSI).
The `USING GSI` keywords are optional and may be omitted.

## Usage

When using memory-optimized indexes, DROP VECTOR INDEX is an expensive operation and may take a few minutes to complete.

If you drop an index with replicas while one of the index nodes is failed over, then only the replicas in the active index nodes are dropped.
If the failed-over index node is recovered, then the orphan replica will be dropped when this failed-over indexer is added back to cluster.

If you drop an index with replicas when one of the index nodes is unavailable but not failed over, the drop index operation may fail.

If you drop an index which is scheduled for background creation, a warning message is generated, but the drop index operation succeeds.

<dl><dt><strong>❗ IMPORTANT: Attention</strong></dt><dd>

Do not drop (or create) secondary indexes, Composite Vector indexes, or Hyperscale Vector indexes when any Index service node is down, as this may result in duplicate index names.
</dd></dl>

## Examples

To try the examples in this section, you must install the vector sample data as described in [Prerequisites](vector-index:hyperscale-vector-index.adoc#prerequisites).

<a name="ex-1"></a>**Drop a Hyperscale Vector index**

For this example, the path to the required keyspace is specified by the query, so you do not need to set the query context.

Drop the Hyperscale Vector index called `color_desc_hyperscale`, if it exists.

```sqlpp
DROP VECTOR INDEX `color_desc_hyperscale`
     IF EXISTS
     ON `vector-sample`.color.rgb
```

The following command would drop the index in exactly the same way, but uses alternative syntax.

```sqlpp
DROP VECTOR INDEX IF EXISTS
     default:`vector-sample`.color.rgb.`color_desc_hyperscale`
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
| [ALTER VECTOR INDEX](n1ql:n1ql-language-reference/altervectorindex.adoc)
* [DROP PRIMARY INDEX](n1ql:n1ql-language-reference/dropprimaryindex.adoc)
| [DROP INDEX](n1ql:n1ql-language-reference/dropindex.adoc)
