# DROP PRIMARY INDEX

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

The DROP PRIMARY INDEX statement allows you to drop a primary index.

**📌 NOTE**\
For compatibility with legacy versions of Couchbase Server, you can also use the DROP INDEX or DROP VECTOR INDEX statement to drop a named primary index.

## Prerequisites

##### RBAC Privileges

To execute the DROP PRIMARY INDEX statement, you must have the `Query Manage Index` privilege granted on the keyspace.
For more information about user roles, see [Roles](learn:security/roles.adoc).

## Syntax

```ebnf
drop-primary-index ::= 'DROP' 'PRIMARY' 'INDEX' ( index-name? ( 'IF' 'EXISTS' )? |
                       'IF' 'EXISTS' index-name ) 'ON' keyspace-ref index-using?
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/drop-primary-index.png)

* **index-name**\
(Optional) A unique name that identifies the index.
If you do not specify a name, the index with the default name of `#primary` is deleted.
* **keyspace-ref**\
(Required) Specifies the keyspace where the index is located.
See [Keyspace Reference](#keyspace-reference).
* **index-using**\
(Optional) Specifies the index type.
See [USING Clause](#using-clause).

### IF EXISTS Clause

The optional `IF EXISTS` clause enables the statement to complete successfully when the specified primary index does not exist.
If the primary index does not exist within the specified keyspace, then:

* If this clause is not present, an error is generated.
* If this clause is present, the statement does nothing and completes without error.

### Keyspace Reference

```ebnf
keyspace-ref ::= keyspace-path | keyspace-partial
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/keyspace-ref.png)

Specifies the keyspace for the primary index to drop.
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

### USING Clause

```ebnf
index-using ::= 'USING' 'GSI'
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/index-using.png)

The index type for a primary index must be Global Secondary Index (GSI).
The `USING GSI` keywords are optional and may be omitted.

## Example

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Drop unnamed primary index**

Create an unnamed primary index on the `airline` keyspace.
Once the index creation statement comes back, query `system:indexes` for status of the index.

```sqlpp
CREATE PRIMARY INDEX ON airline;
SELECT * FROM system:indexes WHERE name = '#primary';
```

Subsequently, drop the unnamed primary index with the following statement so that it’s no longer reported in the `system:indexes` output.

```sqlpp
DROP PRIMARY INDEX ON airline;
SELECT * FROM system:indexes WHERE name = '#primary';
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
* [DROP INDEX](n1ql:n1ql-language-reference/dropindex.adoc)
| [DROP VECTOR INDEX](n1ql:n1ql-language-reference/dropvectorindex.adoc)
