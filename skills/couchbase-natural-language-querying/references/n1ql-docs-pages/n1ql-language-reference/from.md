# FROM Clause

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

The `FROM` clause specifies the documents to be used as the input for a query.

## Purpose

The `FROM` clause is used within a [SELECT](n1ql-language-reference/selectclause.adoc) query or [subquery](n1ql-language-reference/subqueries.adoc).
It specifies the documents to be used as the input for a query.

## Prerequisites

For you to select data from keyspace or expression, you must have the `query_select` privilege on that keyspace.
For more details about user roles, see
[Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
from-clause ::= 'FROM' from-terms
```

![Syntax diagram](../../assets/images/n1ql-language-reference/from-clause.png)

### FROM Terms

```ebnf
from-terms ::= ( from-keyspace | from-subquery | from-generic )
               ( join-clause | nest-clause | unnest-clause )* comma-separated-join*
```

![Syntax diagram](../../assets/images/n1ql-language-reference/from-terms.png)

The first FROM term may be any of the following:

* A [keyspace reference](#from-keyspace)
* A [subquery](#from-subquery) (such as derived tables)
* A [generic expression](#from-generic-expression) (nested paths, `CURL()`, or other expressions)

This may be followed by further FROM terms, each of which may be one of the following:

* A [JOIN](n1ql-language-reference/join.adoc) clause and conditions
* A [NEST](n1ql-language-reference/nest.adoc) clause and conditions
* An [UNNEST](n1ql-language-reference/unnest.adoc) clause and conditions

You may additionally include one or more [comma-separated joins](n1ql-language-reference/comma.adoc).

<dl><dt><strong>❗ IMPORTANT</strong></dt><dd>

`JOIN` clauses, `NEST` clauses, `UNNEST` clauses, and comma-separated joins each have a _left-hand side_ and a _right-hand side_.
The left-hand side is defined by the preceding FROM term; the right-hand side is defined by the FROM term itself.

When you chain multiple FROM terms together, the right-hand side of one FROM term acts as the left-hand side of the following FROM term.
</dd></dl>

### Limitations

* When the FROM term is an expression, `USE KEYS` or `USE INDEX` clauses are not allowed.
* When using a lookup `JOIN` clause, an index `JOIN` clause, a `NEST` clause, or an `UNNEST` clause, the left-hand side of the join may be a keyspace identifier, an expression, or a subquery; but the right-hand side may only be a keyspace identifier.
* When using an ANSI `JOIN` clause, the right-hand side of the join may also be a keyspace identifier, an expression, or a subquery, similar to the left-hand side.
* You can chain comma-separated joins with ANSI `JOIN` clauses, ANSI `NEST` clauses, and `UNNEST` clauses.
However, you cannot chain comma-separated joins with lookup `JOIN` and `NEST` clauses, or index `JOIN` and `NEST` clauses.
* The right-hand side of a comma-separated join can only be a keyspace identifier, a subquery, or a generic expression.
This means that comma-separated joins must come _after_ any `JOIN`, `NEST`, or `UNNEST` clauses.

## FROM Keyspace

The FROM keyspace specifies a keyspace to query from: either a specific keyspace or a constant expression.

### Syntax

```ebnf
from-keyspace ::= keyspace-ref ( 'AS'? alias )? use-clause?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/from-keyspace.png)

* **keyspace-ref**\
[Keyspace Reference](#keyspace-reference) icon:caret-down[]
* **alias**\
[AS Alias](#as-alias) icon:caret-down[]
* **use-clause**\
[USE Clause](#use-clause) icon:caret-down[]

#### Keyspace Reference

```ebnf
keyspace-ref ::= keyspace-path | keyspace-partial
```

![Syntax diagram](../../assets/images/n1ql-language-reference/keyspace-ref.png)

* **keyspace-path**\
[Keyspace Path](#keyspace-path) icon:caret-down[]
* **keyspace-partial**\
[Keyspace Partial](#keyspace-partial) icon:caret-down[]

Keyspace reference of the data source.
The identifiers that make up the keyspace reference are not available as [variables in scope of a subquery](n1ql-language-reference/subqueries.adoc#section_onz_3tj_mz).

**📌 NOTE**\
If there is a hyphen (-) inside any part of the keyspace reference, you must wrap that part of the keyspace reference in backticks ({backtick}&#160;{backtick}).
Refer to the examples below.

#### Keyspace Path

```ebnf
keyspace-path ::= ( namespace ':' )? bucket ( '.' scope '.' collection )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/keyspace-path.png)

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

![Syntax diagram](../../assets/images/n1ql-language-reference/keyspace-partial.png)

Alternatively, if the keyspace is a named collection, the keyspace reference may be just the collection name with no path.
In this case, you must set the [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context) to indicate the required namespace, bucket, and scope.

* **collection**\
(Required) An [identifier](n1ql-language-reference/identifiers.adoc) that refers to the [collection name](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the keyspace.

For example, `airline` indicates the `airline` collection, assuming the query context is set.

#### AS Alias

Assigns another name to the FROM keyspace.
For details, see [AS Clause](#as-clause).

Assigning an alias is optional for the FROM keyspace.
If you assign an alias to the FROM keyspace, the `AS` keyword may be omitted.

#### USE Clause

Enables you to specify that the query should use particular keys, or a particular index.
For details, see [USE clause](n1ql-language-reference/hints.adoc).

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

The simplest type of FROM keyspace clause specifies a single keyspace.

<a name="ex-single-keyspace"></a>**Use a single keyspace**

Select four unique landmarks from the `landmark` keyspace.

```sqlpp
SELECT DISTINCT name
FROM landmark
LIMIT 4;
```

**Results**

```JSON
[
  {
    "name": "Royal Engineers Museum"
  },
  {
    "name": "Hollywood Bowl"
  },
  {
    "name": "Thai Won Mien"
  },
  {
    "name": "Spice Court"
  }
]
```

## FROM Subquery

Specifies a {sqlpp} `SELECT` expression of input objects.

### Syntax

```ebnf
from-subquery ::= subquery-expr 'AS'? alias
```

![Syntax diagram](../../assets/images/n1ql-language-reference/from-subquery.png)

* **subquery-expr**\
[Subquery Expression](#subquery-expression) icon:caret-down[]
* **alias**\
[AS Alias](#as-alias) icon:caret-down[]

#### Subquery Expression

```ebnf
subquery-expr ::= '(' select ')'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/subquery-expr.png)

Use parentheses to specify a subquery.

For more details and examples, see [SELECT Clause](n1ql-language-reference/selectclause.adoc) and [Subqueries](n1ql-language-reference/subqueries.adoc).

#### AS Alias

Assigns another name to the subquery.
For details, see [AS Clause](#as-clause).

Assigning an alias is required for subqueries in the FROM term.
However, when you assign an alias to the subquery, the `AS` keyword may be omitted.

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-subquery-1"></a>**A `SELECT` clause inside a `FROM` clause.**

List all `Gillingham` landmark names from a subset of all landmark eating places.

```sqlpp
SELECT name, city
FROM (SELECT id, name, address, city
      FROM landmark
      WHERE activity = "eat") AS l
WHERE city = "Gillingham";
```

**Results**

```JSON
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

<a name="ex-subquery-2"></a>**Subquery Example**

For each country, find the number of airports at different altitudes and their corresponding cities.

In this case, the inner query finds the first level of grouping of different altitudes by country and corresponding number of cities.
Then the outer query builds on the inner query results to count the number of different altitude groups for each country and the total number of cities.

```sqlpp
SELECT t1.country, num_alts, total_cities
FROM (SELECT country, geo.alt AS alt,
             count(city) AS num_cities
      FROM airport
      GROUP BY country, geo.alt) t1
GROUP BY t1.country
LETTING num_alts = count(t1.alt), total_cities = sum(t1.num_cities);
```

**Results**

```JSON
[
  {
    "country": "United States",
    "num_alts": 946,
    "total_cities": 1560
  },
  {
    "country": "United Kingdom",
    "num_alts": 128,
    "total_cities": 187
  },
  {
    "country": "France",
    "num_alts": 196,
    "total_cities": 221
  }
]
```

This is equivalent to blending the results of the following two queries by country, but the subquery in the `from-term` above simplified it.

```sqlpp
SELECT country,count(city) AS num_cities
FROM airport
GROUP BY country;
```

```sqlpp
SELECT country, count(distinct geo.alt) AS num_alts
FROM airport
GROUP BY country;
```

## FROM Generic Expression

Generic [expressions](n1ql-language-reference/index.adoc) in the FROM term may include {sqlpp} functions, operators, path expressions, language constructs on constant expressions, variables, and subqueries.
This adds huge flexibility by enabling just about any FROM clause imaginable.

### Syntax

```ebnf
from-generic ::= expr ( 'AS' alias )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/from-generic.png)

* **expr**\
A {sqlpp} expression generating JSON documents or objects.
* **alias**\
[AS Alias](#as-alias) icon:caret-down[]

#### AS Alias

Assigns another name to the generic expression.
For details, see [AS Clause](#as-clause).

Assigning an alias is optional for generic expressions in the FROM term.
However, when you assign an alias to the expression, the `AS` keyword is required.

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-constant-expr"></a>**Independent Constant Expression**

The expression may include JSON scalar values, static JSON literals, objects, or {sqlpp} functions.

```sqlpp
SELECT * FROM [1, 2, "name", { "type" : "airport", "id" : "SFO"}] AS ks1;
```

```sqlpp
SELECT CURL("https://maps.googleapis.com/maps/api/geocode/json",
           {"data":"address=Half+Moon+Bay" , "request":"GET"} );
```

Note that functions such as [CURL()](n1ql-language-reference/curl.adoc) can independently produce input data objects for the query.
Similarly, other {sqlpp} functions can also be used in the expressions.

<a name="ex-var-expr"></a>**Variable {sqlpp} Expression**

The expression may refer to any [variables in scope](n1ql-language-reference/subqueries.adoc#section_onz_3tj_mz) for the query.

```sqlpp
SELECT count(*)
FROM airport t
LET x = t.geo
WHERE (SELECT RAW y.alt FROM x y)[0] > 6000;
```

The `FROM x` clause is an expression that refers to the outer query.
This is applicable to only subqueries because the outermost level query cannot use any variables in its own `FROM` clause.
This makes the subquery correlated with outer queries, as explained in the [Subqueries](n1ql-language-reference/subqueries.adoc) section.

## AS Clause

To use a shorter or clearer name anywhere in the query, like SQL, {sqlpp} allows you to assign an alias to any FROM term in the `FROM` clause.

### Syntax

The `AS` keyword is required when assigning an alias to a generic expression.

The `AS` keyword is optional when assigning an alias to the FROM keyspace, a subquery, the JOIN clause, the NEST clause, or the UNNEST clause.

### Arguments

* **alias**\
String to assign an alias.

<dl><dt><strong>📌 NOTE</strong></dt><dd>

Since the original name may lead to referencing wrong data and wrong results, you must use the alias name throughout the query instead of the original keyspace name.

In the FROM clause, the renaming appears only in the projection and not the fields themselves.

When no alias is used, the keyspace or last field name of an expression is given as the implicit alias.

When an alias conflicts with a keyspace or field name in the same scope, the identifier always refers to the alias.
This allows for consistent behavior in scenarios where an identifier only conflicts in some documents.
For more information on aliases, see [Identifiers](n1ql-language-reference/identifiers.adoc).
</dd></dl>

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

The following `FROM` clauses are equivalent, with and without the `AS` keyword.

|     |     |
| --- | --- |
```sqlpp
FROM airport AS t
```
|  |  |
```sqlpp
FROM airport t
```
```sqlpp
FROM hotel AS h
INNER JOIN landmark AS l
ON (h.city = l.city)
```
|  |  |
```sqlpp
FROM hotel h
INNER JOIN landmark l
ON (h.city = l.city)
```

## Related Links

* [USE Clause](n1ql-language-reference/hints.adoc)
* [JOIN Clause](n1ql-language-reference/join.adoc)
* [NEST Clause](n1ql-language-reference/nest.adoc)
* [UNNEST Clause](n1ql-language-reference/unnest.adoc)
* [Comma-Separated Join](n1ql-language-reference/comma.adoc)
