# WHERE clause

The `WHERE` clause filters resultsets based specified conditions.

## Purpose

When you want to narrow down your resultset by one or more criteria, use the `WHERE` clause to filter your resultset.

## Syntax

```ebnf
where-clause ::= 'WHERE' cond
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/where-clause.png)

## Arguments

* **cond**\
[Required] Conditional expression that represents a filter to be applied to the resultset.
Records for which the condition resolves to TRUE are propagated to the resultset.

You can construct complex conditional expressions, for example by using the [logical operators](n1ql-language-reference/logicalops.adoc) `AND`, `OR`, and `NOT`.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Use WHERE filter the resultset**

To list only airports that are in France, use the `WHERE` clause for the "country" field.

```sqlpp
SELECT airportname, city, country
FROM airport
WHERE country = "France"
LIMIT 4;
```

**Results**

```json
[
  {
    "airportname": "Calais Dunkerque",
    "city": "Calais",
    "country": "France"
  },
  {
    "airportname": "Peronne St Quentin",
    "city": "Peronne",
    "country": "France"
  },
  {
    "airportname": "Les Loges",
    "city": "Nangis",
    "country": "France"
  },
  {
    "airportname": "Couterne",
    "city": "Bagnole-de-l'orne",
    "country": "France"
  }
]
```

**Use WHERE and OR to filter the resultset**

List only the landmarks that start with the letter "C" or "K".
Note that the first position of the `SUBSTR` function is `0`.

```sqlpp
SELECT name
FROM landmark
WHERE CONTAINS(SUBSTR(name,0,1),"C")
   OR CONTAINS(SUBSTR(name,0,1),"K")
LIMIT 4;
```

**Results**

```json
[
  {
    "name": "City Chambers"
  },
  {
    "name": "Kingston Bridge"
  },
  {
    "name": "Clyde Arc"
  },
  {
    "name": "Clyde Auditorium"
  }
]
```

**Use WHERE, AND and NOT to filter the resultset**

List landmark restaurants, except Thai restaurants.

```sqlpp
SELECT name, activity
FROM landmark
WHERE activity = "eat"
AND NOT CONTAINS(name,"Thai")
LIMIT 4;
```

**Results**

```json
[
  {
    "activity": "eat",
    "name": "Hollywood Bowl"
  },
  {
    "activity": "eat",
    "name": "Spice Court"
  },
  {
    "activity": "eat",
    "name": "Beijing Inn"
  },
  {
    "activity": "eat",
    "name": "Ossie's Fish and Chips"
  }
]
```
