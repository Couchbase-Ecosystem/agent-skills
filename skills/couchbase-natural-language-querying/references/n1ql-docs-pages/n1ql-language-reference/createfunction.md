# CREATE FUNCTION

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

pass:q[The `CREATE FUNCTION` statement enables you to create a user-defined function.]

## Purpose

Couchbase Server supports two types of user-defined function in {sqlpp} for Query:

* **Inline functions** are defined using {sqlpp} expressions.
Use an inline function to reuse complex or repetitive expressions, including subqueries, and simplify your {sqlpp} queries.
* **External functions** are defined using an external language.
They enable you to create functions that may be difficult or impossible to define using built-in {sqlpp} expressions.
The only supported language is JavaScript.

JavaScript functions in the Query Service support most of the language constructs available in ECMAScript.
For more information about the restrictions and extensions that come with the Couchbase implementation, see [javascript-udfs:javascript-functions-with-couchbase.adoc](javascript-udfs:javascript-functions-with-couchbase.adoc).

### {sqlpp} Managed User-Defined Functions

In Couchbase Server 7.6 and later, you can create the code for an external function and the corresponding {sqlpp} user-defined function in a single operation.
This means that you do not have to specify an external library and create the code for the external function, before creating the {sqlpp} user-defined function.

With a {sqlpp} managed user-defined function, the external function code is stored inline, along with the {sqlpp} user-defined function.
You cannot share this external function code with other user-defined functions, or access it from any external libraries.

### External Libraries

(((library namespacing)))
You can store JavaScript functions in external libraries.
This enables you to share external function code for use in more than one {sqlpp} user-defined function.
A library can contain one or more JavaScript functions.

You must create the external library and the external function code using the [Query Workbench](tools:udfs-ui.adoc) or the {sqlpp} [Functions REST API](n1ql-rest-functions:index.adoc).

External libraries, like {sqlpp} user-defined functions, may be scoped or global.
Set an external library or user-defined function as **Scoped** to keep the code for external functions separate.

Code which is stored in a scoped library is private to users of that scope, and is not visible or available to users of another scope.
Code which is stored in a global library is available to users of all scopes.

A global library may have the same name as a scoped library, and scoped libraries may have the same name as each other.
For example, you can have a global `math` library, and a `math` library in each scope.

### Global Functions and Scoped Functions

You can create user-defined functions at two different levels of the {sqlpp} [logical hierarchy](n1ql-intro/queriesandresults.adoc#logical-hierarchy).

* A ((global function)) is created within a namespace, at the same level as the buckets within the namespace.
When you call a global function, any partial keyspace references within the function definition are resolved against the function’s namespace, regardless of the current [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

  For example, when you call a global function `default:global()` which contains the keyspace reference `{backtick}travel-sample{backtick}`, the keyspace reference is always resolved within the context of the function to the `default:{backtick}travel-sample{backtick}` bucket.
* A ((scoped function)) is created within a scope, at the same level as the collections within the scope.
When you call a scoped function, any partial keyspace references within the function definition are resolved against the function’s scope, regardless of the current [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

  For example, when you call a scoped function `default:{backtick}travel-sample{backtick}.inventory.scope()` which contains the keyspace reference `route`, the keyspace reference is always resolved within the context of the function to `default:{backtick}travel-sample{backtick}.inventory.route`.

When you create a user-defined function, the current query context determines whether it’s created as a global function or a scoped function.
If you want to create a user-defined function outside of the current query context, you must include the full path to the function when you specify the function name.

Similarly, when you call a user-defined function, the current query context determines the path to the function.
If you want to call a user-defined function outside of the current query context, you must include the full path to the function when you specify the function name.

**📌 NOTE**\
A global function is not the same as a scoped function stored in the default scope in a bucket.

## Prerequisites

| To manage ... | You must have ... |
| --- | --- |
| Global inline functions | **Manage Global Functions** role. |
| Scoped inline functions | **Manage Scope Functions** role, with permissions on the specified bucket and scope. |
| Global external functions | **Manage Global External Functions** role. |
| Scoped external functions | **Manage Scope External Functions** role, with permissions on the specified bucket and scope. |

Users with the **Manage Scope External Functions** role also have read-only access to any global JavaScript library.

| To execute ... | You must have ... |
| --- | --- |
| Global inline functions | **Execute Global Functions** role. |
| Scoped inline functions | **Execute Scope Functions** role, with permissions on the specified bucket and scope. |
| Global external functions | **Execute Global External Functions** role. |
| Scoped external functions | **Execute Scope External Functions** role, with permissions on the specified bucket and scope. |

For more information about user roles, see
[Authorization](learn:security/authorization-overview.adoc).

## Syntax

The `CREATE FUNCTION` statement takes a different syntax depending on the type of function you’re creating.
See [Inline Functions](#inline-functions) or [External Functions](#external-functions) below.

```ebnf
create-function ::= create-function-inline | create-function-external
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/create-function.png)

### Inline Functions

The CREATE FUNCTION statement provides two possible syntaxes for defining an inline function: a syntax with braces `{}` and a syntax using the `LANGUAGE` keyword.
The two syntaxes are synonymous.

```ebnf
create-function-inline ::= 'CREATE' ( 'OR' 'REPLACE' )? 'FUNCTION' function '(' params? ')'
                           ( 'IF' 'NOT' 'EXISTS' )?
                           ( '{' body '}' | 'LANGUAGE' 'INLINE' 'AS' body )
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/create-function-inline.png)

* **function**\
[inline-name](#inline-name) icon:caret-down[]
* **params**\
[inline-parameter](#inline-parameter) icon:caret-down[]
* **body**\
[Function Body](#function-body) icon:caret-down[]

#### OR REPLACE / IF NOT EXISTS

The optional `OR REPLACE` clause enables you to redefine a user-defined function if it already exists, whereas the optional `IF NOT EXISTS` clause enables the statement to complete successfully without replacing the function.

When a function with the same name already exists within the same context:
footnote:context[In other words, you’re creating a global function, and a function with the same name already exists within the same namespace; or, you’re creating a scoped function, and a function with the same name already exists within the same scope.]

* If the `OR REPLACE` clause is present, the existing function is replaced.
* If the `IF NOT EXISTS` clause is present, the statement does nothing and completes without error.
* If neither of these two clauses is present, an error is generated.

**📌 NOTE**\
These clauses are exclusive.
If the statement contains both the `OR REPLACE` clause and the `IF NOT EXISTS` clause, an error is generated.

#### Function Name

```ebnf
function ::= ( namespace ':' ( bucket '.' scope '.' )? )? identifier
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/function.png)

The function name specifies the name of the function to create.
It’s recommended to use an unqualified identifier for the function name, such as `func1` or `{backtick}func-1{backtick}`.
In this case, the function is created as a global function or a scoped function, depending on the current query context.

To create a global function in a particular namespace, the function name must be a qualified identifier with a namespace, such as `default:func1`.
Similarly, to create a scoped function in a particular scope, the function name must be a qualified identifier with the full path to a scope, such as `default:{backtick}travel-sample{backtick}.inventory.func1`.

If the function name is an unqualified identifier, it may not be the same as a reserved keyword.
A function name with a specified namespace or scope may have the same name as a reserved keyword.

The function name must be unique within its scope or namespace.
You cannot have two functions with the same name inside the same scope or namespace.
You can have two functions with the same name across different scopes or namespaces.

#### Function Parameters

```ebnf
params ::= identifier ( "," identifier )* | "..."
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/params.png)

[Optional] The function parameter list specifies parameters for the function.
If you specify named parameters for the function, then you must call the function with exactly the same number of arguments at execution time.
If you specify no parameters, then you must call the function with no arguments.
To create a variadic function (a function which you can call with any number of arguments or none), specify `...` as the only parameter.

#### Function Body

The function body defines the function.
You can use any valid {sqlpp} expression.
If you specified named parameters for the function, you can use these in the expression to represent arguments passed to the function at execution time.
If you specified that the function is variadic, any arguments passed to the function at execution time are held in an array named `args`.

<dl><dt><strong>📌 NOTE</strong></dt><dd>

* If the expression contains a parameter that has the same name as a field in the document, it will always refer to the parameter.
To distinguish between the field and the parameter, prefix the field with the keyspace name, for example `landmark.activity`.
To avoid this ambiguity, you should use unique parameter names that do not clash with document field names, such as `vActivity`.
* Functions may return only one value, of any valid {sqlpp} type.
For inline functions, the result and type of the function are the result and type of the expression.
If you need to return multiple values, construct an array.
</dd></dl>

### External Functions

The CREATE FUNCTION statement provides two possible syntaxes for defining an external function: one that references a function code in a JavaScript library, and one that creates a {sqlpp} managed JavaScript function.

```ebnf
create-function-external ::= 'CREATE' ( 'OR' 'REPLACE' )? 'FUNCTION' function '(' params? ')'
                             ( 'IF' 'NOT' 'EXISTS' )?
                             'LANGUAGE' 'JAVASCRIPT' 'AS' ( obj 'AT' library | javascript )
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/create-function-external.png)

* **function**\
[external-name](#external-name) icon:caret-down[]
* **params**\
[external-parameter](#external-parameter) icon:caret-down[]
* **obj**\
[External Object](#external-object) icon:caret-down[]
* **library**\
[External Library](#external-library) icon:caret-down[]
* **javascript**\
[Function Body](#function-body) icon:caret-down[]

#### OR REPLACE / IF NOT EXISTS

The optional `OR REPLACE` clause enables you to redefine a user-defined function if it already exists, whereas the optional `IF NOT EXISTS` clause enables the statement to complete successfully without replacing the function.

When a function with the same name already exists within the same context:
footnote:context[In other words, you’re creating a global function, and a function with the same name already exists within the same namespace; or, you’re creating a scoped function, and a function with the same name already exists within the same scope.]

* If the `OR REPLACE` clause is present, the existing function is replaced.
* If the `IF NOT EXISTS` clause is present, the statement does nothing and completes without error.
* If neither of these two clauses is present, an error is generated.

**📌 NOTE**\
These clauses are exclusive.
If the statement contains both the `OR REPLACE` clause and the `IF NOT EXISTS` clause, an error is generated.

#### Function Name

```ebnf
function ::= ( namespace ':' ( bucket '.' scope '.' )? )? identifier
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/function.png)

The function name specifies the name of the function to create.
It’s recommended to use an unqualified identifier for the function name, such as `func1` or `{backtick}func-1{backtick}`.
In this case, the function is created as a global function or a scoped function, depending on the current query context.

To create a global function in a particular namespace, the function name must be a qualified identifier with a namespace, such as `default:func1`.
Similarly, to create a scoped function in a particular scope, the function name must be a qualified identifier with the full path to a scope, such as `default:{backtick}travel-sample{backtick}.inventory.func1`.

If the function name is an unqualified identifier, it may not be the same as a reserved keyword.
A function name with a specified namespace or scope may have the same name as a reserved keyword.

The function name must be unique within its scope or namespace.
You cannot have two functions with the same name inside the same scope or namespace.
You can have two functions with the same name across different scopes or namespaces.

#### Function Parameters

```ebnf
params ::= identifier ( "," identifier )* | "..."
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/params.png)

[Optional] The function parameter list specifies parameters for the function.
If you specify named parameters for the function, then you must call the function with exactly the same number of arguments at execution time.
If you specify no parameters, then you must call the function with no arguments.
To create a variadic function (a function which you can call with any number of arguments or none), specify `...` as the only parameter.

#### External Object

[Optional] Use this parameter when the function code is stored in a JavaScript library.

The name of the JavaScript function that you want to use for the user-defined function.
This parameter is a string and must be wrapped in quotes.

#### External Library

[Optional] Use this parameter when the function code is stored in a JavaScript library.

The name of the JavaScript library that contains the JavaScript function you want to use.
This parameter is a string and must be wrapped in quotes.

The name of a scoped JavaScript library must include the bucket name, the scope name, and the library name, separated by slashes.
For example, to refer to a scoped library called `my-library` located in the `inventory` scope within the `travel-sample` bucket, you would specify the library name as `travel-sample/inventory/my-library`.

#### Function Body

[Optional] Use this parameter to create a {sqlpp} managed JavaScript function.

The external JavaScript function code.
This must contain a function with the same name and the same number of parameters as the {sqlpp} user-defined function.
This parameter is a string and must be wrapped in quotes.

If you specified named parameters for the function, you can use these in the expression to represent arguments passed to the function at execution time.
If you specified that the function is variadic, any arguments passed to the function at execution time are held in an array named `args`.

The JavaScript code can contain multiple function definitions, but these functions can only be referenced within the JavaScript code for this {sqlpp} user-defined function, and cannot be shared.

## Examples

For simplicity, none of these examples implement any data validation or error checking.
If necessary, you can use [conditional operators](n1ql:n1ql-language-reference/conditionalops.adoc) to check the parameters of a user-defined function, and the [ABORT()](n1ql:n1ql-language-reference/metafun.adoc#abort) function to generate an error if something is wrong.

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-inline-language"></a>**Inline function with the LANGUAGE syntax**

This statement creates a function called `celsius`, which converts Fahrenheit to Celsius.
The function takes a single argument.

```sqlpp
CREATE FUNCTION celsius(fahrenheit) LANGUAGE INLINE AS (fahrenheit - 32) * 5/9;
```

**Test**

```sqlpp
EXECUTE FUNCTION celsius(100);
```

**Result**

```json
[
  37.77777777777778
]
```

<a name="ex-inline-braces"></a>**Inline function with the braces syntax**

This statement creates a function called `fahrenheit`, which converts Celsius to Fahrenheit.
The function takes a single argument.

```sqlpp
CREATE FUNCTION fahrenheit(celsius) { (celsius * 9/5) + 32 };
```

**Test**

```sqlpp
EXECUTE FUNCTION fahrenheit(100);
```

**Result**

```json
[
  212
]
```

<a name="ex-params-incorrect"></a>**Inline function with multiple parameters**

The following statement creates a function called `lstr`, which returns the specified number of characters from the left of a string.
The expression expects two named arguments: `vString`, which is the string to work with, and `vLen`, which is the number of characters to return.

```sqlpp
CREATE FUNCTION lstr(vString, vLen) LANGUAGE INLINE AS SUBSTR(vString, 0, vLen);
```

**Test**

```sqlpp
EXECUTE FUNCTION lstr("Couchbase", 5, "ignore this");
```

**Result**

```json
[
  {
    "code": 10104,
    "msg": "Incorrect number of arguments supplied to function lstr - cause: lstr"
  }
]
```

As the arguments were specified by the function definition, you must use the same number of arguments when you call the function.
If you supply the wrong number of arguments, an error is generated.

<a name="ex-params-correct"></a>**Inline function with multiple parameters**

The following statement creates a function called `rstr`, which returns the specified number of characters from the right of a string.
The expression expects two named arguments: `vString`, which is the string to work with, and `vLen`, which is the number of characters to return.

```sqlpp
CREATE FUNCTION rstr(vString, vLen) { SUBSTR(vString, LENGTH(vString) - vLen, vLen) };
```

**Test**

```sqlpp
EXECUTE FUNCTION rstr("Couchbase", 4);
```

**Result**

```json
[
  "base"
]
```

<a name="ex-inline-subquery"></a>**Inline function with subquery**

The following statement creates a function called `locations`, which selects name and address information from all documents with the specified activity in the `landmark` keyspace.

```sqlpp
CREATE FUNCTION locations(vActivity) { (
  SELECT id, name, address, city
  FROM landmark
  WHERE activity = vActivity) };
```

**Test**

```sqlpp
EXECUTE FUNCTION locations("see");
```

**Result**

```json
[
  [
    {
      "address": "Prince Arthur Road, ME4 4UG",
      "city": "Gillingham",
      "id": 10019,
      "name": "Royal Engineers Museum"
    },
    {
      "address": "84 rue Claude Monet",
      "city": "Giverny",
      "id": 10061,
      "name": "Monet's House"
    },
// ...
```

<a name="ex-inline-variadic"></a>**Variadic inline function**

The following statement creates a function called `total_length`, which takes a variable number of strings and returns the total length of all the strings.
As the function is variadic, you can use any number of arguments when you call the function.

```sqlpp
CREATE FUNCTION total_length(...)
{ ARRAY_SUM((SELECT VALUE LEN(a) FROM args AS a)) };
```

**Test**

```sqlpp
EXECUTE FUNCTION total_length("Hello", "Goodbye");
```

**Result**

```json
[
  12
]
```

<a name="ex-replace"></a>**Replace a function**

This statement creates a function which returns the mathematical constant φ.
The function takes no arguments.

```sqlpp
CREATE FUNCTION phi() { 2 * SIN(RADIANS(54)) };
```

**Test**

```sqlpp
EXECUTE FUNCTION phi();
```

**Result**

```json
[
  1.618033988749895
]
```

The following statement redefines the function so that it calculates φ using a different method.

**Replace**

```sqlpp
CREATE OR REPLACE FUNCTION phi() { (1 + SQRT(5)) / 2 };
```

**Test**

```sqlpp
EXECUTE FUNCTION phi();
```

**Result**

```json
[
  1.618033988749895
]
```

<a name="ex-managed"></a>**{sqlpp} managed JavaScript function**

The following statement creates external JavaScript function code and the corresponding {sqlpp} user-defined function in one operation.

```sqlpp
CREATE FUNCTION add100(num) LANGUAGE JAVASCRIPT AS
"function add100(param1) {return param1+100;}";
```

**Test**

```sqlpp
EXECUTE FUNCTION add100(100);
```

**Result**

```json
[
  200
]
```

<a name="ex-external"></a>**External functions**

The following command registers two JavaScript functions called `encodeGeoHash` and `calculateAdjacent` in a library called `geohash-js`.
footnote:[Credit: https://github.com/davetroy/geohash-js]

* The function `encodeGeoHash` takes two arguments, a latitude and a longitude, and returns the 12-character [geohash](https://en.wikipedia.org/wiki/Geohash) for the specified location.
* The function `calculateAdjacent` takes two arguments, a geohash and a direction -- `"top"`, `"bottom"`, `"left"`, or `"right"` -- and returns the geohash of the location next to the original geohash in the specified direction.

```sh
curl -v -X POST \
http://localhost:8093/evaluator/v1/libraries/geohash-js \
-u Administrator:password \
-H 'content-type: application/json' \
-d 'function encodeGeoHash(latitude, longitude) {

  var BITS = [16, 8, 4, 2, 1];
  var BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

  var is_even = 1;
  var i = 0, mid;
  var lat = []; var lon = [];
  var bit = 0;
  var ch = 0;
  var precision = 12;
  var geohash = "";

  lat[0] = -90.0; lat[1] = 90.0;
  lon[0] = -180.0; lon[1] = 180.0;

  while (geohash.length < precision) {
    if (is_even) {
      mid = (lon[0] + lon[1]) / 2;
      if (longitude > mid) {
        ch |= BITS[bit];
        lon[0] = mid;
      } else
        lon[1] = mid;
    } else {
      mid = (lat[0] + lat[1]) / 2;
      if (latitude > mid) {
        ch |= BITS[bit];
        lat[0] = mid;
      } else
        lat[1] = mid;
    }

    is_even = !is_even;
    if (bit < 4)
      bit++;
    else {
      geohash += BASE32[ch];
      bit = 0;
      ch = 0;
    }
  }

  return geohash;
}

function calculateAdjacent(srcHash, dir) {

  var BITS = [16, 8, 4, 2, 1];
  var BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

  var NEIGHBORS = { right  : { even : "bc01fg45238967deuvhjyznpkmstqrwx" },
                    left   : { even : "238967debc01fg45kmstqrwxuvhjyznp" },
                    top    : { even : "p0r21436x8zb9dcf5h7kjnmqesgutwvy" },
                    bottom : { even : "14365h7k9dcfesgujnmqp0r2twvyx8zb" } };

  var BORDERS   = { right  : { even : "bcfguvyz" },
                    left   : { even : "0145hjnp" },
                    top    : { even : "prxz" },
                    bottom : { even : "028b" } };

  NEIGHBORS.bottom.odd = NEIGHBORS.left.even;
  NEIGHBORS.top.odd = NEIGHBORS.right.even;
  NEIGHBORS.left.odd = NEIGHBORS.bottom.even;
  NEIGHBORS.right.odd = NEIGHBORS.top.even;

  BORDERS.bottom.odd = BORDERS.left.even;
  BORDERS.top.odd = BORDERS.right.even;
  BORDERS.left.odd = BORDERS.bottom.even;
  BORDERS.right.odd = BORDERS.top.even;

  srcHash = srcHash.toLowerCase();
  var lastChr = srcHash.charAt(srcHash.length - 1);
  var type = (srcHash.length % 2) ? "odd" : "even";
  var base = srcHash.substring(0, srcHash.length - 1);
  if (BORDERS[dir][type].indexOf(lastChr) != -1)
    base = calculateAdjacent(base, dir);
  return base + BASE32[NEIGHBORS[dir][type].indexOf(lastChr)];
}'
```

The following statements create two functions:

1. A function called `geohash`, which calls the JavaScript `encodeGeoHash` function from the `geohash-js` library;
2. A function called `adjacent`, which calls the JavaScript `calculateAdjacent` function from the `geohash-js` library.

```sqlpp
CREATE FUNCTION geohash(lat, lon)
  LANGUAGE JAVASCRIPT AS "encodeGeoHash" AT "geohash-js";

CREATE FUNCTION adjacent(src, dir)
  LANGUAGE JAVASCRIPT AS "calculateAdjacent" AT "geohash-js";
```

**Test `geohash`**

```sqlpp
EXECUTE FUNCTION geohash(53.353744, -2.27495);
```

**Result**

```json
[
  "gcqrs0z2jfdr"
]
```

To view the geohash on a map, go to [Geohashes](https://www.movable-type.co.uk/scripts/geohash.html) and enter the string in the **Geohash** box.
At the specified latitude, the geohash represents an area of approximately 11 𐄂 19 millimeters.

**Test `adjacent`**

```sqlpp
EXECUTE FUNCTION adjacent(geohash(53.353744, -2.27495), "top");
```

**Result**

```json
[
  "gcqrs0z2jff2"
]
```

To view the geohash on a map, go to [Geohashes](https://www.movable-type.co.uk/scripts/geohash.html) and enter the string in the **Geohash** box.
At this level of precision, the geohash should appear to be in almost exactly the same location as the previous one.

## Related Links

* For an introduction to user-defined functions, see [guides:javascript-udfs.adoc](guides:javascript-udfs.adoc).
* For more information about JavaScript functions, see [javascript-udfs:javascript-functions-with-couchbase.adoc](javascript-udfs:javascript-functions-with-couchbase.adoc).
* To manage JavaScript libraries, see [n1ql-rest-functions:index.adoc](n1ql-rest-functions:index.adoc).
* To execute a user-defined function, see [n1ql-language-reference/execfunction.adoc](n1ql-language-reference/execfunction.adoc).
* To see the execution plan for a user-defined function, see [n1ql-language-reference/explainfunction.adoc](n1ql-language-reference/explainfunction.adoc).
* To include a user-defined function in an expression, see [n1ql-language-reference/userfun.adoc](n1ql-language-reference/userfun.adoc).
* To monitor user-defined functions, see [Monitor Functions](n1ql:n1ql-intro/sysinfo.adoc#sys-functions).
* To drop a user-defined function, see [n1ql-language-reference/dropfunction.adoc](n1ql-language-reference/dropfunction.adoc).
