# Query Block Hints

Query block hints are hints that apply to an entire query block.

A query hint is a type of [optimizer hint](n1ql-language-reference/optimizer-hints.adoc).
Currently {sqlpp} supports only one query block hint: ORDERED.

There are two possible formats for each optimizer hint: simple syntax and JSON syntax.
Note that you cannot mix simple syntax and JSON syntax in the same hint comment.

## ORDERED

If present, this hint directs the optimizer to order any joins just as they are ordered in the query.
If not specified, the optimizer determines the optimal join order.

**📌 NOTE**\
This hint is only available in the [SELECT Clause](n1ql-language-reference/selectclause.adoc).

### Simple Syntax

```ebnf
ordered-hint-simple ::= 'ORDERED'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/ordered-hint-simple.png)

With the simple syntax, this hint takes no arguments.
You may only use this hint once within the hint comment.

### JSON Syntax

```ebnf
ordered-hint-json ::= '"ordered"' ':' 'true'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/ordered-hint-json.png)

With the JSON syntax, this hint takes the form of an `ordered` property.
You may only use this property once within the hint comment.
The value of this property must be set to `true`.

### Examples

For the examples in this section, it is assumed that the cost-based optimizer is active, and all optimizer statistics are up-to-date.

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-ordered-opt"></a>**Optimized join ordering**

Consider the following query, which does not contain an ordering hint.

**Query**

```sqlpp
SELECT a.airportname AS source, r.id AS route, l.name AS airline
FROM airport AS a
JOIN route AS r -- ①
  ON r.sourceairport = a.faa
JOIN airline AS l -- ②
  ON r.airlineid = META(l).id
WHERE l.name = "40-Mile Air";
```

1. Join the `airport` keyspace to the `route` keyspace.
2. Join the resulting dataset to the `airline` keyspace.

If you examine the plan for this query, you can see that with no hint specified, the optimizer has re-ordered the joins.

!["Query plan with optimized join order"](../../assets/images/join-order-optimize.png)

1. Join the `airline` keyspace to the `route` keyspace.
2. Join the resulting dataset to the `airport` keyspace.

<a name="ex-ordered-simple"></a>**ORDERED hint -- simple syntax**

This example is equivalent to the one in the [Optimized join ordering](#ex-ordered-opt) example, but includes an ordering hint using simple syntax.

**Query**

```sqlpp
SELECT /*+ ORDERED */
       a.airportname AS source, r.id AS route, l.name AS airline
FROM airport AS a
JOIN route AS r -- ①
  ON r.sourceairport = a.faa
JOIN airline AS l -- ②
  ON r.airlineid = META(l).id
WHERE l.name = "40-Mile Air";
```

1. Join the `airport` keyspace to the `route` keyspace.
2. Join the resulting dataset to the `airline` keyspace.

If you examine the plan for this query, you can see that the joins are ordered just as they were written.

!["Query plan with ORDERED hint"](../../assets/images/join-order-hint.png)

1. Join the `airport` keyspace to the `route` keyspace.
2. Join the resulting dataset to the `airline` keyspace.

<a name="ex-ordered-json"></a>**ORDERED hint -- JSON syntax**

This example is equivalent to the one in the [Optimized join ordering](#ex-ordered-opt) example, but includes an ordering hint using JSON syntax.

**Query**

```sqlpp
SELECT /*+ {"ordered": true} */
       a.airportname AS source, r.id AS route, l.name AS airline
FROM airport AS a
JOIN route AS r -- ①
  ON r.sourceairport = a.faa
JOIN airline AS l -- ②
  ON r.airlineid = META(l).id
WHERE l.name = "40-Mile Air";
```

1. Join the `airport` keyspace to the `route` keyspace.
2. Join the resulting dataset to the `airline` keyspace.

If you examine the plan for this query, you can see that the joins are ordered just as they were written, just like the query in the previous example.

### Legacy Equivalent

There is no legacy clause equivalent to this hint.

## Related Links

* [n1ql-language-reference/cost-based-optimizer.adoc](n1ql-language-reference/cost-based-optimizer.adoc)
* [n1ql-language-reference/optimizer-hints.adoc](n1ql-language-reference/optimizer-hints.adoc)
* [n1ql-language-reference/keyspace-hints.adoc](n1ql-language-reference/keyspace-hints.adoc)
