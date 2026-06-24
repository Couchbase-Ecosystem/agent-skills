# USE Clause

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

The `USE` clause enables you to specify that the query should use particular keys, or a particular index.

## Purpose

The `USE` clause is used within the [FROM](n1ql-language-reference/from.adoc) clause.
It enables you to provide a hint to the query service, specifying that the query should use particular keys, or a particular index.

**💡 TIP**\
You can also supply an index hint within a specially-formatted [hint comment](n1ql-language-reference/optimizer-hints.adoc).
Note that you cannot specify an index hint for the same keyspace using both the `USE` clause and a hint comment.
If you do this, the `USE` clause and the hint comment are both marked as erroneous and ignored by the optimizer.

## Prerequisites

For you to select data from a document or keyspace, you must have the `query_select` privilege on the document or keyspace.
For more details about user roles, see
[Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
use-clause ::= use-keys-clause | use-index-clause
```

![Syntax diagram](../../assets/images/n1ql-language-reference/use-clause.png)

* **use-keys-clause**\
[USE KEYS Clause](#use-keys-clause) icon:caret-down[]
* **use-index-clause**\
[USE INDEX clause](#use-index-clause) icon:caret-down[]

## USE KEYS Clause

### Purpose

You can refer to a document’s unique document key by using the `USE KEYS` clause.
Only documents having those document keys will be included as inputs to a query.

There is no optimizer hint equivalent to this clause.

### Syntax

```ebnf
use-keys-clause ::= 'USE' use-keys-term
```

![Syntax diagram](../../assets/images/n1ql-language-reference/use-keys-clause.png)

```ebnf
use-keys-term ::= 'PRIMARY'? 'KEYS' expr
```

![Syntax diagram](../../assets/images/n1ql-language-reference/use-keys-term.png)

Synonym: `USE KEYS` and `USE PRIMARY KEYS` are synonyms.

* **expr**\
String of a document key or an array of comma-separated document keys.

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Select a single document by its document key**

```sqlpp
SELECT *
FROM airport
USE KEYS "airport_1254";
```

**Results**

```JSON
[
  {
    "travel-sample": {
      "airportname": "Calais Dunkerque",
      "city": "Calais",
      "country": "France",
      "faa": "CQF",
      "geo": {
        "alt": 12,
        "lat": 50.962097,
        "lon": 1.954764
      },
      "icao": "LFAC",
      "id": 1254,
      "type": "airport",
      "tz": "Europe/Paris"
    }
  }
]
```

**Select multiple documents by their document keys**

```sqlpp
SELECT *
FROM airport
USE KEYS ["airport_1254","airport_1255"];
```

**Results**

```JSON
[
  {
    "travel-sample": {
      "airportname": "Calais Dunkerque",
      "city": "Calais",
      "country": "France",
      "faa": "CQF",
      "geo": {
        "alt": 12,
        "lat": 50.962097,
        "lon": 1.954764
      },
      "icao": "LFAC",
      "id": 1254,
      "type": "airport",
      "tz": "Europe/Paris"
    }
  },
  {
    "travel-sample": {
      "airportname": "Peronne St Quentin",
      "city": "Peronne",
      "country": "France",
      "faa": null,
      "geo": {
        "alt": 295,
        "lat": 49.868547,
        "lon": 3.029578
      },
      "icao": "LFAG",
      "id": 1255,
      "type": "airport",
      "tz": "Europe/Paris"
    }
  }
]
```

## USE INDEX clause

### Purpose

Use the `USE INDEX` clause to specify the index or indexes to be used as part of the query execution.
The query engine attempts to use a specified index if the index is applicable for the query.

If necessary, you can omit the index name and just specify the index type.
In this case, the query service considers all the available indexes of the specified type.

This clause is equivalent to the `INDEX` and `INDEX_FTS` optimizer hints.
For more details, refer to [Keyspace Hints](n1ql-language-reference/keyspace-hints.adoc).

If you attempt to use an index which is still scheduled for background creation, the request fails.

### Syntax

```ebnf
use-index-clause ::= 'USE' use-index-term
```

![Syntax diagram](../../assets/images/n1ql-language-reference/use-index-clause.png)

```ebnf
use-index-term ::= 'INDEX' '(' index-ref ( ',' index-ref )* ')'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/use-index-term.png)

```ebnf
index-ref ::= index-name? index-type?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/index-ref.png)

* **index-name**\
[Optional] String or expression representing an index to be used for the query.

  <a name="use-index-args"></a>This argument is optional; if omitted, the query engine considers all available indexes of the specified index type.
* **index-type**\
[USING clause](#using-clause) icon:caret-down[]

#### USING clause

```ebnf
index-type ::= 'USING' ( 'GSI' | 'FTS' )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/index-type.png)

Specifies which index form to use.

* **`USING GSI`**\
A Global Secondary Index, which lives on an index node and can possibly be separate from a data node.
* **`USING FTS`**\
A Full Text Search index, for use with queries containing [Search functions](n1ql-language-reference/searchfun.adoc).
You can use this hint to specify that the query is a [Flex Index](n1ql:n1ql-language-reference/flex-indexes.adoc) query using a Full Text Search index.
In Couchbase Server Community Edition, this hint is ignored if the query does not contain a Search function.

This clause is optional; if omitted, the default is `USING GSI`.

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Use a specified Global Secondary Index**

This example uses the index `def_inventory_route_route_src_dst_day`, which is installed with the `travel-sample` bucket.

The following query hints that the optimizer should select the specified index for the keyspace `route`.

**INDEX hint**

```sqlpp
SELECT id FROM route
USE INDEX (def_inventory_route_route_src_dst_day USING GSI)
WHERE sourceairport = "SFO"
LIMIT 1;
```

**Use any suitable Full Text Search index**

Specify that the query service should prefer an FTS index, without specifying the index by name.
To qualify for this query, there must be an FTS index on state and type, using the keyword analyzer.
(Or alternatively, an FTS index on state, with a custom type mapping on "hotel".)

```sqlpp
SELECT META().id
FROM hotel USE INDEX (USING FTS)
WHERE state = "Corse" OR state = "California";
```

All FTS indexes are considered.
If a qualified FTS index is available, it is selected for the query.
If none of the available FTS indexes are qualified, the available GSI indexes are considered instead.

## Related Links

* [ANSI JOIN Hints](n1ql-language-reference/join.adoc#ansi-join-hints)
* [Optimizer Hints](n1ql-language-reference/optimizer-hints.adoc)
