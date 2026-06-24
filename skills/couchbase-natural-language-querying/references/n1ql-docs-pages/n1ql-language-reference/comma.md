# Comma-Separated Join

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

A comma-separated join enables you to produce new input objects by creating a Cartesian product of all the source objects.

## Purpose

A comma-separated join is used within the [FROM](n1ql-language-reference/from.adoc) clause.
Like the [JOIN](n1ql-language-reference/join.adoc) clause, it creates an input object by combining two or more source objects.
A comma-separated join can combine arbitrary fields from the source documents, and you can chain several comma-separated joins together.

(((join predicate,comma-separated join)))
The comma-separated join, by itself, does not specify a join predicate.
This means that, in its basic form, the comma-separated join would produce all the possible combinations of the combined source objects -- this is known as the _Cartesian product_.

In practice, it is common to use the query’s [WHERE](n1ql-language-reference/where.adoc) clause to specify a condition for the comma-separated join.
Refer to the examples below for further details.

## Prerequisites

For you to select data from keyspace or expression, you must have the `query_select` privilege on that keyspace.
For more details about user roles, see [Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
comma-separated-join ::= ',' 'LATERAL'? ( rhs-keyspace | rhs-subquery | rhs-generic )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/comma-separated-join.png)

* **rhs-keyspace**\
[Right-Hand Side Keyspace](#right-hand-side-keyspace) icon:caret-down[]
* **rhs-subquery**\
[Right-Hand Side Subquery](#right-hand-side-subquery) icon:caret-down[]
* **rhs-generic**\
[Right-Hand Side Generic Expression](#right-hand-side-generic-expression) icon:caret-down[]

### Left-Hand Side

The comma-separated join cannot be the first term within the `FROM` clause; it must be preceded by another FROM term.
The term immediately preceding the comma-separated join represents the _left-hand side_ of the comma-separated join.

You can chain the comma-separated join with any of the other permitted FROM terms, including another comma-separated join.
For more information, see the page on the [FROM](n1ql-language-reference/from.adoc) clause.

There are restrictions on what types of FROM terms may be chained and in what order -- see the descriptions on this page for more details.

The types of FROM term that may be used as the left-hand side of the comma-separated join are summarized in the following table.

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
| previous comma-separated join |  |
```N1QL
SELECT a.airportname, h.name AS hotel, l.name AS landmark
FROM airport AS a,
     hotel AS h,
     landmark AS l
WHERE a.city = h.city
  AND h.city = l.city
LIMIT 5;
```

(((join type,comma-separated join)))
The comma-separated join is a type of inner join.
For each joined object produced, both the left-hand side and right-hand side source objects must be non-MISSING and non-NULL.

(((right-hand side,comma-separated join)))
The _right-hand side_ of a comma-separated join may be a keyspace reference, a subquery, or a generic expression term.

### LATERAL Join

When an expression on the right-hand side of a comma-separated join references a keyspace that is already specified in the same FROM clause, the expression is said to be correlated.
In relational databases, a join which contains correlated expressions is referred to as a lateral join.
In {sqlpp}, lateral correlations are detected automatically, and there is no need to specify that a join is lateral.

In Couchbase Server 7.6 and later, you can use the LATERAL keyword as a visual reminder that a join contains correlated expressions.
The LATERAL keyword is not required -- the keyword is included solely for compatibility with queries from relational databases.

If you use the LATERAL keyword in a join that has no lateral correlation, the keyword is ignored.

You can use the optional LATERAL keyword in front of the right-hand side keyspace of a comma-separated join.

**📌 NOTE**\
Using the LATERAL keyword in a comma-separated join implies that the right-hand side of the join must appear after the left-hand side of the join.
This may prevent the cost-based optimizer from reordering joins in the query to give the optimal join order.
For details, see [Join Enumeration](n1ql:n1ql-language-reference/cost-based-optimizer.adoc#join-enumeration).

### Right-Hand Side Keyspace

```ebnf
rhs-keyspace ::= keyspace-ref ( 'AS'? alias )? ansi-join-hints?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/rhs-keyspace.png)

* **keyspace-ref**\
[Keyspace Reference](#keyspace-reference) icon:caret-down[]
* **alias**\
[AS Alias](#as-alias) icon:caret-down[]
* **ansi-join-hints**\
[USE Clause](#use-clause) icon:caret-down[]

#### Keyspace Reference

Keyspace reference for the right-hand side of the comma-separated join.
For details, see [Keyspace Reference](n1ql-language-reference/from.adoc#from-keyspace-ref).

#### AS Alias

Assigns another name to the keyspace reference.
For details, see [AS Clause](n1ql-language-reference/from.adoc#section_ax5_2nx_1db).

Assigning an alias to the keyspace reference is optional.
If you assign an alias to the keyspace reference, the `AS` keyword may be omitted.

#### USE Clause

Enables you to specify that the join should use particular keys, a particular index, or a particular join method.
For details, see [ANSI JOIN Hints](n1ql-language-reference/join.adoc#ansi-join-hints).

**💡 TIP**\
You can also supply a join hint within a specially-formatted [hint comment](n1ql-language-reference/optimizer-hints.adoc).
Note that you cannot specify a join hint for the same keyspace using both the `USE` clause and a hint comment.
If you do this, the `USE` clause and the hint comment are both marked as erroneous and ignored by the optimizer.

### Right-Hand Side Subquery

```ebnf
rhs-subquery ::= subquery-expr 'AS'? alias
```

![Syntax diagram](../../assets/images/n1ql-language-reference/rhs-subquery.png)

* **subquery-expr**\
[Subquery Expression](#subquery-expression) icon:caret-down[]
* **alias**\
[AS Alias](#as-alias) icon:caret-down[]

#### Subquery Expression

Use parentheses to specify a subquery for the right-hand side of the comma-separated join.
For details, see [Subquery Expression](n1ql-language-reference/from.adoc#select-expr-clause).

**📌 NOTE**\
A subquery on the right-hand side of the comma-separated join cannot be **correlated**, i.e. it cannot refer to a keyspace in the outer query block.
This will lead to an error.

#### AS Alias

Assigns another name to the subquery.
For details, see [AS Clause](n1ql-language-reference/from.adoc#section_ax5_2nx_1db).

You must assign an alias to a subquery on the right-hand side of the join.
However, when you assign an alias to the subquery, the `AS` keyword may be omitted.

### Right-Hand Side Generic Expression

```ebnf
rhs-generic ::= expr ( 'AS'? alias )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/rhs-generic.png)

* **expr**\
[Expression Term](#expression-term) icon:caret-down[]
* **alias**\
[AS Alias](#as-alias) icon:caret-down[]

#### Expression Term

A {sqlpp} [expression](n1ql-language-reference/index.adoc#N1QL_Expressions) generating JSON documents or objects for the right-hand side of the comma-separated join.

**📌 NOTE**\
An expression on the right-hand side of the comma-separated join may be **correlated**, i.e. it may refer to a keyspace on the left-hand side of the join.
In this case, only a [nested-loop join](#ansi-join-hints) may be used.

#### AS Alias

Assigns another name to the generic expression.
For details, see [AS Clause](n1ql-language-reference/from.adoc#section_ax5_2nx_1db).

You must assign an alias to the generic expression if it is not an identifier; otherwise, assigning an alias is optional.
However, when you assign an alias to the generic expression, the `AS` keyword may be omitted.

## Limitations

* You can chain comma-separated joins with ANSI `JOIN` clauses, ANSI `NEST` clauses, and `UNNEST` clauses.
However, you cannot chain comma-separated joins with lookup `JOIN` and `NEST` clauses, or index `JOIN` and `NEST` clauses.
* The right-hand side of a comma-separated join can only be a keyspace identifier, a subquery, or a generic expression.
This means that comma-separated joins must come _after_ any `JOIN`, `NEST`, or `UNNEST` clauses.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="example-cartesian"></a>**Cartesian product**

The following query lists every possible combination of the two input objects.

**Comma-separated join**

```sqlpp
SELECT * FROM [{"abc": 1}, {"abc": 2}, {"abc": 3}] AS a,
              [{"xyz": 1}, {"xyz": 2}] AS b;
```

Compare the query above with the following query using an ANSI join.

**ANSI join**

```sqlpp
SELECT * FROM [{"abc": 1}, {"abc": 2}, {"abc": 3}] AS a
         JOIN [{"xyz": 1}, {"xyz": 2}] AS b ON true;
```

The results of the two queries are the same.

**Results**

```json
[
  {
    "a": {
      "abc": 1
    },
    "b": {
      "xyz": 1
    }
  },
  {
    "a": {
      "abc": 1
    },
    "b": {
      "xyz": 2
    }
  },
  {
    "a": {
      "abc": 2
    },
    "b": {
      "xyz": 1
    }
  },
  {
    "a": {
      "abc": 2
    },
    "b": {
      "xyz": 2
    }
  },
  {
    "a": {
      "abc": 3
    },
    "b": {
      "xyz": 1
    }
  },
  {
    "a": {
      "abc": 3
    },
    "b": {
      "xyz": 2
    }
  }
]
```

<a name="example-condition"></a>**Comma-separated join condition**

The following query uses the WHERE clause to define the condition for a comma-separated join.

**Comma-separated join**

```sqlpp
SELECT a.airportname AS airport, r.id AS route
FROM route AS r,
     airport AS a
WHERE a.faa = r.sourceairport
LIMIT 4;
```

Compare the query above with the following query using an ANSI join.

**ANSI join**

```sqlpp
SELECT a.airportname AS airport, r.id AS route
FROM route AS r
JOIN airport AS a
  ON a.faa = r.sourceairport
LIMIT 4;
```

The results of the two queries are the same.

**Results**

```json
[
  {
    "airport": "Lehigh Valley Intl",
    "route": 20010
  },
  {
    "airport": "Lehigh Valley Intl",
    "route": 20011
  },
  {
    "airport": "Lehigh Valley Intl",
    "route": 28856
  },
  {
    "airport": "Lehigh Valley Intl",
    "route": 28857
  }
]
```

<a name="example-filters"></a>**Comma-separated join with filters**

The following query uses the WHERE clause to define a condition for a comma-separated join and to filter the query.

**Comma-separated join**

```sqlpp
SELECT a.airportname AS airport, r.id AS route
FROM route AS r,
     airport AS a
WHERE a.faa = r.sourceairport
  AND r.sourceairport = "SFO"
LIMIT 4;
```

Compare the query above with the following query using an ANSI join.

**ANSI join**

```sqlpp
SELECT a.airportname AS airport, r.id AS route
FROM route AS r
JOIN airport AS a
  ON a.faa = r.sourceairport
WHERE r.sourceairport = "SFO"
LIMIT 4;
```

The results of the two queries are the same.

**Results**

```json
[
  {
    "airport": "San Francisco Intl",
    "route": 10624
  },
  {
    "airport": "San Francisco Intl",
    "route": 10625
  },
  {
    "airport": "San Francisco Intl",
    "route": 11212
  },
  {
    "airport": "San Francisco Intl",
    "route": 11213
  }
]
```

<a name="example-hints"></a>**Comma-separated join with hints**

The following query uses the USE clause to specify hints for a comma-separated join.

**Comma-separated join**

```sqlpp
EXPLAIN SELECT a.airportname AS airport, r.id AS route
FROM route AS r,
     airport AS a
     USE INDEX(def_inventory_airport_faa) NL
WHERE a.faa = r.sourceairport
  AND r.sourceairport = "SFO"
LIMIT 4;
```

Compare the query above with the following query using an ANSI join.

**ANSI join**

```sqlpp
EXPLAIN SELECT a.airportname AS airport, r.id AS route
FROM route AS r
JOIN airport AS a
 USE INDEX(def_inventory_airport_faa) NL
  ON a.faa = r.sourceairport
WHERE r.sourceairport = "SFO"
LIMIT 4;
```

The results of the two queries are the same.

**Results**

```json
[
  {
    "optimizer_hints": {
      "hints_followed": [
        "USE_NL(a)",
        "INDEX(a def_inventory_airport_faa)"
      ]
    },
    // ...
  }
]
```

<a name="example-chain"></a>**Chaining ANSI joins with comma-separated joins**

The following query chains an ANSI join with a comma-separated join.

**Query**

```sqlpp
SELECT l.name AS airline, a.airportname AS airport, r.id AS route
FROM airline AS l
JOIN route AS r
  ON META(l).id = r.airlineid,
     airport AS a
WHERE a.faa = r.sourceairport
  AND r.sourceairport = "SFO"
LIMIT 4;
```

**Results**

```json
[
  {
    "airline": "AirTran Airways",
    "airport": "San Francisco Intl",
    "route": 25480
  },
  {
    "airline": "AirTran Airways",
    "airport": "San Francisco Intl",
    "route": 25481
  },
  {
    "airline": "AirTran Airways",
    "airport": "San Francisco Intl",
    "route": 25482
  },
  {
    "airline": "AirTran Airways",
    "airport": "San Francisco Intl",
    "route": 25483
  }
]
```

<a name="example-lateral"></a>**Lateral correlation**

The following query has a lateral correlation between the subquery and the `airport` keyspace.

**Comma-separated join**

```sqlpp
SELECT airport.airportname, t2.name
FROM airport,
(SELECT name FROM hotel WHERE hotel.city = airport.city) AS t2
LIMIT 5;
```

Compare the query above with the following query using the LATERAL keyword.

**Comma-separated join with LATERAL keyword**

```sqlpp
SELECT airport.airportname, t2.name
FROM airport,
LATERAL (SELECT name FROM hotel WHERE hotel.city = airport.city) AS t2
LIMIT 5;
```

The results of the two queries are the same.

**Results**

```json
[
  {
    "airportname": "Mandelieu",
    "name": "Hotel Cybelle"
  },
  {
    "airportname": "Cote D\\'Azur",
    "name": "Best Western Hotel Riviera Nice"
  },
  {
    "airportname": "Cote D\\'Azur",
    "name": "Hotel Anis"
  },
  {
    "airportname": "Cote D\\'Azur",
    "name": "NH Nice"
  },
  {
    "airportname": "Cote D\\'Azur",
    "name": "Hotel Suisse"
  }
]
```
