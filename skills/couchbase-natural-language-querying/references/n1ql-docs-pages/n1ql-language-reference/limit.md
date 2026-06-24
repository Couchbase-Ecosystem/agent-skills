# LIMIT clause

The LIMIT clause specifies the maximum number of documents to be returned in a resultset by a SELECT statement.

## Purpose

When you don’t need the entire resultset, use the `LIMIT` clause to specify the maximum number of documents to be returned in a resultset by a `SELECT` query.

The `LIMIT` and `OFFSET` clauses are evaluated after the `ORDER BY` clause.

(((pagination)))
You can use the `OFFSET` and `LIMIT` clauses together to _paginate_ the results -- that is, to split the resultset into pages, each containing a specified number of documents, for display purposes.

**📌 NOTE**\
Starting from version 4.5, the LIMIT clause in INSERT, UPDATE, and DELETE statements is no longer a hint.
It indicates that the actual number of mutations will be less than or equal to the specified LIMIT.

## Syntax

```ebnf
limit-clause ::= 'LIMIT' expr
```

![Syntax diagram](../../assets/images/n1ql-language-reference/limit-clause.png)

## Arguments

* **expr**\
Integer or an expression that evaluates to an integer representing the number of resulting documents.
A negative value is the same as `LIMIT 0`.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex1"></a>**Get only 2 documents of hotels with an empty room**

```sqlpp
SELECT name, address, city, country, url
FROM hotel
WHERE vacancy = true
LIMIT 2;
```

**Result**

```json
[
  {
    "address": "Capstone Road, ME7 3JE",
    "city": "Medway",
    "country": "United Kingdom",
    "name": "Medway Youth Hostel",
    "url": "http://www.yha.org.uk"
  },
  {
    "address": "6 rue aux Juifs",
    "city": "Giverny",
    "country": "France",
    "name": "The Robins",
    "url": "http://givernyguesthouse.com/robin.htm"
  }
]
```

<a name="ex2"></a>**Paginate the results using OFFSET and LIMIT**

The following query uses named parameters and expressions to display the specified page of results, assuming that page numbering starts at zero.

```sqlpp
SELECT name, address, city, country, url
FROM hotel
WHERE vacancy = true
OFFSET $page * $results
LIMIT $results;
```

Setting the page number to zero, with two results per page, the results are the same as [Get only 2 documents of hotels with an empty room](#ex1).

**Result**

```json
[
  {
    "address": "Capstone Road, ME7 3JE",
    "city": "Medway",
    "country": "United Kingdom",
    "name": "Medway Youth Hostel",
    "url": "http://www.yha.org.uk"
  },
  {
    "address": "6 rue aux Juifs",
    "city": "Giverny",
    "country": "France",
    "name": "The Robins",
    "url": "http://givernyguesthouse.com/robin.htm"
  }
]
```
