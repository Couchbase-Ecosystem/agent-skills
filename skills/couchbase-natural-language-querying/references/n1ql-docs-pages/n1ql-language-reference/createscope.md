# CREATE SCOPE

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

pass:q[The `CREATE SCOPE` statement enables you to create a scope.]

## Syntax

```ebnf
create-scope ::= 'CREATE' 'SCOPE' ( namespace ':' )? bucket '.' scope ( 'IF' 'NOT' 'EXISTS' )?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/create-scope.png)

* **namespace**\
(Optional) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [namespace](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the bucket in which you want to create the scope.
Currently, only the `default` namespace is available.
If the namespace name is omitted, the default namespace in the current session is used.
* **bucket**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the bucket in which you want to create the scope.
* **scope**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the name of the scope that you want to create.
Refer to [Naming for Scopes and Collections](learn:data/scopes-and-collections.adoc#naming-for-scopes-and-collections) for restrictions on scope names.

**📌 NOTE**\
If there is a hyphen (-) inside the bucket name or the scope name, you must wrap that part of the path in backticks ({backtick} {backtick}).
For example, `default:{backtick}travel-sample{backtick}` indicates the `travel-sample` keyspace in the `default` namespace.

### IF NOT EXISTS Clause

The optional `IF NOT EXISTS` clause enables the statement to complete successfully when the specified scope already exists.
If a scope with the same name already exists within the specified bucket, then:

* If this clause is not present, an error is generated.
* If this clause is present, the statement does nothing and completes without error.

## Example

This statement creates a scope called `events` in the `travel-sample` bucket.

```sqlpp
CREATE SCOPE `travel-sample`.events
```

## Related Links

* An overview of scopes and collections is provided in [Scopes and Collections](learn:data/scopes-and-collections.adoc).
* Step-by-step procedures for management are provided in [Manage Scopes and Collections](manage:manage-scopes-and-collections/manage-scopes-and-collections.adoc).
* Refer to [Scopes and Collections API](rest-api:scopes-and-collections-api.adoc) to manage scopes and collections with the REST API.
* Refer to the reference page for the [collection-manage](cli:cbcli/couchbase-cli-collection-manage.adoc) command to manage scopes and collections with the CLI.
