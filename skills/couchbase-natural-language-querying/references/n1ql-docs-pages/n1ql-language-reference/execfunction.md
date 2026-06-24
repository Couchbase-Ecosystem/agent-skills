# EXECUTE FUNCTION

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

The `EXECUTE FUNCTION` statement enables you to execute a user-defined function.

## Purpose

The `EXECUTE FUNCTION` statement enables you to execute a user-defined function.
It’s useful for testing user-defined functions outside the context of a query.
It also enables you to execute functions which have side effects, such as performing mutations, which is not possible when calling a user-defined function in an expression.

You cannot use the `EXECUTE FUNCTION` statement to execute a built-in {sqlpp} function.
If you do this, error `10101: Function not found` is generated.

## Prerequisites

| To execute ... | You must have ... |
| --- | --- |
| Global inline functions | **Execute Global Functions** role. |
| Scoped inline functions | **Execute Scope Functions** role, with permissions on the specified bucket and scope. |
| Global external functions | **Execute Global External Functions** role. |
| Scoped external functions | **Execute Scope External Functions** role, with permissions on the specified bucket and scope. |

For more information about user roles, see
[Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
execute-function ::= 'EXECUTE' 'FUNCTION' function '(' ( expr ( ',' expr )* )? ')'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/execute-function.png)

* **function**\
[Function Name](#function-name) icon:caret-down[]
* **expr**\
[Arguments](#arguments) icon:caret-down[]

### Function Name

```ebnf
function ::= ( namespace ':' ( bucket '.' scope '.' )? )? identifier
```

![Syntax diagram](../../assets/images/n1ql-language-reference/function.png)

The name of the function.
This is usually an unqualified identifier, such as `func1` or `{backtick}func-1{backtick}`.
In this case, the path to the function is determined by the current [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

To execute a global function in a particular namespace, the function name must be a qualified identifier with a namespace, such as `default:func1`.
Similarly, to execute a scoped function in a particular scope, the function name must be a qualified identifier with the full path to a scope, such as `default:{backtick}travel-sample{backtick}.inventory.func1`.
For more information, see [Global Functions and Scoped Functions](n1ql-language-reference/createfunction.adoc#context).

**📌 NOTE**\
The name of a user-defined function is case-sensitive, unlike that of a built-in function.
You must execute the user-defined function using the same case that was used when it was created.

### Arguments

[Optional] Comma-separated expressions specify arguments for the function.
If the function was created with named parameters, you must supply all the arguments that were specified when the function was created.
If the function was created without named parameters, you cannot supply an argument.
If the function is variadic, you can supply as many arguments as needed, or none.

## Return Value

The function returns one value, of any valid {sqlpp} type.
The result (and the data type of the result) depend on the expression or code that were used to define the function.

If you supply the wrong number of arguments, or arguments with the wrong data type, the possible results differ, depending on whether the function is variadic, or requires a definite number of arguments.

If the function requires a definite number of arguments:

* If you do not supply enough arguments, the function generates error `10104: Incorrect number of arguments`.
* If you supply too many arguments, the function generates error `10104: Incorrect number of arguments`.
* If any of the arguments have the wrong data type, the function may return unexpected results, depending on the function expression or code.

If the function is variadic:

* If you do not supply enough arguments, the function may return unexpected results, depending on the function expression or code.
* If you supply too many arguments, the extra parameters are ignored.
* If any of the arguments have the wrong data type, the function may return unexpected results, depending on the function expression or code.

## Examples

For examples, see [CREATE FUNCTION](n1ql-language-reference/createfunction.adoc#examples).

## Related Links

* For an introduction to user-defined functions, see [guides:javascript-udfs.adoc](guides:javascript-udfs.adoc).
* For more information about JavaScript functions, see [javascript-udfs:javascript-functions-with-couchbase.adoc](javascript-udfs:javascript-functions-with-couchbase.adoc).
* To manage JavaScript libraries, see [n1ql-rest-functions:index.adoc](n1ql-rest-functions:index.adoc).
* To create user-defined functions, see [n1ql-language-reference/createfunction.adoc](n1ql-language-reference/createfunction.adoc).
* To see the execution plan for a user-defined function, see [n1ql-language-reference/explainfunction.adoc](n1ql-language-reference/explainfunction.adoc).
* To include a user-defined function in an expression, see [n1ql-language-reference/userfun.adoc](n1ql-language-reference/userfun.adoc).
* To monitor user-defined functions, see [Monitor Functions](n1ql:n1ql-intro/sysinfo.adoc#sys-functions).
* To drop a user-defined function, see [n1ql-language-reference/dropfunction.adoc](n1ql-language-reference/dropfunction.adoc).
