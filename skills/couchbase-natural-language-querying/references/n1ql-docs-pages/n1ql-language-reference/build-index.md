# BUILD INDEX

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

The BUILD INDEX statement enables you to build one or more GSI indexes that are marked for deferred building all at once.

By default, CREATE INDEX or CREATE VECTOR INDEX starts building the created index after the creation stage is complete.
However for more efficient building of multiple indexes, CREATE INDEX or CREATE VECTOR INDEX can mark indexes for deferred building using the `defer_build:true` option.
BUILD INDEX is capable of building multiple indexes at once, and can utilize a single scan of documents in the keyspace to feed many index build operations.

BUILD INDEX is an asynchronous operation.
BUILD INDEX creates a task to build the primary or secondary GSI indexes and returns as soon as the task is queued for execution.
The full index build operation happens in the background.

Index metadata provides a state field.
The index state may be `scheduled for creation`, `deferred`, `building`, `pending`, `online`, `offline`, or `abridged`.
This state field and other index metadata can be queried using [system:indexes](n1ql-intro/sysinfo.adoc#querying-indexes).
You can also monitor the index state using the Couchbase Web Console.

If you attempt to build an index which is still scheduled for background creation, the request fails.

<dl><dt><strong>❗ IMPORTANT</strong></dt><dd>

If you kick off multiple index build operations concurrently, then you may sometimes see transient errors similar to the following.

```json
[
  {
    "code": 5000,
    "msg": "GSI CreateIndex() - cause: Encountered transient error.  Index creation will be retried in background.  Error: Index ... will retry building in the background for reason: Build Already In Progress. Keyspace ...",
    "query": "..."
  }
]
```

To work around this issue, wait for index building to complete (that is, for all indexes to get to the online state), then issue the BUILD INDEX command again.
</dd></dl>

BUILD INDEX is also idempotent.
On execution, the statement only builds indexes which have not already been built.
If any of the indexes specified by BUILD INDEX have already been built, BUILD INDEX skips those indexes.

When building an index which has automatic index replicas, all of the replicas are also built as part of the BUILD INDEX statement, without having to manually specify them.

Hyperscale Vector indexes and Composite Vector indexes require a codebook for the vector field.
The codebook is the result of sampling the dataset and is saved as part of the index metadata.

The codebook is created as part of the BUILD INDEX process, and is not incrementally updated.
If the data set changes dramatically, you must drop and rebuild the index to update the codebook.

## Prerequisites

##### RBAC Privileges

User executing the BUILD INDEX statement must have the _Query Manage Index_ privilege granted on the keyspace.
For more details about user roles, see
[Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
build-index ::= 'BUILD' 'INDEX' 'ON' keyspace-ref '(' index-term (',' index-term)* ')'
                index-using?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/build-index.png)

* **keyspace-ref**\
(Required) Specifies the keyspace where the indexes are built.
Refer to [Keyspace Reference](#keyspace-reference) below.
* **index-term**\
(Required) Specifies the indexes to build.
Refer to [Index Term](#index-term) below.
* **index-using**\
(Optional) Specifies the index type.
Refer to [USING Clause](#using-clause) below.

### Keyspace Reference

```ebnf
keyspace-ref ::= keyspace-path | keyspace-partial
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-ref.png)

```ebnf
keyspace-path ::= ( namespace ':' )? bucket ( '.' scope '.' collection )?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-path.png)

```ebnf
keyspace-partial ::= collection
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-partial.png)

The simple name or fully-qualified name of the keyspace on which to build the index.
Refer to the [CREATE INDEX](n1ql-language-reference/createindex.adoc#keyspace-ref) statement for details of the syntax.

### Index Term

```ebnf
index-term ::= index-name | index-expr | subquery-expr
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/index-term.png)

You can specify one index term, or multiple index terms separated by commas.
An index term must be specified for each index to be built.

Each index term may be an [index name](#index-name), an [index expression](#index-expression), or a [subquery expression](#subquery-expression).
The BUILD INDEX clause may contain a mixture of the different types of index term.

#### Index Name

```ebnf
index-name ::= identifier
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/index-name.png)

An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the name of an index.

```sqlpp
BUILD INDEX ON keyspace(ix1, ix2, ix3);
```

#### Index Expression

```ebnf
index-expr ::= string | array
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/index-expr.png)

An [expression](n1ql-language-reference/index.adoc) that may be a string, or an array of strings, each referring to the name of an index.

```sqlpp
BUILD INDEX ON keyspace('ix1', 'ix2', 'ix3');
BUILD INDEX ON keyspace(['ix1', 'ix2', 'ix3']);
BUILD INDEX ON keyspace('ix1', ['ix2', 'ix3'], ['ix4']);
```

<dl><dt><strong>❗ IMPORTANT</strong></dt><dd>

Arrays of identifiers are _not_ permitted.

```sqlpp
BUILD INDEX ON keyspace([ix1, ix2, ix3]);
BUILD INDEX ON keyspace([ix1], [ix2, ix3]);
```
</dd></dl>

#### Subquery Expression

```ebnf
subquery-expr ::= '(' select ')'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/subquery-expr.png)

Use parentheses to specify a subquery.

The subquery must return an array of strings, each string representing the name of an index.
See [Build all indexes](#ex-build-idx-all) for details.

For more details and examples, see [SELECT Clause](n1ql-language-reference/selectclause.adoc) and [Subqueries](n1ql-language-reference/subqueries.adoc).

### USING Clause

```ebnf
index-using ::= 'USING' 'GSI'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/index-using.png)

The index type for a deferred index build must be Global Secondary Index (GSI).
The `USING GSI` keywords are optional and may be omitted.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-create-idx-defer"></a>**Create deferred indexes**

Create a set of primary and secondary indexes in the `landmark` keyspace with the `defer_build` option.

```sqlpp
CREATE INDEX idx_landmark_country
  ON landmark(country)
  USING GSI
  WITH {"defer_build":true};
```

```sqlpp
CREATE INDEX idx_landmark_name 
  ON landmark(name)
  USING GSI
  WITH {"defer_build":true};
```

```sqlpp
CREATE PRIMARY INDEX idx_landmark_primary
  ON landmark
  USING GSI
  WITH {"defer_build":true};
```

<a name="ex-check-idx-defer"></a>**Check deferred index status**

Query `system:indexes` for the status of an index.

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

1. Note that the index is in the deferred state.

<a name="ex-build-idx-single"></a>**Build a named index**

Kick off a deferred build using the index name.

```sqlpp
BUILD INDEX ON landmark(idx_landmark_country) USING GSI;
```

<a name="ex-build-idx-all"></a>**Build all indexes**

Alternatively, kick off all deferred builds in the keyspace, using a subquery to find the deferred builds.

```sqlpp
BUILD INDEX ON landmark (( -- ①
  SELECT RAW name -- ②
  FROM system:indexes
  WHERE keyspace_id = 'landmark'
    AND scope_id = 'inventory'
    AND bucket_id = 'travel-sample'
    AND state = 'deferred' ));
```

1. One set of parentheses delimits the whole group of index terms, and another set of parentheses delimits the subquery.
In this case there is a double set of parentheses, as the subquery is the only index term.
2. The `RAW` keyword forces the subquery to return a flattened array of strings, each of which refers to an index name.

Note that it is only possible to kick off all deferred builds in a single collection -- it is not possible to kick off all deferred builds in all collections in all scopes within a bucket.

<a name="ex-check-idx-online"></a>**Check online index status**

Query `system:indexes` for the status of an index.

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

1. Note that the index has now been created.

## Related Links

* [indexes:indexing-overview.adoc](indexes:indexing-overview.adoc)
* [vector-index:composite-vector-index.adoc](vector-index:composite-vector-index.adoc)
* [vector-index:hyperscale-vector-index.adoc](vector-index:hyperscale-vector-index.adoc)
* [CREATE PRIMARY INDEX](n1ql:n1ql-language-reference/createprimaryindex.adoc)
| [CREATE INDEX](n1ql:n1ql-language-reference/createindex.adoc)
| [CREATE VECTOR INDEX](n1ql:n1ql-language-reference/createvectorindex.adoc)
* [ALTER INDEX](n1ql:n1ql-language-reference/alterindex.adoc)
| [ALTER VECTOR INDEX](n1ql:n1ql-language-reference/altervectorindex.adoc)
* [DROP PRIMARY INDEX](n1ql:n1ql-language-reference/dropprimaryindex.adoc)
| [DROP INDEX](n1ql:n1ql-language-reference/dropindex.adoc)
| [DROP VECTOR INDEX](n1ql:n1ql-language-reference/dropvectorindex.adoc)
