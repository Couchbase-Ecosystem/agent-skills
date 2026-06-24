# NEST Clause

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

The `NEST` clause creates an input object by producing a single result of nesting keyspaces.

## Purpose

The `NEST` clause is used within the [FROM](n1ql-language-reference/from.adoc) clause.
It enables you to create an input object by producing a single result of nesting keyspaces via [ANSI NEST](#ansi-nest-clause), [Lookup NEST](#lookup-nest-clause), or [Index NEST](#index-nest-clause).

## Prerequisites

For you to select data from keyspace or expression, you must have the `query_select` privilege on that keyspace.
For more details about user roles, see
[Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
nest-clause ::= ansi-nest-clause | lookup-nest-clause | index-nest-clause
```

![Syntax diagram](../../assets/images/n1ql-language-reference/nest-clause.png)

* **ansi-nest-clause**\
[ANSI NEST Clause](#ansi-nest-clause) icon:caret-down[]
* **lookup-nest-clause**\
[Lookup NEST Clause](#lookup-nest-clause) icon:caret-down[]
* **index-nest-clause**\
[Index NEST Clause](#index-nest-clause) icon:caret-down[]

### Left-Hand Side

The pass:q[`NEST` clause] cannot be the first term within the `FROM` clause; it must be preceded by another FROM term.
The term immediately preceding the pass:q[`NEST` clause] represents the _left-hand side_ of the pass:q[`NEST` clause].

You can chain the pass:q[`NEST` clause] with any of the other permitted FROM terms, including another pass:q[`NEST` clause].
For more information, see the page on the [FROM](n1ql-language-reference/from.adoc) clause.

There are restrictions on what types of FROM terms may be chained and in what order -- see the descriptions on this page for more details.

The types of FROM term that may be used as the left-hand side of the pass:q[`NEST` clause] are summarized in the following table.

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

| Type | Example |
| --- | --- |
| [keyspace identifier](n1ql-language-reference/from.adoc#sec_from-keyspace) |  |
```N1QL
hotel
```
| [generic expression](n1ql-language-reference/from.adoc#generic-expr) |  |
```N1QL
20+10 AS Total
```
| [subquery](n1ql-language-reference/from.adoc#select-expr) |  |
```N1QL
SELECT ARRAY_AGG(t1.city) AS cities,
  SUM(t1.city_cnt) AS apnum
FROM (
  SELECT city, city_cnt, country,
    ARRAY_AGG(airportname) AS apnames
  FROM airport
  GROUP BY city, country
  LETTING city_cnt = COUNT(city)
) AS t1
WHERE t1.city_cnt > 5;
```
| previous [join](n1ql-language-reference/join.adoc), [nest](n1ql-language-reference/nest.adoc), or [unnest](n1ql-language-reference/unnest.adoc) |  |
```N1QL
SELECT *
FROM route AS rte
JOIN airport AS apt
  ON rte.destinationairport = apt.faa
NEST landmark AS lmk
  ON apt.city = lmk.city
LIMIT 5;
```

## ANSI NEST Clause

**📌 NOTE**\
[ANSI JOIN](n1ql-language-reference/join.adoc#section_ek1_jnx_1db) and [ANSI NEST](n1ql-language-reference/nest.adoc#section_tc1_nnx_1db) clauses have much more flexible functionality than their earlier INDEX and LOOKUP equivalents.
Since these are standard compliant and more flexible, we recommend you to use ANSI JOIN and ANSI NEST exclusively, where possible.

ANSI NEST supports more nest types than Lookup NEST or Index NEXT.
ANSI NEST can nest arbitrary fields of the documents, and can be chained together.

The key difference between ANSI NEST and other supported NEST types is the replacement of the `ON KEYS` or `ON KEY … FOR` clauses with a simple `ON` clause.
The `ON KEYS` or `ON KEY … FOR` clauses dictate that those nests can only be done on a document key (primary key for a document).
The `ON` clause can contain any expression, and thus it opens up many more nest possibilities.

### Syntax

```ebnf
ansi-nest-clause ::= ansi-nest-type? 'NEST' 'LATERAL'? ansi-nest-rhs ansi-nest-predicate
```

![Syntax diagram](../../assets/images/n1ql-language-reference/ansi-nest-clause.png)

* **ansi-nest-type**\
[Nest Type](#nest-type) icon:caret-down[]
* **ansi-nest-lateral**\
[LATERAL Nest](#lateral-nest) icon:caret-down[]
* **ansi-nest-rhs**\
[Nest Right-Hand Side](#nest-right-hand-side) icon:caret-down[]
* **ansi-nest-predicate**\
[Nest Predicate](#nest-predicate) icon:caret-down[]

#### Nest Type

```ebnf
ansi-nest-type ::= 'INNER' | ( 'LEFT' 'OUTER'? )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/ansi-nest-type.png)

This clause represents the type of ANSI nest.

* **`INNER`**\
For each nested object produced, both the left-hand and right-hand source objects must be non-MISSING and non-NULL.
* **`LEFT [OUTER]`**\
{startsb}Query Service interprets `LEFT` as `LEFT OUTER`{endsb}

  For each nested object produced, only the left-hand source objects must be non-MISSING and non-NULL.

This clause is optional.
If omitted, the default is `INNER`.

#### LATERAL Nest

When an expression on the right-hand side of an ANSI nest references a keyspace that is already specified in the same FROM clause, the expression is said to be correlated.
In relational databases, a join which contains correlated expressions is referred to as a lateral join.
In {sqlpp}, lateral correlations are detected automatically, and there is no need to specify that a nest or join is lateral.

In Couchbase Server 7.6 and later, you can use the LATERAL keyword as a visual reminder that a nest contains correlated expressions.
The LATERAL keyword is not required -- the keyword is included solely for compatibility with queries from relational databases.

If you use the LATERAL keyword in a nest that has no lateral correlation, the keyword is ignored.

INNER NEST and LEFT OUTER NEST support the optional LATERAL keyword in front of the right-hand side keyspace.

#### Nest Right-Hand Side

```ebnf
ansi-nest-rhs ::= keyspace-ref ( 'AS'? alias )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/ansi-nest-rhs.png)

* **keyspace-ref**\
[Keyspace Reference](#keyspace-reference) icon:caret-down[]
* **alias**\
[AS Alias](#as-alias) icon:caret-down[]

##### Keyspace Reference

Keyspace reference or expression representing the right-hand side of the NEST clause.
For details, see [Keyspace Reference](n1ql-language-reference/from.adoc#from-keyspace-ref).

##### AS Alias

Assigns another name to the right-hand side of the NEST clause.
For details, see [AS Clause](n1ql-language-reference/from.adoc#section_ax5_2nx_1db).

Assigning an alias to the keyspace reference is optional.
If you assign an alias to the keyspace reference, the `AS` keyword may be omitted.

#### Nest Predicate

```ebnf
ansi-nest-predicate ::= 'ON' expr
```

![Syntax diagram](../../assets/images/n1ql-language-reference/ansi-nest-predicate.png)

* **`expr`**\
Boolean expression representing the nest condition between the left-hand side [FROM term](#left-hand-side) and the right-hand side [Keyspace Reference](#keyspace-reference).
This expression may contain fields, constant expressions, or any complex {sqlpp} expression.

### Limitations

* Full OUTER nest and cross nest types are currently not supported.
* No mixing of ANSI nest syntax with lookup or index nest syntax in the same FROM clause.
* The right-hand-side of any nest must be a keyspace.
Expressions, subqueries, or other join combinations cannot be on the right-hand-side of a nest.
* A nest can only be executed when appropriate index exists on the inner side of the ANSI nest.
* Adaptive indexes are not considered when selecting indexes on inner side of the nest.
* You may chain ANSI nests with comma-separated joins; however, the comma-separated joins must come after any JOIN, NEST, or UNNEST clauses.

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ANSI-NEST-Example-1"></a>**Inner ANSI NEST**

List only airports in Toulouse which have routes starting from them, and nest details of the routes.

**Query**

```sqlpp
SELECT *
FROM airport a
  INNER NEST route r
  ON a.faa = r.sourceairport
WHERE a.city = "Toulouse"
ORDER BY a.airportname;
```

**Results**

```JSON
[
  {
    "a": {
      "airportname": "Blagnac",
      "city": "Toulouse",
      "country": "France",
      "faa": "TLS",
      "geo": {
        "alt": 499,
        "lat": 43.629075,
        "lon": 1.363819
      },
      "icao": "LFBO",
      "id": 1273,
      "type": "airport",
      "tz": "Europe/Paris"
    },
    "r": [
      {
        "airline": "AH",
        "airlineid": "airline_794",
        "destinationairport": "ALG",
        "distance": 787.299015326995,
        "equipment": "736",
        "id": 10265,
// ...
      },
      {
        "airline": "AH",
        "airlineid": "airline_794",
        "destinationairport": "ORN",
        "distance": 906.1483088609814,
        "equipment": "736",
        "id": 10266,
// ...
    ]
  }
]
```

<a name="ANSI-NEST-Example-1A"></a>**Inner LATERAL NEST**

This example is the same as [Example 1](#ANSI-NEST-Example-1), but it includes the optional LATERAL keyword.

**Query**

```sqlpp
SELECT *
FROM airport a
  NEST LATERAL (
    SELECT r1.* FROM route r1
    WHERE a.faa = r1.sourceairport
  ) AS r
  ON true
WHERE a.city = "Toulouse"
ORDER BY a.airportname;
```

**Results**

```JSON
[
  {
    "a": {
      "id": 1273,
      "type": "airport",
      "airportname": "Blagnac",
      "city": "Toulouse",
      "country": "France",
      "faa": "TLS",
      "icao": "LFBO",
      "tz": "Europe/Paris",
      "geo": {
        "lat": 43.629075,
        "lon": 1.363819,
        "alt": 499
      }
    },
    "r": [
      {
        "airline": "AH",
        "airlineid": "airline_794",
        "destinationairport": "ALG",
        "distance": 787.299015326995,
        "equipment": "736",
        "id": 10265,
  // ...
```

<a name="ANSI-NEST-Example-2"></a>**Left Outer ANSI NEST**

List all airports in Toulouse, and nest details of any routes that start from each airport.

**Query**

```sqlpp
SELECT *
FROM airport a
  LEFT NEST route r
  ON a.faa = r.sourceairport
WHERE a.city = "Toulouse"
ORDER BY a.airportname;
```

**Results**

```JSON
[
  {
    "a": {
      "airportname": "Blagnac",
      "city": "Toulouse",
      "country": "France",
      "faa": "TLS",
      "geo": {
        "alt": 499,
        "lat": 43.629075,
        "lon": 1.363819
      },
      "icao": "LFBO",
      "id": 1273,
      "type": "airport",
      "tz": "Europe/Paris"
    },
    "r": [
      {
        "airline": "AH",
        "airlineid": "airline_794",
        "destinationairport": "ALG",
        "distance": 787.299015326995,
        "equipment": "736",
        "id": 10265,
// ...
      }
    ]
  },
  {
    "a": {
      "airportname": "Francazal",
      "city": "Toulouse",
      "country": "France",
      "faa": null,
      "geo": {
        "alt": 535,
        "lat": 43.545555,
        "lon": 1.3675
      },
      "icao": "LFBF",
      "id": 1266,
      "type": "airport",
      "tz": "Europe/Paris"
    },
    "r": [] // ①
  },
  {
    "a": {
      "airportname": "Lasbordes",
      "city": "Toulouse",
      "country": "France",
      "faa": null,
      "geo": {
        "alt": 459,
        "lat": 43.586113,
        "lon": 1.499167
      },
      "icao": "LFCL",
      "id": 1286,
      "type": "airport",
      "tz": "Europe/Paris"
    },
    "r": []
  }
]
```

1. The LEFT OUTER NEST lists all the left-side results, even if there are no matching right-side documents, as indicated by the results in which the fields from the `route` keyspace are null or missing.

## Lookup NEST Clause

Nesting is conceptually the inverse of unnesting.
Nesting performs a join across two keyspaces.
But instead of producing a cross-product of the left and right inputs, a single result is produced for each left input, while the corresponding right inputs are collected into an array and nested as a single array-valued field in the result object.

### Syntax

```ebnf
lookup-nest-clause ::= lookup-nest-type? 'NEST' lookup-nest-rhs lookup-nest-predicate
```

![Syntax diagram](../../assets/images/n1ql-language-reference/lookup-nest-clause.png)

* **lookup-nest-type**\
[Nest Type](#nest-type) icon:caret-down[]
* **lookup-nest-rhs**\
[Nest Right-Hand Side](#nest-right-hand-side) icon:caret-down[]
* **lookup-nest-predicate**\
[Nest Predicate](#nest-predicate) icon:caret-down[]

#### Nest Type

```ebnf
lookup-nest-type ::= 'INNER' | ( 'LEFT' 'OUTER'? )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/lookup-nest-type.png)

This clause represents the type of lookup nest.

* **`INNER`**\
For each result object produced, both the left-hand and right-hand source objects must be non-`MISSING` and non-`NULL`.
* **`LEFT [OUTER]`**\
{startsb}Query Service interprets `LEFT` as `LEFT OUTER`{endsb}

  A left-outer unnest is performed, and at least one result object is produced for each left source object.

  For each joined object produced, only the left-hand source objects must be non-`MISSING` and non-`NULL`.

This clause is optional.
If omitted, the default is `INNER`.

#### Nest Right-Hand Side

```ebnf
lookup-nest-rhs ::= keyspace-ref ( 'AS'? alias )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/lookup-nest-rhs.png)

* **keyspace-ref**\
[Keyspace Reference](#keyspace-reference) icon:caret-down[]
* **alias**\
[AS Alias](#as-alias) icon:caret-down[]

##### Keyspace Reference

Keyspace reference for the right-hand side of the lookup nest.
For details, see [Keyspace Reference](n1ql-language-reference/from.adoc#from-keyspace-ref).

##### AS Alias

Assigns another name to the right-hand side of the lookup nest.
For details, see [AS Clause](n1ql-language-reference/from.adoc#section_ax5_2nx_1db).

Assigning an alias to the keyspace reference is optional.
If you assign an alias to the keyspace reference, the `AS` keyword may be omitted.

#### Nest Predicate

```ebnf
lookup-nest-predicate ::= 'ON' 'KEYS' expr
```

![Syntax diagram](../../assets/images/n1ql-language-reference/lookup-nest-predicate.png)

The `ON KEYS` expression produces a document key or array of document keys for the right-hand side of the lookup nest.

* **expr**\
[Required] String or expression representing the primary keys of the documents for the right-hand side keyspace.

### Return Values

If the right-hand source object is NULL, MISSING, empty, or a non-array value, then the result object’s right-side value is MISSING (omitted).

Nests can be chained with other NEST, JOIN, and UNNEST clauses.
By default, an INNER NEST is performed.
This means that for each result object produced, both the left and right source objects must be non-missing and non-null.
The right-hand side result of NEST is always an array or MISSING.
If there is no matching right source object, then the right source object is as follows:

| If the `ON KEYS` expression evaluates to | Then the right-side value is |
| --- | --- |
| `MISSING` | `MISSING` |
| `NULL` | `MISSING` |
| an array | an empty array |
| a non-array value | an empty array |

### Limitations

Lookup nests can be chained with other lookup joins or nests and index joins or nests, but they cannot be mixed with ANSI joins, ANSI nests, or comma-separated joins.

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="Lookup-NEST-Example-1"></a>**Join two keyspaces producing an output for each left input**

Show one set of routes for one airline in the `airline` keyspace.

**Query**

```sqlpp
SELECT *
FROM route
  INNER NEST airline
  ON KEYS route.airlineid
LIMIT 1;
```

**Results**

```JSON
[
  {
    "airline": [
      {
        "callsign": "AIRFRANS",
        "country": "France",
        "iata": "AF",
        "icao": "AFR",
        "id": 137,
        "name": "Air France",
        "type": "airline"
      }
    ],
    "route": {
      "airline": "AF",
      "airlineid": "airline_137",
      "destinationairport": "MRS",
      "distance": 2881.617376098415,
      "equipment": "320",
      "id": 10000,
      "schedule": [
// ...
      ],
      "sourceairport": "TLV",
      "stops": 0,
      "type": "route"
    }
  }
]
```

## Index NEST Clause

Index NESTs allow you to flip the direction of a Lookup NEST clause.
Index NESTs can be used efficiently when Lookup NESTs cannot efficiently nest left-hand side documents with right-to-left nests, and your situation cannot be flipped because your predicate needs to be on the left-hand side, such as [Join two keyspaces producing an output for each left input](#Lookup-NEST-Example-1) above where airline documents have no reference to route documents.

**📌 NOTE**\
For index nests, the syntax uses `ON KEY` (singular) instead of `ON KEYS` (plural).
This is because an Index NEST’s `ON KEY` expression must produce a scalar value; whereas a Lookup NEST’s `ON KEYS` expression can produce either a scalar or an array value.

### Syntax

```ebnf
index-nest-clause ::= index-nest-type? 'NEST' index-nest-rhs index-nest-predicate
```

![Syntax diagram](../../assets/images/n1ql-language-reference/index-nest-clause.png)

* **index-nest-type**\
[Nest Type](#nest-type) icon:caret-down[]
* **index-nest-rhs**\
[Nest Right-Hand Side](#nest-right-hand-side) icon:caret-down[]
* **index-nest-predicate**\
[Nest Predicate](#nest-predicate) icon:caret-down[]

#### Nest Type

```ebnf
index-nest-type ::= 'INNER' | ( 'LEFT' 'OUTER'? )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/index-nest-type.png)

This clause represents the type of index nest.

* **`INNER`**\
For each nested object produced, both the left-hand and right-hand source objects must be non-MISSING and non-NULL.
* **`LEFT [OUTER]`**\
{startsb}Query Service interprets `LEFT` as `LEFT OUTER`{endsb}

  For each nested object produced, only the left-hand source objects must be non-MISSING and non-NULL.

This clause is optional.
If omitted, the default is `INNER`.

#### Nest Right-Hand Side

```ebnf
index-nest-rhs ::= keyspace-ref ( 'AS'? alias )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/index-nest-rhs.png)

* **keyspace-ref**\
[Keyspace Reference](#keyspace-reference) icon:caret-down[]
* **alias**\
[AS Alias](#as-alias) icon:caret-down[]

##### Keyspace Reference

Keyspace reference or expression representing the right-hand side of the NEST clause.
For details, see [Keyspace Reference](n1ql-language-reference/from.adoc#from-keyspace-ref).

##### AS Alias

Assigns another name to the right-hand side of the NEST clause.
For details, see [AS Clause](n1ql-language-reference/from.adoc#section_ax5_2nx_1db).

Assigning an alias to the keyspace reference is optional.
If you assign an alias to the keyspace reference, the `AS` keyword may be omitted.

#### Nest Predicate

```ebnf
index-nest-predicate ::= 'ON' 'KEY' expr 'FOR' alias
```

![Syntax diagram](../../assets/images/n1ql-language-reference/index-nest-predicate.png)

* **`expr`**\
Expression in the form `__rhs-expression__.__lhs-expression-key__`:

`__rhs-expression__`;; Keyspace reference for the right-hand side of the index nest.

`__lhs-expression-key__`;; String or expression representing the attribute in `__rhs-expression__` and referencing the document key for `alias`.

* **`alias`**\
Keyspace reference for the left-hand side of the index nest.

### Limitations

Index nests can be chained with other index joins or nests and lookup joins or nests, but they cannot be mixed with ANSI joins, ANSI nests, or comma-separated joins.

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="Index-NEST-Example-1"></a>**Use INDEX nest to flip the direction of [Join two keyspaces producing an output for each left input](#Lookup-NEST-Example-1) above**

This example nests the airline routes for each airline after creating the following index.
(Note that the index will not match if it contains a WHERE clause.)

**Index**

```sqlpp
CREATE INDEX route_airlineid ON route(airlineid);
```

**Query**

```sqlpp
SELECT *
FROM airline aline
  INNER NEST route rte
  ON KEY rte.airlineid FOR aline
LIMIT 1;
```

**Results**

```JSON
[
  {
    "aline": {
      "callsign": "MILE-AIR",
      "country": "United States",
      "iata": "Q5",
      "icao": "MLA",
      "id": 10,
      "name": "40-Mile Air",
      "type": "airline"
    },
    "rte": [
      {
        "airline": "Q5",
        "airlineid": "airline_10",
        "destinationairport": "FAI",
        "distance": 118.20183585107631,
        "equipment": "CNA",
        "id": 46587,
        "schedule": [
// ...
        ],
        "sourceairport": "HKB",
        "stops": 0,
        "type": "route"
      },
      {
        "airline": "Q5",
        "airlineid": "airline_10",
        "destinationairport": "HKB",
        "distance": 118.20183585107631,
        "equipment": "CNA",
        "id": 46586,
        "schedule": [
// ...
        ],
        "sourceairport": "FAI",
        "stops": 0,
        "type": "route"
      }
    ]
  }
]
```

If you generalize the same query, it looks like the following:

```
CREATE INDEX _on-key-for-index-name_ _rhs-expression_ (__lhs-expression-key__);
```

```
SELECT _projection-list_
FROM _lhs-expression_
  NEST _rhs-expression_
  ON KEY __rhs-expression__.__lhs-expression-key__ FOR _lhs-expression_
[ WHERE _predicates_ ] ;
```

There are three important changes in the index scan syntax example above:

* `CREATE INDEX` on the `ON KEY` expression `rte.airlineid` to access `route` documents using `airlineid` (which are produced on the left-hand side).
* The `ON KEY rte.airlineid FOR aline` enables {sqlpp} to use the index `route_airlineid`.
* Create any optional index, such as `route_airline`, that can be used on `airline` (left-hand side).

## Appendix: Summary of NEST Types

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

### ANSI

|     |     |
| --- | --- |
| Left-Hand Side (lhs) | Any field or expression that produces a value that will be matched on the right-hand side. |
| Right-Hand Side (rhs) | Anything that can have a proper index on the join expression. |
| Syntax |  |
```
_lhs-expr_
NEST _rhs-keyspace_
ON _any nest condition_
```
| Example |  |
```sqlpp
SELECT *
FROM route r
NEST airline a
ON r.airlineid = META(a).id
LIMIT 4;
```

### Lookup

|     |     |
| --- | --- |
| Left-Hand Side (lhs) | Must produce a Document Key for the right-hand side. |
| Right-Hand Side (rhs) | Must have a Document Key. |
| Syntax |  |
```
_lhs-expr_
NEST _rhs-keyspace_
ON KEYS _lhs-expr.foreign_key_
```
| Example |  |
```sqlpp
SELECT *
FROM route r
NEST airline a
ON KEYS r.airlineid
LIMIT 4;
```

### Index

|     |     |
| --- | --- |
| Left-Hand Side (lhs) | Must produce a key for the right-hand side index. |
| Right-Hand Side (rhs) | Must have a proper index on the field or expression that maps to the Document Key of the left-hand side. |
| Syntax |  |
```
_lhs-keyspace_
NEST _rhs-keyspace_
ON KEY _rhs-kspace.idx_key_
FOR _lhs-keyspace_
```
| Example |  |
```sqlpp
SELECT *
FROM airline a
NEST route r
ON KEY r.airlineid FOR a
LIMIT 4;
```
