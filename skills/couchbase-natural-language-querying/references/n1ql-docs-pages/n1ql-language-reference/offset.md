# OFFSET clause

The OFFSET clause specifies the number of resultset objects to skip in a SELECT query.

## Purpose

When you want the resultset to skip over the first few resulting objects, use the `OFFSET` clause to specify that number of objects to ignore.

The `LIMIT` and `OFFSET` clauses are evaluated after the `ORDER BY` clause.

If a `LIMIT` clause is also present, the `OFFSET` is applied prior to the `LIMIT`; that is, the specified number of objects is omitted from the result set before enforcing a specified `LIMIT`.

(((pagination)))
You can use the `OFFSET` and `LIMIT` clauses together to _paginate_ the results -- that is, to split the resultset into pages, each containing a specified number of documents, for display purposes.

## Syntax

```ebnf
offset-clause ::= 'OFFSET' expr
```

![Syntax diagram](../../assets/images/n1ql-language-reference/offset-clause.png)

## Arguments

* **expr**\
Integer or an expression that evaluates to an integer which is non-negative.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**List 4 airport cities after skipping the first 200**

```sqlpp
SELECT DISTINCT city
FROM airport
ORDER BY city
LIMIT 4
OFFSET 200;
```

**Results**

```json
[
  {
    "city": "Brownsville"
  },
  {
    "city": "Brownwood"
  },
  {
    "city": "Brunswick"
  },
  {
    "city": "Bryan"
  }
]
```

**Paginate the results using OFFSET and LIMIT**

The following query uses named parameters and expressions to display the specified page of results, assuming that page numbering starts at zero.

```sqlpp
SELECT name, address, city, country, url
FROM hotel
WHERE vacancy = true
OFFSET $page * $results
LIMIT $results;
```

Setting the page number to zero, with two results per page, the results are as follows.

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
