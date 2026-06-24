# UNNEST clause

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

The UNNEST clause creates an input object by flattening an array in the parent document.

## Purpose

The `UNNEST` clause is used within the [FROM](n1ql-language-reference/from.adoc) clause.
If a document or object contains a nested array, UNNEST conceptually performs a join of the nested array with its parent object.
Each resulting joined object becomes an output of the query.
Unnests can be chained.

**💡 TIP**\
To return the position of the elements in an unnested array after you use `UNNEST`, use the [UNNEST_POS function](n1ql-language-reference/metafun.adoc#unnest-pos).

## Syntax

```ebnf
unnest-clause ::= unnest-type? ( 'UNNEST' | 'FLATTEN' ) expr ( 'AS'? alias )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/unnest-clause.png)

* **unnest-type**\
[Unnest Type](#unnest-type) icon:caret-down[]
* **expr**\
[Unnest Path](#unnest-path) icon:caret-down[]
* **alias**\
[AS Alias](#as-alias) icon:caret-down[]

### Left-Hand Side

The pass:q[`UNNEST` clause] cannot be the first term within the `FROM` clause; it must be preceded by another FROM term.
The term immediately preceding the pass:q[`UNNEST` clause] represents the _left-hand side_ of the pass:q[`UNNEST` clause].

You can chain the pass:q[`UNNEST` clause] with any of the other permitted FROM terms, including another pass:q[`UNNEST` clause].
For more information, see the page on the [FROM](n1ql-language-reference/from.adoc) clause.

There are restrictions on what types of FROM terms may be chained and in what order -- see the descriptions on this page for more details.

The types of FROM term that may be used as the left-hand side of the pass:q[`UNNEST` clause] are summarized in the following table.

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

### Unnest Type

```ebnf
unnest-type ::= 'INNER' | ( 'LEFT' 'OUTER'? )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/unnest-type.png)

This clause represents the type of unnest.

* **`INNER`**\
For each result object produced, the array object in the left-hand side keyspace must be non-empty.
* **`LEFT [OUTER]`**\
{startsb}Query Service interprets `LEFT` as `LEFT OUTER`{endsb}

  A left-outer unnest is performed, and at least one result object is produced for each left source object.

This clause is optional.
If omitted, the default is `INNER`.

### Unnest Path

* **expr**\
The path to the nested array.

The path expression in each UNNEST clause must reference some preceding path.

### AS Alias

Assigns another name to the right-hand side of the unnest.
For details, see [AS Clause](n1ql-language-reference/from.adoc#section_ax5_2nx_1db).

Assigning an alias to the path is optional.
If you assign an alias to the path, the `AS` keyword may be omitted.

<dl><dt><strong>📌 NOTE</strong></dt><dd>

If you want to use an [ARRAY index](n1ql-language-reference/indexing-arrays.adoc) for the UNNEST query, you can use any arbitrary alias for the right side of the UNNEST -- the alias does not have to be the same as the ARRAY index variable name in order to use that index.
</dd></dl>

## Limitations

You may chain UNNEST clauses with comma-separated joins; however, the comma-separated joins must come after any JOIN, NEST, or UNNEST clauses.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="UNNEST-Example-1"></a>**UNNEST an array to select an item**

In the `route` keyspace, flatten the schedule array to get details of the flights on Monday (`1`).

```sqlpp
SELECT route.sourceairport, route.destinationairport, sched.flight, sched.utc
FROM route
UNNEST schedule sched
WHERE  sched.day = 1
LIMIT 3;
```

**Results**

```JSON
[
  {
    "destinationairport": "MRS",
    "flight": "AF356",
    "sourceairport": "TLV",
    "utc": "12:40:00"
  },
  {
    "destinationairport": "MRS",
    "flight": "AF480",
    "sourceairport": "TLV",
    "utc": "08:58:00"
  },
  {
    "destinationairport": "MRS",
    "flight": "AF250",
    "sourceairport": "TLV",
    "utc": "12:59:00"
  }
]
```

Another way to get similar results is by using a quantified expression to find array items that meet our criteria:

```sqlpp
SELECT route.sourceairport, route.destinationairport,
ARRAY item FOR item IN schedule WHEN item.day = 1 END AS Monday_flights
FROM route
WHERE ANY item IN schedule SATISFIES item.day = 1 END
LIMIT 3;
```

However, without the `UNNEST` clause, the unflattened list results in 3 sets of flights instead of only 3 individual flights:

```JSON
[
  {
    "Monday_flights": [
      {
        "day": 1,
        "flight": "AF356",
        "utc": "12:40:00"
      },
      {
        "day": 1,
        "flight": "AF480",
        "utc": "08:58:00"
      },
      {
        "day": 1,
        "flight": "AF250",
        "utc": "12:59:00"
      },
      {
        "day": 1,
        "flight": "AF130",
        "utc": "04:45:00"
      }
    ],
    "destinationairport": "MRS",
    "sourceairport": "TLV"
  },
  {
    "Monday_flights": [
      {
        "day": 1,
        "flight": "AF517",
        "utc": "13:36:00"
      },
      {
        "day": 1,
        "flight": "AF279",
        "utc": "21:35:00"
      },
      {
        "day": 1,
        "flight": "AF753",
        "utc": "00:54:00"
      },
      {
        "day": 1,
        "flight": "AF079",
        "utc": "15:29:00"
      },
      {
        "day": 1,
        "flight": "AF756",
        "utc": "06:16:00"
      }
    ],
    "destinationairport": "NCE",
    "sourceairport": "TLV"
  },
  {
    "Monday_flights": [
      {
        "day": 1,
        "flight": "AF975",
        "utc": "11:23:00"
      },
      {
        "day": 1,
        "flight": "AF225",
        "utc": "16:05:00"
      }
    ],
    "destinationairport": "CDG",
    "sourceairport": "TNR"
  }
]
```

<a name="UNNEST-Example-2"></a>**Use `UNNEST` to collect items from one array to use in another query**

In this example, the `UNNEST` clause iterates over the `reviews` array and collects the `author` names of the reviewers who rated the rooms less than a 2 to be contacted for ways to improve.
`r` is an element of the array generated by the UNNEST operation.

```sqlpp
SELECT RAW r.author
FROM hotel
UNNEST reviews AS r
WHERE r.ratings.Rooms < 2
LIMIT 4;
```

**Results**

```JSON
[
  "Kayli Cronin",
  "Shanelle Streich",
  "Catharine Funk",
  "Tyson Beatty"
]
```
