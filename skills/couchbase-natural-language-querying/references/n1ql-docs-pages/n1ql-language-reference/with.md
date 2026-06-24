# WITH clause

Use `WITH` to create a **common table expression**.
The common table expression may be temporary result set that can be used as a data source for the query, or an expression for later use within a query.

## Purpose

Common table expressions or CTEs can be used to simplify complex queries.
They can also be particularly useful when a value needs to be used several times in a query.

The WITH clause has comparable functionality to the [LET](n1ql-language-reference/let.adoc) clause.
The major difference between the WITH clause and the LET clause is that the WITH clause can come before the SELECT clause, enabling an earlier definition of expressions; whereas the LET clause must come after the [FROM](n1ql-language-reference/from.adoc) clause.

The WITH clause is evaluated once per query block, and LET is evaluated for every object produced by the FROM or JOIN clause.

You can chain WITH clauses.
A CTE that you create in one WITH clause may be referenced in a later WITH clause.

## Prerequisites

The WITH clause can only be used preceding a SELECT statement, and in order for you to select data from a document or keyspace, you must have the `query_select` privilege on the document or keyspace.
For more details about user roles, see
[Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
with-clause ::= 'WITH' alias 'AS' '(' ( select | expr ) ')'
                 ( ',' alias 'AS' '(' ( select | expr ) ')' )*
```

![Syntax diagram](../../assets/images/n1ql-language-reference/with-clause.png)

## Arguments

* **alias**\
[Required] String or [expression](n1ql-language-reference/index.adoc) that represents the name of the variable.
* **select**\
[SELECT](n1ql-language-reference/selectclause.adoc) statement that returns a temporary result set assigned to `alias`.
* **expression**\
String or [expression](n1ql-language-reference/index.adoc) that represents a value assigned to `alias`.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Use a common table expression to create an expression for use in a query**

Find the average number of public likes for each record.
Then find all hotels with a greater than average number of public likes.

```sqlpp
WITH avgLikeCount AS (
  SELECT VALUE AVG(DISTINCT ARRAY_COUNT(cte.public_likes))
  FROM hotel AS cte
)
SELECT hotel.name, ARRAY_COUNT(hotel.public_likes) AS likeCount
FROM hotel
WHERE ARRAY_COUNT(hotel.public_likes) > avgLikeCount[0]
LIMIT 5;
```

**Results**

```json
[
  {
    "likeCount": 8,
    "name": "Medway Youth Hostel"
  },
  {
    "likeCount": 7,
    "name": "Le Clos Fleuri"
  },
  {
    "likeCount": 9,
    "name": "Windy Harbour Farm Hotel"
  },
  {
    "likeCount": 5,
    "name": "Avondale Guest House"
  },
  {
    "likeCount": 8,
    "name": "The Bulls Head"
  }
]
```

**Use a common table expression to create a record subset for use in a query**

Create a recordset of hotel names and their Cleanliness ratings.
Then use this recordset to find the names all hotels whose average Cleanliness rating is greater than 4.5.

```sqlpp
WITH hotels AS (
  SELECT name, reviews[*].ratings[*].Cleanliness
  FROM hotel
)
SELECT hotels.name
FROM hotels
WHERE ARRAY_AVG(hotels.Cleanliness) > 4.5
LIMIT 5;
```

**Results**

```json
[
  {
    "name": "The George Hotel"
  },
  {
    "name": "Windy Harbour Farm Hotel"
  },
  {
    "name": "Avondale Guest House"
  },
  {
    "name": "The Bulls Head"
  },
  {
    "name": "Hill House Holiday Cottage"
  }
]
```
