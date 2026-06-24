# User-Defined Functions

You can call a user-defined function in any expression where you can call a built-in function.

## Description

When you have created a user-defined function, you can call it in any expression, just like a built-in function.
User-defined functions have the same syntax as built-in functions, with parentheses `()` to contain any arguments.

The name of the function is usually an unqualified identifier, such as `func1` or `{backtick}func-1{backtick}`.
In this case, the path to the function is determined by the current [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

To call a global function in a particular namespace, the function name must be a qualified identifier with a namespace, such as `default:func1`.
Similarly, to call a scoped function in a particular scope, the function name must be a qualified identifier with the full path to a scope, such as `default:{backtick}travel-sample{backtick}.inventory.func1`.
For more information, see [Global Functions and Scoped Functions](n1ql-language-reference/createfunction.adoc#context).

**📌 NOTE**\
The name of a user-defined function is case-sensitive, unlike that of a built-in function.
You must call the user-defined function using the same case that was used when it was created.

It’s not possible to call a user-defined function in an expression if the function has side effects, such as performing mutations.
When you do this, an error is generated.

## Prerequisites

| To execute ... | You must have ... |
| --- | --- |
| Global inline functions | **Execute Global Functions** role. |
| Scoped inline functions | **Execute Scope Functions** role, with permissions on the specified bucket and scope. |
| Global external functions | **Execute Global External Functions** role. |
| Scoped external functions | **Execute Scope External Functions** role, with permissions on the specified bucket and scope. |

For more information about user roles, see
[Authorization](learn:security/authorization-overview.adoc).

## Arguments

A user-defined function has zero, one, or more arguments, separated by commas, just like a built-in function.
Each argument is a {sqlpp} expression required by the function.

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

See [CREATE FUNCTION](n1ql-language-reference/createfunction.adoc) for details on creating user-defined functions.

For simplicity, none of these examples implement any data validation or error checking.
If necessary, you can use [conditional operators](n1ql:n1ql-language-reference/conditionalops.adoc) to check the parameters of a user-defined function, and the [ABORT()](n1ql:n1ql-language-reference/metafun.adoc#abort) function to generate an error if something is wrong.

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Inline function with expression**

The following statement creates a function called `to_meters`, which converts feet to meters.

```sqlpp
CREATE FUNCTION to_meters(feet) { feet * 0.3048 };
```

The following query uses the `to_meters` function to express the elevation of the selected airports in meters above mean sea level (mamsl).
The built-in ROUND function is used to round the output to zero decimal places.

**Query**

```sqlpp
SELECT airportname, ROUND(to_meters(geo.alt)) AS mamsl
FROM airport
LIMIT 5;
```

**Result**

```json
[
  {
    "airportname": "Calais Dunkerque",
    "mamsl": 4
  },
  {
    "airportname": "Peronne St Quentin",
    "mamsl": 90
  },
  {
    "airportname": "Les Loges",
    "mamsl": 130
  },
  {
    "airportname": "Couterne",
    "mamsl": 219
  },
  {
    "airportname": "Bray",
    "mamsl": 111
  }
]
```

**Inline function with subquery**

The following statement creates a function called `locations`, which selects name and address information from all documents with the specified activity in the `landmark` keyspace.

```sqlpp
CREATE FUNCTION locations(vActivity) { (
  SELECT id, name, address, city
  FROM landmark
  WHERE activity = vActivity) };
```

The following query uses the `locations` function as the FROM term in a SELECT query.
Compare this query with the example [A `SELECT` clause inside a `FROM` clause](n1ql-language-reference/from.adoc#ex-subquery-1) in FROM Subquery.

**Query**

```sqlpp
SELECT l.name, l.city
FROM locations("eat") AS l
WHERE l.city = "Gillingham";
```

**Result**

```json
[
  {
    "city": "Gillingham",
    "name": "Hollywood Bowl"
  },
  {
    "city": "Gillingham",
    "name": "Thai Won Mien"
  },
  {
    "city": "Gillingham",
    "name": "Spice Court"
  },
  {
    "city": "Gillingham",
    "name": "Beijing Inn"
  },
  {
    "city": "Gillingham",
    "name": "Ossie's Fish and Chips"
  }
]
```

**External functions**

For this example, it’s assumed that you have created two external functions:

1. A function called `geohash`, which depends on the JavaScript `encodeGeoHash` function in the `geohash-js` library;
2. A function called `adjacent`, which depends on the JavaScript `calculateAdjacent` function in the `geohash-js` library.

For more information, see the example [External functions](n1ql-language-reference/createfunction.adoc#ex-external) in CREATE FUNCTION.

The following query uses the `geohash` and `adjacent` functions to find the 9-figure geohash of the selected hotel, and the geohashes immediately to the north, south, west, and east.

**Query**

```sqlpp
SELECT area,
       adjacent(area, "top") AS north,
       adjacent(area, "bottom") AS south,
       adjacent(area, "left") AS west,
       adjacent(area, "right") AS east
FROM hotel
LET area = SUBSTR(geohash(geo.lat, geo.lon), 0, 9)
WHERE name = "Sachas Hotel";
```

**Result**

```json
[
  {
    "area": "gcw2m05h1",
    "east": "gcw2m05h4",
    "north": "gcw2m05h3",
    "south": "gcw2m055c",
    "west": "gcw2m05h0"
  }
]
```

To view any of these geohashes on a map, go to [Geohashes](https://www.movable-type.co.uk/scripts/geohash.html) and enter the string in the **Geohash** box.
At the latitude of the selected hotel, each geohash represents an area of approximately 3 𐄂 5 meters.

## Related Links

* For an introduction to user-defined functions, see [guides:javascript-udfs.adoc](guides:javascript-udfs.adoc).
* For more information about JavaScript functions, see [javascript-udfs:javascript-functions-with-couchbase.adoc](javascript-udfs:javascript-functions-with-couchbase.adoc).
* To manage JavaScript libraries, see [n1ql-rest-functions:index.adoc](n1ql-rest-functions:index.adoc).
* To create user-defined functions, see [n1ql-language-reference/createfunction.adoc](n1ql-language-reference/createfunction.adoc).
* To execute a user-defined function, see [n1ql-language-reference/execfunction.adoc](n1ql-language-reference/execfunction.adoc).
* To see the execution plan for a user-defined function, see [n1ql-language-reference/explainfunction.adoc](n1ql-language-reference/explainfunction.adoc).
* To monitor user-defined functions, see [Monitor Functions](n1ql:n1ql-intro/sysinfo.adoc#sys-functions).
* To drop a user-defined function, see [n1ql-language-reference/dropfunction.adoc](n1ql-language-reference/dropfunction.adoc).
