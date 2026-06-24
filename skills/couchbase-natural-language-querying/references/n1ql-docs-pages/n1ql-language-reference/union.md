# UNION, INTERSECT, and EXCEPT

The set operators [UNION](#union), [INTERSECT](#intersect), and [EXCEPT](#except) combine the resultsets of two or more `SELECT` statements.

## Syntax

```ebnf
set-op ::= ( 'UNION' | 'INTERSECT' | 'EXCEPT' ) 'ALL'?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/set-op.png)

### UNION

Returns all values from both the first and second `SELECT` statements.

### INTERSECT

Returns only values present in both the first and second `SELECT` statements.

### EXCEPT

Returns values from the first `SELECT` statement that are absent from the second `SELECT` statement.

## Return Values

`UNION`, `INTERSECT`, and `EXCEPT` return distinct results, such that there are no duplicates.

`UNION ALL`, `INTERSECT ALL`, and `EXCEPT ALL` return all applicable values, including duplicates.
These queries are faster, because they do not compute distinct results.

You can improve the performance of a query by using covering indexes, where the index includes all the information needed to satisfy the query.
For more information, see [Covering Indexes](indexes:covering-indexes.adoc).

To order all the results of a set operator together, refer to the examples for the [ORDER BY](n1ql-language-reference/orderby.adoc#Ex2) clause.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

For the following examples, consider these queries and the number of results they return.

**Q1**

```sqlpp
SELECT DISTINCT city FROM airport;
```
(1641 results)

**Q2**

```sqlpp
SELECT DISTINCT city FROM hotel;
```
(274 results)

**📌 NOTE**\
The `SELECT` statements in the following examples do not need to use the DISTINCT keyword, since the set operators return distinct results when used without the ALL keyword.

**UNION of Q1 and Q2**

```sqlpp
SELECT city FROM airport
UNION
SELECT city FROM hotel;
```

This gives 1871 results:

```json
[
  {
    "city": "Calais"
  },
  {
    "city": "Peronne"
  },
  {
    "city": "Nangis"
  },
  {
    "city": "Bagnole-de-l'orne"
  },
// ...
]
```

**INTERSECT of Q1 and Q2**

```sqlpp
SELECT city FROM airport
INTERSECT
SELECT city FROM hotel;
```

This gives 44 results:

```json
[
  {
    "city": "Cannes"
  },
  {
    "city": "Nice"
  },
  {
    "city": "Orange"
  },
  {
    "city": "Avignon"
  },
// ...
]
```

**EXCEPT of Q1 and Q2**

```sqlpp
SELECT city FROM airport
EXCEPT
SELECT city FROM hotel;
```

This gives 1597 results:

```json
[
  {
    "city": "Calais"
  },
  {
    "city": "Peronne"
  },
  {
    "city": "Nangis"
  },
  {
    "city": "Bagnole-de-l'orne"
  },
// ...
]
```

**EXCEPT of Q2 and Q1**

```sqlpp
SELECT city FROM hotel
EXCEPT
SELECT city FROM airport;
```

This gives 230 results:

```json
[
  {
    "city": "Medway"
  },
  {
    "city": "Gillingham"
  },
  {
    "city": "Giverny"
  },
  {
    "city": "Highland"
  },
// ...
]
```
