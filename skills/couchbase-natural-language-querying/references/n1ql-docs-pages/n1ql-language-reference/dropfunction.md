# DROP FUNCTION

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

pass:q[The `DROP FUNCTION` statement enables you to delete a user-defined function.]

## Prerequisites

| To manage ... | You must have ... |
| --- | --- |
| Global inline functions | **Manage Global Functions** role. |
| Scoped inline functions | **Manage Scope Functions** role, with permissions on the specified bucket and scope. |
| Global external functions | **Manage Global External Functions** role. |
| Scoped external functions | **Manage Scope External Functions** role, with permissions on the specified bucket and scope. |

For more information about user roles, see
[Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
drop-function ::= 'DROP' 'FUNCTION' function ( 'IF' 'EXISTS' )?
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/drop-function.png)

* **function**\
[Function Name](#function-name) icon:caret-down[]

### Function Name

```ebnf
function ::= ( namespace ':' ( bucket '.' scope '.' )? )? identifier
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/function.png)

The name of the function.
This is usually an unqualified identifier, such as `func1` or `{backtick}func-1{backtick}`.
In this case, the path to the function is determined by the current [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

To delete a global function in a particular namespace, the function name must be a qualified identifier with a namespace, such as `default:func1`.
Similarly, to delete a scoped function in a particular scope, the function name must be a qualified identifier with the full path to a scope, such as `default:{backtick}travel-sample{backtick}.inventory.func1`.
For more information, see [Global Functions and Scoped Functions](n1ql-language-reference/createfunction.adoc#context).

**📌 NOTE**\
The name of a user-defined function is case-sensitive, unlike that of a built-in function.
You must delete the user-defined function using the same case that was used when it was created.

### IF EXISTS Clause

The optional `IF EXISTS` clause enables the statement to complete successfully when the specified function does not exist.

When the function does not exist within the specified context:
footnote:context[In other words, you’re dropping a global function, and the function does not exist within the specified namespace; or, you’re dropping a scoped function, and the function does not exist within the specified scope.]

* If this clause is not present, an error is generated.
* If this clause is present, the statement does nothing and completes without error.

## Usage

When you drop a user-defined function whose definition is stored in a JavaScript library, the JavaScript library and function on which the user-defined function depended are not deleted.
This enables you to create a new user-defined function with a different name, or a different number of parameters, using the same JavaScript library and function.

To change or delete a JavaScript library or the JavaScript function code, you must use the [Couchbase Web Console](guides:javascript-udfs.adoc) or the {sqlpp} [Functions REST API](n1ql-rest-functions:index.adoc).

When you drop a {sqlpp} managed JavaScript function, the associated JavaScript function code is also deleted.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Drop an inline function**

This statement deletes an inline function called `celsius`.

```sqlpp
DROP FUNCTION celsius;
```

You can run the following query to check that the function is no longer available.

```sqlpp
SELECT * FROM system:functions;
```

**Drop a {sqlpp} managed JavaScript function**

This statement deletes a {sqlpp} managed JavaScript function called `add100`.

```sqlpp
DROP FUNCTION add100 IF EXISTS;
```

You can run the following query to check that the function is no longer available.

```sqlpp
SELECT * FROM system:functions;
```

**Drop an external function**

These statements delete two external functions:

1. A function called `geohash`, which depends on the JavaScript `encodeGeoHash` function in the `geohash-js` library;
2. A function called `adjacent`, which depends on the JavaScript `calculateAdjacent` function in the `geohash-js` library.

```sqlpp
DROP FUNCTION geohash;

DROP FUNCTION adjacent;
```

You can run the following command to check that the JavaScript `geohash-js` library and the `encodeGeoHash` and `calculateAdjacent` functions are still available.

```sh
curl -v -X GET \
http://localhost:8093/evaluator/v1/libraries/geohash-js \
-u Administrator:password
```

## Related Links

* For an introduction to user-defined functions, see [guides:javascript-udfs.adoc](guides:javascript-udfs.adoc).
* For more information about JavaScript functions, see [javascript-udfs:javascript-functions-with-couchbase.adoc](javascript-udfs:javascript-functions-with-couchbase.adoc).
* To manage JavaScript libraries, see [n1ql-rest-functions:index.adoc](n1ql-rest-functions:index.adoc).
* To create user-defined functions, see [n1ql-language-reference/createfunction.adoc](n1ql-language-reference/createfunction.adoc).
* To execute a user-defined function, see [n1ql-language-reference/execfunction.adoc](n1ql-language-reference/execfunction.adoc).
* To see the execution plan for a user-defined function, see [n1ql-language-reference/explainfunction.adoc](n1ql-language-reference/explainfunction.adoc).
* To include a user-defined function in an expression, see [n1ql-language-reference/userfun.adoc](n1ql-language-reference/userfun.adoc).
* To monitor user-defined functions, see [Monitor Functions](n1ql:n1ql-intro/sysinfo.adoc#sys-functions).
