# DROP COLLECTION

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

The `DROP COLLECTION` statement enables you to delete a named collection from a scope.

## Syntax

```ebnf
drop-collection ::= 'DROP' 'COLLECTION' ( ( namespace ':' )? bucket '.' scope '.' )?
                    collection ( 'IF' 'EXISTS' )?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/drop-collection.png)

* **namespace**\
(Optional) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [namespace](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the bucket which contains the collection you want to delete.
Currently, only the `default` namespace is available.
If the namespace name is omitted, the default namespace in the current session is used.
* **bucket**\
(Optional) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the bucket which contains the collection you want to delete.
* **scope**\
(Optional) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the scope which contains the collection you want to delete.
* **collection**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the name of the collection that you want to delete.

**📌 NOTE**\
If there is a hyphen (-) inside the bucket name, the scope name, or the collection name, you must wrap that part of the path in backticks ({backtick} {backtick}).
For example, `default:{backtick}travel-sample{backtick}` indicates the `travel-sample` keyspace in the `default` namespace.

### Specifying the Location

To specify the location of the collection, you may do one of the following:

* Include its _full path_, containing the namespace, bucket, and scope, followed by the collection name;
* Include a _relative path_, containing just the bucket and scope, followed by the connection name;
* Specify just the collection name without a path.

When you specify a collection name without a path, you must set the [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context) to indicate the required namespace, bucket, and scope.
If you specify a collection name by itself without setting a valid query context, an error is generated.

### IF EXISTS Clause

The optional `IF EXISTS` clause enables the statement to complete successfully when the specified collection doesn’t exist.
If the collection does not exist within the specified scope, then:

* If this clause is not present, an error is generated.
* If this clause is present, the statement does nothing and completes without error.

## Examples

**Delete collection with full path**

This statement deletes a collection called `city` in the `inventory` scope within the `travel-sample` bucket.

```sqlpp
DROP COLLECTION `travel-sample`.inventory.city
```

**Delete collection with query context**

For this example, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

Assuming that the query context is set, this statement deletes a collection called `country` in the `inventory` scope within the `travel-sample` bucket.

```sqlpp
DROP COLLECTION country;
```

## Related Links

* An overview of scopes and collections is provided in [Scopes and Collections](learn:data/scopes-and-collections.adoc).
* Step-by-step procedures for management are provided in [Manage Scopes and Collections](manage:manage-scopes-and-collections/manage-scopes-and-collections.adoc).
* Refer to [Scopes and Collections API](rest-api:scopes-and-collections-api.adoc) to manage scopes and collections with the REST API.
* Refer to the reference page for the [collection-manage](cli:cbcli/couchbase-cli-collection-manage.adoc) command to manage scopes and collections with the CLI.
