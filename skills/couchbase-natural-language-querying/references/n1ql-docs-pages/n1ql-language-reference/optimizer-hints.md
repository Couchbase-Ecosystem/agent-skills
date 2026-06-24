# Optimizer Hints

Optimizer hints enable you to supply directives to the optimizer.

You can use optimizer hints to request that the [optimizer](n1ql-language-reference/cost-based-optimizer.adoc) should consider specific indexes, join methods, join ordering, and so on, when creating the plan for a query.
This may be useful in situations where the optimizer is not able to come up with the preferred plan, due to lack of optimizer statistics, high level of skew in data, data correlations, and so on.

Generally speaking, you should rely on the optimizer to generate the query plan.

**Examples on this Page**

To use the examples on this page, you must set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

## Syntax

```ebnf
hint-comment ::= block-hint-comment | line-hint-comment
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/hint-comment.png)

```ebnf
block-hint-comment ::= '/*+' hints '*/'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/block-hint-comment.png)

```ebnf
line-hint-comment ::= '--+' hints
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/line-hint-comment.png)

You can supply hints to the operator within a specially-formatted _hint comment_.
The hint comment may be a block comment or a line comment.
There must be a plus sign `+` immediately after the start of the comment; this is the distinguishing delimiter of the hint comment.

Note that a line comment includes all text up to the end of the line.
Therefore, if the hint comment is a line comment, the next part of the query must start on the following line.

<a name="ex-block-hint"></a>**Block hint comment**

**Query**

```sqlpp
SELECT /*+ INDEX(airport def_inventory_airport_city) */ airportname
FROM airport
WHERE city = "San Francisco";
```

<a name="ex-line-hint"></a>**Line hint comment**

**Equivalent to [Block hint comment](#ex-block-hint)**

```sqlpp
SELECT --+ INDEX(airport def_inventory_airport_city)
       airportname
FROM airport
WHERE city = "San Francisco";
```

## Placement

In Couchbase Server 8.0 and later, a hint comment is supported in `SELECT`, `DELETE`, `UPDATE`, and `MERGE` statements only.
The hint comment must be located immediately after the statement keyword.

There can only be one hint comment in a query block.
If there is more than one hint comment, a syntax error is generated.
However, the hint comment may contain one or more hints.

<a name="ex-multi-hints"></a>**Multiple hint comments**

**Incorrect query**

```sqlpp
SELECT /*+ USE_HASH(r) */
       /*+ INDEX(a def_inventory_airport_city) */
       a.airportname, r.airline
FROM airport a
JOIN route r
ON a.faa = r.sourceairport
WHERE a.city = "San Francisco";
```

This query generates a syntax error, as it contains multiple hint comments.

## Format

```ebnf
hints ::= simple-hint-sequence | json-hint-object
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/hints.png)

```ebnf
simple-hint-sequence ::= simple-hint+
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/simple-hint-sequence.png)

```ebnf
json-hint-object ::= '{' json-hint (',' json-hint )* '}'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/json-hint-object.png)

Internally, the hint comment may take one of two equivalent formats:

* The _simple_ syntax is a plain text format, similar to the type of hint comment found in many relational databases.
* Alternatively, you may supply optimizer hints using _JSON_ syntax.
In this case, the hint comment contains a single top-level hint object.

You cannot mix the simple syntax and the JSON syntax within the same hint comment; each hint comment must use one syntax or the other exclusively.

To use multiple hints with the simple syntax, simply specify the hints one after another within the hint comment.
To use multiple hints with the JSON syntax, specify each hint as a property within the top-level hint object.

<a name="ex-simple-hint"></a>**Simple hint**

**Query**

```sqlpp
SELECT /*+ INDEX(airport def_inventory_airport_city) */
       airportname, faa
FROM airport
WHERE city = "San Francisco";
```

<a name="ex-json-hint"></a>**JSON hint**

**Equivalent to [Simple hint](#ex-simple-hint)**

```sqlpp
SELECT /*+ {"index": {"keyspace": "airport",
                      "indexes": "def_inventory_airport_city"}} */
       airportname, faa
FROM airport
WHERE city = "San Francisco";
```

<a name="ex-multi-simple"></a>**Multiple simple hints**

**Query**

```sqlpp
SELECT /*+ INDEX(a def_inventory_airport_city) USE_HASH(r) */
       a.airportname, r.airline
FROM airport a
JOIN route r
ON a.faa = r.sourceairport
WHERE a.city = "San Francisco";
```

<a name="ex-multi-json"></a>**Multiple JSON hints**

**Equivalent to [Multiple simple hints](#ex-multi-simple)**

```sqlpp
SELECT /*+ {"index": {"keyspace": "a",
                      "indexes": "def_inventory_airport_city"},
            "use_hash": {"keyspace": "r"}} */
       a.airportname, r.airline
FROM airport a
JOIN route r
ON a.faa = r.sourceairport
WHERE a.city = "San Francisco";
```

## Legacy Equivalents

Many optimizer hints have an equivalent legacy syntax using the `USE` clause.
Details of these are given on the pages for individual optimizer hints, and in the pages describing the `USE` clause.
For details, refer to [USE INDEX Clause](n1ql-language-reference/hints.adoc#use-index-clause)
and [ANSI JOIN Hints](n1ql-language-reference/join.adoc#ansi-join-hints).

Note that you cannot use a hint comment and the `USE` clause to specify optimizer hints on the same keyspace.
If you do this, the hint comment and the `USE` clause are marked as erroneous and ignored by the optimizer.

<a name="ex-legacy-hint"></a>**Legacy hint**

**Legacy equivalent to [Simple hint](#ex-simple-hint)**

```sqlpp
SELECT airportname, faa
FROM airport
USE INDEX (def_inventory_airport_city)
WHERE city = "San Francisco";
```

## Explain Plans

When optimizer hints are specified for a query, the explain plan reports the status of each hint: that is, whether the hint was followed or not followed by the optimizer in choosing the query plan.
Invalid hints are also reported.
Specific error messages are given for any hint that is not followed, or invalid.

<a name="ex-simple-hint-explain"></a>**Simple hint explain plan**

When the optimizer follows a simple hint, the hint is shown in the explain plan.

**Explain plan for [Simple hint](#ex-simple-hint)**

```sqlpp
EXPLAIN SELECT /*+ INDEX(airport def_inventory_airport_city) */
               airportname, faa
FROM airport
WHERE city = "San Francisco";
```

**Result**

```json
[
  {
    "optimizer_hints": {
      "hints_followed": [
        "INDEX(airport def_inventory_airport_city)"
      ]
    },
// ...
  }
]
```

<a name="ex-json-hint-explain"></a>**JSON hint explain plan**

When the optimizer follows a JSON hint, the hint is shown in the explain plan in JSON format.

**Explain plan for [JSON hint](#ex-json-hint)**

```sqlpp
EXPLAIN
SELECT /*+ {"index": {"keyspace": "airport",
                      "indexes": "def_inventory_airport_city"}} */
       airportname, faa
FROM airport
WHERE city = "San Francisco";
```

**Result**

```json
[
  {
    "optimizer_hints": {
      "hints_followed": [
        "hint": "{\"index\":{\"indexes\":[\"def_inventory_airport_city\"],\"keyspace\":\"airport\"}}"
      ]
    },
// ...
  }
]
```

<a name="ex-multi-simple-explain"></a>**Multiple hint explain plan**

When the optimizer follows multiple hints, all the followed hints are shown in the explain plan.

**Explain plan for [Multiple simple hints](#ex-multi-simple)**

```sqlpp
EXPLAIN SELECT /*+ USE_HASH(r) INDEX(a def_inventory_airport_city) */
               a.airportname, r.airline
FROM airport a
JOIN route r
ON a.faa = r.sourceairport
WHERE a.city = "San Francisco";
```

**Result**

```json
[
  {
    "optimizer_hints": {
      "hints_followed": [
        "USE_HASH(r)",
        "INDEX(a def_inventory_airport_city)"
      ]
    },
// ...
  }
]
```

<a name="ex-legacy-hint-explain"></a>**Legacy hint explain plan**

When the optimizer follows a hint specified using the legacy `USE` clause, the hint is likewise shown in the explain plan.

**Explain plan for [Legacy hint](#ex-legacy-hint)**

```sqlpp
EXPLAIN SELECT airportname, faa
FROM airport
USE INDEX (def_inventory_airport_city)
WHERE city = "San Francisco";
```

**Result**

```json
[
  {
    "optimizer_hints": {
      "hints_followed": [
        "INDEX(airport def_inventory_airport_city)"
      ]
    },
// ...
  }
]
```

<a name="ex-unused-hint-explain"></a>**Unused hint explain plan**

When the optimizer cannot follow a hint, any hints that cannot be followed are shown in the explain plan.

**Explain plan**

```sqlpp
EXPLAIN SELECT /*+ USE_HASH(r) INDEX(a def_inventory_airport_city) */
               a.airportname, r.airline
FROM airport a
JOIN route r
ON a.faa = r.sourceairport
WHERE a.city IS MISSING;
```

**Result**

```json
[
  {
    "optimizer_hints": {
      "hints_followed": [
        "USE_HASH(r)"
      ],
      "hints_not_followed": [
        "INDEX(a def_inventory_airport_city): INDEX hint cannot be followed"
      ]
    },
// ...
  }
]
```

<a name="ex-invalid-hint-explain"></a>**Invalid hint explain plan**

When you specify an invalid hint, any invalid hints are shown in the explain plan.

**Explain plan**

```sqlpp
EXPLAIN SELECT /*+ USE_HASH(r) INDEX_SS(a def_inventory_airport_city) */
               a.airportname, r.airline
FROM airport a
JOIN route r
ON a.faa = r.sourceairport
WHERE a.city = "San Francisco";
```

**Result**

```json
[
  {
    "optimizer_hints": {
      "hints_followed": [
        "USE_HASH(r)"
      ],
      "invalid_hints": [
        "INDEX_SS(a def_inventory_airport_city): Invalid hint name"
      ]
    },
// ...
  }
]
```

<a name="ex-update-hint-explain"></a>**Explain plan for UPDATE with a simple index hint**

When the optimizer follows a simple hint in an UPDATE query, the hint is shown in the explain plan.

**Explain plan**

```sqlpp
EXPLAIN
UPDATE /*+ INDEX(airport def_inventory_airport_city) */ airport
SET updated = true
WHERE city = "San Jose";
```

**Result**

```json
[
  {
    "optimizer_hints": {
      "hints_followed": [
        "INDEX(airport def_inventory_airport_city)"
      ]
    },
// ...
  }
]
```

<a name="ex-delete-hint-explain"></a>**Explain plan for DELETE with a simple index hint**

When the optimizer follows a simple hint in a DELETE query, the hint is shown in the explain plan.

**Explain plan**

```sqlpp
EXPLAIN
DELETE /*+ INDEX (hotel def_inventory_hotel_city) */
FROM `hotel`
WHERE city = "San Francisco";
```

**Result**

```json
[
  {
    "optimizer_hints": {
        "hints_followed": [
            "INDEX(`hotel` `def_inventory_hotel_city`)"
        ]
    },
// ...
  }
]
```

## Further Details

Refer to the following pages for details of individual optimizer hints:

* [n1ql-language-reference/query-hints.adoc](n1ql-language-reference/query-hints.adoc) apply to an entire query block.
* [n1ql-language-reference/keyspace-hints.adoc](n1ql-language-reference/keyspace-hints.adoc) apply to a specific keyspace.
* [n1ql:n1ql-language-reference/negative-keyspace-hints.adoc](n1ql:n1ql-language-reference/negative-keyspace-hints.adoc) apply to a specific keyspace, but instruct the optimizer not to use certain options.

## Related Links

* [Cost-Based Optimizer](n1ql-language-reference/cost-based-optimizer.adoc)
* [SELECT](n1ql-language-reference/selectclause.adoc)
* [DELETE](n1ql-language-reference/delete.adoc)
* [UPDATE](n1ql-language-reference/update.adoc)
* [MERGE](n1ql-language-reference/merge.adoc)
