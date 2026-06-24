# Array Indexing

Array Indexing adds the capability to create global indexes on array elements and optimizes the execution of queries involving array elements.

This is a huge leap from the previous versions where secondary indexes could only be created and subsequently queried on whole arrays.
You can now create an index of array elements ranging from plain scalar values to complex arrays or JSON objects nested deeper in the array.

## Syntax

To create an array index, the overall syntax is the same as for a global secondary index.
The distinguishing feature is the use of an array expression as an index key.

Refer to the [CREATE INDEX](n1ql-language-reference/createindex.adoc) statement for details of the syntax.

### Index Key

```ebnf
index-key ::= expr | array-expr
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/index-key.png)

To create an array index, one index key must be an array expression.
The index key containing the array expression is referred to as the _array index key_.
The index definition may also contain other index keys which are not array expressions.

* **expr**\
A {sqlpp} [expression](n1ql-language-reference/index.adoc) over any fields in the document.
This cannot use constant expressions, aggregate functions, or sub-queries.
* **array-expr**\
An array expression.
Refer to [Array Expression](#array-expression) below.

<dl><dt><strong>❗ IMPORTANT: Array Index Key</strong></dt><dd>

Currently, the index definition for an array index may only contain one array index key.
However, the array index key may index more than one field or expression within the array, as described below.

For an UNNEST scan to use an array index, the array index key containing the appropriate array expression must be the _leading key_ of the index definition.
The UNNEST scan can generate index spans on other non-leading index keys when appropriate predicates exist.

In order for the optimizer to select the correct array index for a SELECT, UPDATE, or DELETE statement, the query predicate which appears in the WHERE clause must be constructed to match the format of the array index key.
See [Format of Query Predicate](#format-of-query-predicate) for details.

You can add the `INCLUDE MISSING` modifier to a leading array index key, just as you can with any other leading index key, in order to index documents in which the specified array is missing.
</dd></dl>

### Array Expression

```ebnf
array-expr ::= full-array-expr | simple-array-expr
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/array-expr.png)

The array expression can be either a [full array expression](#full-array-expression), which uses the `ARRAY` operator to index specified fields and elements within the array; or a [simple array expression](#simple-array-expression), which indexes all fields and elements in the array.

#### Full Array Expression

```ebnf
full-array-expr ::= ( 'ALL' | 'DISTINCT' ) 'ARRAY' var-expr
                    'FOR' var ( 'IN' | 'WITHIN' ) expr
                    ( ',' var ( 'IN' | 'WITHIN' ) expr )* ( 'WHEN' cond )? 'END'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/full-array-expr.png)

The `ARRAY` operator lets you map and filter the elements or attributes of a collection, object, or objects.
It evaluates to an array of the operand expression that satisfies the WHEN clause, if specified.

* **var-expr**\
A function of the `var` variable used in the FOR clause.
* **var**\
Represents elements in the array specified by `expr`.
* **expr**\
Evaluates to an array of objects, elements of which are represented by the `var` variable.
* **cond**\
Specifies predicates to qualify the subset of documents to include in the index array.

<dl><dt><strong>📌 NOTE: Variable Expression</strong></dt><dd>

You can index one or more expressions _within_ the array (up to maximum of 32) by using the [FLATTEN_KEYS()](n1ql-language-reference/metafun.adoc#flatten_keys) function in the `var-expr`.
This function flattens expressions within the array, as if they were separate index keys; and all subsequent index keys are accordingly moved to the right.
Queries will be [sargable](n1ql-language-reference/selectintro.adoc#index-selection) and will generate spans.
Refer to [Format of Query Predicate](#format-of-query-predicate) below.

The `var-expr` itself may be a nested [array expression](#array-expression).
This enables creating array indexes on nested array fields.
Refer to [Nested array index](#example-5) below.

To create an array index involving multiple array elements or multiple arrays, you may construct the `var-expr` as a compound object constituted with different elements of the same array or multiple arrays.
Refer to [Array index on compound object](#example-6) below.

You can add the `INCLUDE MISSING` modifier to the first argument in the [FLATTEN_KEYS()](n1ql-language-reference/metafun.adoc#flatten_keys) function, in order to index array elements in which the specified field is missing.
</dd></dl>

#### Simple Array Expression

```ebnf
simple-array-expr ::= ( 'ALL' | 'DISTINCT' ) expr
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/simple-array-expr.png)

Couchbase Server 5.0 and later provides a simpler syntax for array indexing when all array elements are indexed as is, without needing to use the `ARRAY` operator in the index definition.

* **expr**\
An array field name, or an expression that can evaluate to an array.
In this case, all fields and elements of the array are indexed.

## Format of Query Predicate

In order for the optimizer to select the correct array index for a SELECT, UPDATE, or DELETE statement, the query predicate which appears in the WHERE clause must be constructed to match the format of the array index key.

Consider the following expressions used in a CREATE INDEX statement:

|     |     |
| --- | --- |
```n1ql
DISTINCT ARRAY f(x) FOR x IN expr1 END;
```
| .C1 | .C2 |
```n1ql
DISTINCT ARRAY f(x) FOR x WITHIN expr1 END;
```

And the following expressions used in the SELECT statement WHERE clause:

|     |     |
| --- | --- |
```n1ql
ANY x IN expr2 SATISFIES g(x) END;
```
| .Q1 | .Q2 |
```n1ql
ANY x WITHIN expr2 SATISFIES g(x) END;
```

The following dependencies must be satisfied for the Query service to consider the array index:

* The index keys used in CREATE INDEX must be used in the WHERE clause.
(The query can use different variable names from those used in the array index definition.)
* The `expr2` in [q1](#q1) and [q2](#q2) must be equivalent to the `expr1` in [c1](#c1) and [c2](#c2).
This is a formal notion of equivalence.
For example, they must be the same expressions, or equivalent arithmetic expressions such as `(x+y)` and `(y+x)`.
* Usually, `g(x)` in [q1](#q1) and [q2](#q2) must be sargable for `f(x)` in [c1](#c1) and [c2](#c2).
In other words, if there were a scalar index with key `f(x)`, then that index would be applicable to the predicate `g(x)`.
For example, the predicate `UPPER(x) LIKE "John%"` is sargable for the index key `UPPER(x)`.

##### Flatten Keys

Now consider the following variants of [c1](#c1) and [c2](#c2), in which the index key `f(x)` uses the [FLATTEN_KEYS()](n1ql-language-reference/metafun.adoc#flatten_keys) function to flatten expressions within the array:

|     |     |
| --- | --- |
```n1ql
DISTINCT ARRAY
  FLATTEN_KEYS(f1(x) ASC, f2(x) DESC)
  FOR x IN expr1 END;
```
| .C3 | .C4 |
```n1ql
DISTINCT ARRAY
  FLATTEN_KEYS(f1(x) ASC, f2(x) DESC)
  FOR x WITHIN expr1 END;
```

* The index keys [c3](#c3) and [c4](#c4) flatten expressions within the array, as if they were separate index keys; and all subsequent index keys are accordingly moved to the right.
Queries will be sargable and will generate spans.
* In order to select an array index defined using [c3](#c3) or [c4](#c4), the predicate `g(x)` in [q1](#q1) and [q2](#q2) must be sargable for one of the _arguments_ of the [FLATTEN_KEYS()](n1ql-language-reference/metafun.adoc#flatten_keys) function -- `f1(x)` or `f2(x)`.

##### IN vs. WITHIN

* Index key [c1](#c1) can be used for query predicate [q1](#q1).
Index key [c2](#c2) can be used for both query predicates [q1](#q1) and [q2](#q2).
* Index key [c2](#c2) is strictly more expensive than index key [c1](#c1), for both index maintenance and query processing.
Index key [c2](#c2) and query predicate [q2](#q2) are very powerful.
They can efficiently index and query recursive trees of arbitrary depth.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="example-1"></a>**Array index of distinct elements**

<a name="C1"></a>**Index: Create an index on all schedules**

```sqlpp
CREATE INDEX idx_sched
ON route
( DISTINCT ARRAY v.flight FOR v IN schedule END );
```

<a name="Q1"></a>**Query: Find the list of scheduled 'UA' flights**

```sqlpp
SELECT * FROM route
WHERE ANY v IN schedule SATISFIES v.flight LIKE 'UA%' END;
```

<a name="example-2"></a>**Partial array index**

Create a partial index (with WHERE clause) of individual attributes from selected elements (using WHEN clause) of an array.

<a name="C2"></a>**Index: Create an index on flights from San Francisco scheduled in the first 4 days of the week**

```sqlpp
CREATE INDEX idx_flight_sfo
ON route
( ALL ARRAY v.flight FOR v IN schedule WHEN v.day < 4 END )
WHERE sourceairport = "SFO";
```

<a name="Q2"></a>**Query: Find the list of scheduled 'UA' flights on day 1**

```sqlpp
SELECT * FROM route
WHERE sourceairport = "SFO" -- ①
AND ANY v IN schedule SATISFIES (v.flight LIKE 'UA%') -- ②
AND (v.day=1) END; -- ③
```

In this example, the [Index](#C2) qualifies for the [Query](#Q2) because:

1. The [Query](#Q2) predicate `sourceairport = "SFO"` matches that of the partial index WHERE clause.
2. The ANY operator uses the index key `v.flight` on which [Index](#C2) is defined.
3. The ANY-SATISFIES condition `v.day=1` in the [Query](#Q2) is sargable to the WHEN clause condition `v.day < 4` in the index definition.

<a name="example-3"></a>**Flattened array index**

<a name="C3"></a>**Index: Create an index on day and flight from schedule array**

```sqlpp
CREATE INDEX ixf_sched
  ON route
  (ALL ARRAY FLATTEN_KEYS(s.day DESC, s.flight) FOR s IN schedule END,
  sourceairport, destinationairport, stops);
```

<a name="Q3A"></a>**Query A: Find the weekday Delta flights FROM SFO to ATL**

```sqlpp
SELECT META(r).id
  FROM route AS r
  WHERE r.sourceairport = "SFO" -- ①
    AND r.destinationairport = "ATL" -- ②
    AND ANY s IN r.schedule SATISFIES s.day BETWEEN 1 AND 5 -- ③
    AND s.flight LIKE "DL%" END; -- ④
```

In this example, [Query A](#Q3A) is able to use the `ixf_sched` index defined by the [Index](#C3), pass all the predicate information to index scan, and cover the query.

**Partial Explain Plan**

```JSON
"spans": [
             {
                 "exact": true,
                 "range": [
                     {
                         "high": "5",
                         "inclusion": 3,
                         "index_key": "(`s`.`day`)", // ③
                         "low": "1"
                     },
                     {
                         "high": "\"DM\"",
                         "inclusion": 1,
                         "index_key": "(`s`.`flight`)", // ④
                         "low": "\"DL\""
                     },
                     {
                         "high": "\"SFO\"",
                         "inclusion": 3,
                         "index_key": "`sourceairport`", // ①
                         "low": "\"SFO\""
                     },
                     {
                         "high": "\"ATL\"",
                         "inclusion": 3,
                         "index_key": "`destinationairport`", // ②
                         "low": "\"ATL\""
                     }

                 ]
             }
         ]
```

1. `r.sourceairport = "SFO"` is able to match and pass to IndexScan.
2. `r.destinationairport = "ATL"` is able to match and pass to IndexScan.
3. ARRAY predicate `s.day BETWEEN 1 AND 5` is able to match and pass to IndexScan.
4. ARRAY predicate `s.flight LIKE "DL%"` is able to match and pass to IndexScan.

<a name="Q3B"></a>**Query B: Find the weekday Delta flights from SFO to ATL**

```sqlpp
SELECT  s.day, s.flight,r.sourceairport, r.destinationairport, r.stops
FROM route AS r
UNNEST r.schedule AS s
WHERE r.sourceairport = "SFO" AND r.destinationairport = "ATL"
      AND s.day BETWEEN 1 AND 5 AND s.flight LIKE "DL%"
ORDER BY s.day DESC
OFFSET 2
LIMIT 3;
```

This query performs a covering UNNEST IndexScan, by applying all the predicates, using the `ixf_sched` index defined by the [Index](#C3).
Even though the ORDER BY key uses an array index key, it can use index order, and pass LIMIT and OFFSET to the indexer.

<a name="example-missing"></a>**Array index with missing leading key**

The following statement creates an index of flight numbers from the `schedule` array for all routes.
If the schedule array is missing from any route, that route is indexed anyway.

Compare this statement with the [Index](#C1) in [Array index of distinct elements](#example-1).

**Index I: Create an array index, including missing leading key**

```sqlpp
CREATE INDEX idx_sched_missing
ON route
(DISTINCT ARRAY v.flight FOR v IN schedule END INCLUDE MISSING);
```

The following statement creates a flattened index on the time (`utc`) and day from the `schedule` array for all routes.
If the `utc` element is missing from any schedule, that schedule is indexed anyway.

**Index II: Create a flattened array index, including missing leading key**

```sqlpp
CREATE INDEX ixf_sched_missing
ON route
(DISTINCT ARRAY FLATTEN_KEYS(v.utc INCLUDE MISSING, v.day) FOR v IN schedule END);
```

<a name="example-4"></a>**Composite array index**

<a name="C4"></a>**Index: Create an index on individual elements of an array and other non-array fields**

```sqlpp
CREATE INDEX idx_flight_stops
ON route
    ( stops, DISTINCT ARRAY v.flight FOR v IN schedule END );
```

<a name="Q4"></a>**Query: Find the list of scheduled 'FL' flights that have one or more stops**

```sqlpp
SELECT * FROM route
WHERE stops >=1
AND ANY v IN schedule SATISFIES v.flight LIKE 'FL%' END;
```

<a name="example-5"></a>**Nested array index**

**⚠️ WARNING**\
Please note that the example below will alter the data in your sample buckets.
To restore your sample data, remove and reinstall the `travel-sample` bucket.
Refer to [Sample Buckets](manage:manage-settings/install-sample-buckets.adoc) for details.

**Update: Create a nested array**

```sqlpp
UPDATE route
SET schedule[0] = {"day" : 7, "special_flights" :
               [ {"flight" : "AI444", "utc" : "4:44:44"},
                 {"flight" : "AI333", "utc" : "3:33:33"}
               ] }
WHERE destinationairport = "CDG" AND sourceairport = "TLV";
```

Use the DISTINCT ARRAY clause in a nested fashion to index specific attributes of a document when the array contains other arrays or documents that contain arrays.

<a name="C5i"></a>**Index I: Create a partial index on a nested array**

```sqlpp
CREATE INDEX idx_nested ON route
    (DISTINCT ARRAY
        (DISTINCT ARRAY y.flight -- ①
        FOR y IN x.special_flights END)
    FOR x IN schedule END);
```

1. In this case, the inner ARRAY construct is used as the `var_expr` for the outer ARRAY construct in the {sqlpp} Syntax above.

<a name="Q5A"></a>**Query A: Use nested ANY operator to use the index**

```sqlpp
SELECT count(*) FROM route
WHERE ANY x in schedule SATISFIES
    (ANY y in x.special_flights SATISFIES y.flight IS NOT NULL END)
END;
```

This query uses the index `idx_nested` defined by [Index I](#C5i).
It returns 3 results, as there are 3 routes with special flights.

<a name="Q5B"></a>**Query B: Use UNNEST operators to use the index**

```sqlpp
SELECT count(*) FROM route
UNNEST schedule AS x
UNNEST x.special_flights AS y
WHERE y.flight IS NOT NULL;
```

This query uses the index `idx_nested` defined by [Index I](#C5i).
It returns 6 results, as there are 3 routes with 2 special flights each.

<a name="C5ii"></a>**Index II: Create a flattened index on a nested array**

```sqlpp
CREATE INDEX ixf_sched_nested ON route
    (ALL ARRAY
        (ALL ARRAY FLATTEN_KEYS(s.day, sf.flight)
         FOR sf IN s.special_flights END)
    FOR s IN schedule END);
```

<a name="Q5C"></a>**Query C: Use nested ANY operator to use the index**

```sqlpp
SELECT RAW count(1)
FROM route AS r
WHERE ANY s IN schedule
      SATISFIES (ANY sf IN s.special_flights
                 SATISFIES sf.flight IS NOT NULL AND s.day = 7
                 END)
      END;
```

This query performs a covering UNNEST IndexScan, by applying the predicates on both levels of the ARRAY, using the index `ixf_sched_nested` defined by [Index II](#C5ii).

<a name="Q5D"></a>**Query D: Use UNNEST operators to use the index**

```sqlpp
SELECT RAW count(1)
FROM route AS r
UNNEST r.schedule AS s
UNNEST s.special_flights AS sf
WHERE sf.flight IS NOT NULL AND s.day = 7;
```

This query performs a covering UNNEST IndexScan, by applying the predicates on both levels of the ARRAY, using the index `ixf_sched_nested` defined by [Index II](#C5ii); and uses index aggregation.

<a name="example-6"></a>**Array index on compound object**

<a name="C6"></a>**Index: Create an index on multiple elements of an array**

```sqlpp
CREATE INDEX idx_flight_day ON route
    (DISTINCT ARRAY [v.flight, v.day] FOR v IN schedule END);
```

<a name="Q6"></a>**Query: Find the list of scheduled 'US681' flights on day 2**

```sqlpp
SELECT meta().id FROM route
WHERE ANY v in schedule SATISFIES [v.flight, v.day] = ["US681", 2] END;
```

<a name="example-7"></a>**Simplified array index**

<a name="C7"></a>**Index: Create an index on all schedules using simplified array index syntax**

```sqlpp
CREATE INDEX idx_sched_simple
ON route (ALL schedule);
```

The following queries find details of all route documents matching a specific schedule.

<a name="Q7A"></a>**Query A: Use ANY operator to use the index**

```sqlpp
SELECT * FROM route
WHERE ANY v IN schedule
SATISFIES v = {"day":2, "flight": "US681", "utc": "19:20:00"} END; -- ①
```

1. Elements of the schedule array are objects, and hence the right side value of the predicate condition should be a similarly structured object.

<a name="Q7B"></a>**Query B: Use UNNEST operator to use the index**

```sqlpp
SELECT * FROM route t
UNNEST schedule sch
WHERE sch = {"day":2, "flight": "US681", "utc": "19:20:00"};
```

This is a variant of [Query A](#Q7A) using UNNEST in the SELECT statement.

<a name="Q7C"></a>**Query C: Alternative using a flattened array index**

```sqlpp
SELECT META(r).id
FROM route AS r
WHERE ANY v IN r.schedule SATISFIES v.day = 2 AND v.flight = "US681" END;
```

For comparison, this query performs a covering index scan, by applying all the predicates, using `ixf_sched` defined by the [Index](#C3) in [Flattened array index](#example-3).
The query syntax is more intuitive than [Query A](#Q7A) and [Query B](#Q7B), since the multiple fields within the array have not required complex indexing.

## Covering Array Index

Covering indexes are an efficient method of using an Index for a particular query, whereby the index itself can completely cover the query in terms of providing all data required for the query.
Basically, it avoids the fetch phase of the query processing and related overhead in fetching the required documents from data-service nodes.
For more details, see [Covering Indexes](indexes:covering-indexes.adoc).

Array indexing requires special attention to create covering array indexes.
In general, the array field itself should be included as one of the index keys in the CREATE INDEX definition.
For instance, in [Array index of distinct elements](#example-1), the [Index](#C1) does not cover the [Query](#Q1) because the [Query](#Q1) projection list includes * which needs to fetch the document from the Data Service.

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="example-8"></a>**Covering Array Index**

<a name="C8i"></a>**Index I: Creating a Covering Array Index**

```sqlpp
CREATE INDEX idx_sched_cover ON route
    (DISTINCT ARRAY v.flight FOR v IN schedule END, schedule);
```

The index keys of an index must be used in the WHERE clause of a DML statement to use the index for that query.
In the SELECT or DML WHERE clause, Covering Array Indexes can be used by the following operators:

* ANY: As shown in [Query A](#Q8A) below.
* ANY AND EVERY: As shown in [Query B](#Q8B) (a variant of [Query A](#Q8A)) below.

<a name="Q8A"></a>**Query A: Covering Array Index using the ANY clause**

```sqlpp
EXPLAIN SELECT meta().id FROM route
USE INDEX (idx_sched_cover) -- ①
WHERE ANY v IN schedule SATISFIES v.flight LIKE 'UA%' END;
```

1. In this example, [Query A](#Q8A) needs [Index I](#C8i) to cover it because the query predicate refers to the array `schedule` in the ANY operator.

**Result**

```JSON
[
  {
    "plan": {
      "#operator": "Sequence",
      "~children": [
        {
          "#operator": "DistinctScan",
          "scan": {
            "#operator": "IndexScan3",
            "bucket": "travel-sample",
            "covers": [
              "cover ((distinct (array (`v`.`flight`) for `v` in (`route`.`schedule`) end)))",
              "cover ((`route`.`schedule`))",
              "cover ((meta(`route`).`id`))"
            ],
            "filter": "cover (any `v` in (`route`.`schedule`) satisfies ((`v`.`flight`) like \"UA%\") end)",
            "filter_covers": {
              "cover (any `v` in (`route`.`schedule`) satisfies ((\"UA\" <= (`v`.`flight`)) and ((`v`.`flight`) < \"UB\")) end)": true,
              "cover (any `v` in (`route`.`schedule`) satisfies ((`v`.`flight`) like \"UA%\") end)": true
            },
            "index": "idx_sched_cover",
          // ...
          }
        }
      ]
    }
  }
]
```

<a name="Q8B"></a>**Query B: Covering Array Index using the ANY AND EVERY clause**

```sqlpp
EXPLAIN SELECT meta().id FROM route
USE INDEX (idx_sched_cover)
WHERE ANY AND EVERY v IN schedule SATISFIES v.flight LIKE 'UA%' END;
```

**Result**

```JSON
[
  {
    "plan": {
      "#operator": "Sequence",
      "~children": [
        {
          "#operator": "DistinctScan",
          "scan": {
            "#operator": "IndexScan3",
            "bucket": "travel-sample",
            "covers": [
              "cover ((distinct (array (`v`.`flight`) for `v` in (`route`.`schedule`) end)))",
              "cover ((`route`.`schedule`))",
              "cover ((meta(`route`).`id`))"
            ],
            "filter": "any and every `v` in cover ((`route`.`schedule`)) satisfies ((`v`.`flight`) like \"UA%\") end",
            "index": "idx_sched_cover",
          // ...
          }
        }
      ]
    }
  }
]
```

<a name="Q8C"></a>**Query C: Covering Array Index using the UNNEST clause and aliasing**

```sqlpp
EXPLAIN SELECT meta(t).id FROM route t
USE INDEX (idx_sched_cover)
UNNEST schedule v
WHERE v.flight LIKE 'UA%';
```

**Result**

```JSON
[
  {
    "plan": {
      "#operator": "Sequence",
      "~children": [
        {
          "#operator": "DistinctScan",
          "scan": {
            "#operator": "IndexScan3",
            "as": "t",
            "bucket": "travel-sample",
            "covers": [
              "cover ((distinct (array (`v`.`flight`) for `v` in (`t`.`schedule`) end)))",
              "cover ((`t`.`schedule`))",
              "cover ((meta(`t`).`id`))"
            ],
            "filter": "is_array(cover ((`t`.`schedule`)))",
            "index": "idx_sched_cover",
          // ...
          }
        }
      ]
    }
  }
]
```

In this example, [Query A](#Q8A) has the following limitation: the collection operator EVERY cannot use array indexes or covering array indexes because the EVERY operator needs to apply the SATISFIES predicate to all elements in the array, including the case where an array has zero elements.

As items cannot be indexed, it is not possible to index MISSING items, so the EVERY operator is evaluated in the {sqlpp} engine and cannot leverage the array index scan.

For example, [Query D](#Q8D) below uses the primary index `def_inventory_route_primary` ignoring the [USE INDEX](n1ql-language-reference/hints.adoc#use-index-clause) hint to use the array indexes.
(Note that in this example, [Index I](#C8i) defines a DISTINCT array index while [Index II](#C8ii) defines an ALL array index, and both are ignored).

<a name="C8ii"></a>**Index II: Non-array index with an ALL array index**

```sqlpp
CREATE INDEX idx_sched_cover_all ON route
    (ALL ARRAY v.flight FOR v IN schedule END, schedule);
```

<a name="Q8D"></a>**Query D: Non-array index with an ALL array index**

```sqlpp
EXPLAIN SELECT meta().id FROM route
USE INDEX (idx_sched_cover_all, idx_sched_cover)
WHERE EVERY v IN schedule SATISFIES v.flight LIKE 'UA%' END;
```

**Result**

```JSON
[
  {
    "plan": {
      "#operator": "Sequence",
      "~children": [
        {
          "#operator": "PrimaryScan3",
          "bucket": "travel-sample",
          "index": "def_inventory_route_primary",
        // ...
        }
      ]
    }
  }
]
```

## Implicit Covering Array Index

{sqlpp} supports simplified Implicit Covering Array Index syntax in certain cases where the mandatory array index-key requirement is relaxed to create a covering array-index.
This special optimization applies to those queries and DML which have WHERE clause predicates that can be exactly and completely pushed to the indexer during the array index scan.

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="example-9"></a>**ANY operator with an =, <, >, and LIKE predicate in the SATISFIES clause**

Note that the GSI indexes are tree structures that support exact match and range matches.
And the ANY predicate returns `true` as long as it finds at least one matching item in the index.
Hence, an item found in the index can cover the query.
Furthermore, this is covered by both ALL and DISTINCT array indexes.

<a name="C9"></a>**Index: Creating an Implicit Covering Array Index with DISTINCT**

```sqlpp
CREATE INDEX idx_sched_cover_simple ON route
    (DISTINCT ARRAY v.flight FOR v IN schedule END);
```

<a name="Q9"></a>**Query: Implicit Covering Array Index using the ANY clause**

```sqlpp
EXPLAIN SELECT meta().id FROM route
USE INDEX (idx_sched_cover_simple)
WHERE ANY v IN schedule SATISFIES v.flight LIKE 'UA%' END;
```

**Result**

```JSON
[
  {
    "plan": {
      "#operator": "Sequence",
      "~children": [
        {
          "#operator": "DistinctScan",
          "scan": {
            "#operator": "IndexScan3",
            "bucket": "travel-sample",
            "covers": [
              "cover ((distinct (array (`v`.`flight`) for `v` in (`route`.`schedule`) end)))",
              "cover ((meta(`route`).`id`))"
            ],
            "filter": "cover (any `v` in (`route`.`schedule`) satisfies ((`v`.`flight`) like \"UA%\") end)",
            "filter_covers": {
              "cover (any `v` in (`route`.`schedule`) satisfies ((\"UA\" <= (`v`.`flight`)) and ((`v`.`flight`) < \"UB\")) end)": true,
              "cover (any `v` in (`route`.`schedule`) satisfies ((`v`.`flight`) like \"UA%\") end)": true
            },
            "index": "idx_sched_cover_simple",
          // ...
          }
        }
      ]
    }
  }
]
```

<a name="example-10"></a>**UNNEST operator with =, <, >, or LIKE predicate in the WHERE clause**

This applies to only ALL array indexes because, for such index, all array elements are indexed in the array index, and the UNNEST operation needs all the elements to reconstruct the array.
Note that the array cannot be reconstructed if on DISTINCT elements of the array are indexed.

In this example, [Query A](#Q10A) can be covered with the ALL index `idx_sched_cover_simple_all` defined by the [Index](#C10), but [Query B](#Q10B) is not covered when using the DISTINCT index `idx_sched_cover_simple` defined by the [Index](#C9) in [ANY operator with an =, <, >, and LIKE predicate in the SATISFIES clause](#example-9).

<a name="C10"></a>**Index: UNNEST covered with the ALL index**

```sqlpp
CREATE INDEX idx_sched_cover_simple_all ON route
    (ALL ARRAY v.flight FOR v IN schedule END);
```

<a name="Q10A"></a>**Query A: UNNEST covered with the ALL index**

```sqlpp
EXPLAIN SELECT meta(t).id FROM route t
USE INDEX (idx_sched_cover_simple_all)
UNNEST schedule v
WHERE v.flight LIKE 'UA%';
```

**Result**

```JSON
[
  {
    "plan": {
      "#operator": "Sequence",
      "~children": [
        {
          "#operator": "IndexScan3",
          "as": "t",
          "bucket": "travel-sample",
          "covers": [
            "cover ((`v`.`flight`))",
            "cover ((meta(`t`).`id`))"
          ],
          "filter": "cover (is_array((`t`.`schedule`)))",
          "filter_covers": {
            "cover (((`t`.`schedule`) < {}))": true,
            "cover (([] <= (`t`.`schedule`)))": true,
            "cover (is_array((`t`.`schedule`)))": true
          },
          "index": "idx_sched_cover_simple_all",
          "index_id": "de0704c3fdb45b07",
          "keyspace": "route",
          "namespace": "default",
          "scope": "inventory",
          "spans": [
            {
              "exact": true,
              "range": [
                {
                  "high": "\"UB\"",
                  "inclusion": 1,
                  "low": "\"UA\""
                }
              ]
            }
          ],
          "using": "gsi"
        },
      // ...
      ]
    }
  }
]
```

<a name="Q10B"></a>**Query B: UNNEST not covered when using the DISTINCT index**

```sqlpp
EXPLAIN SELECT meta(t).id FROM route t
USE INDEX (idx_sched_cover_simple)
UNNEST schedule v
WHERE v.flight LIKE 'UA%';
```

**Result**

```JSON
[
  {
    "plan": {
      "#operator": "Sequence",
      "~children": [
        {
          "#operator": "DistinctScan",
          "scan": {
            "#operator": "IndexScan3",
            "as": "t",
            "bucket": "travel-sample",
            "index": "idx_sched_cover_simple",
            "index_id": "198a2bc8b0a3ea55",
            "index_projection": {
              "primary_key": true
            },
            "keyspace": "route",
            "namespace": "default",
            "scope": "inventory",
            "spans": [
              {
                "exact": true,
                "range": [
                  {
                    "high": "\"UB\"",
                    "inclusion": 1,
                    "low": "\"UA\""
                  }
                ]
              }
            ],
            "using": "gsi"
          }
        // ...
        }
      ]
    }
  }
]
```

## Summary

The following table summarizes {sqlpp}-supported collection operators in the DML WHERE clause for different kinds of array index features:

**{sqlpp}-supported collection operators**

| Operator in the SELECT/DML WHERE clause | Array Index | Covering Array Index (with explicit array index-key) | Implicit Covering Array Index (without explicit array index-key) |
| :-: | :-: | :-: | :-: |
| **ANY** | ✓ (both ALL & DISTINCT) | ✓ (both ALL & DISTINCT) | ✓ (both ALL & DISTINCT) |
| **UNNEST** | ✓ (only ALL, with array as leading index-key) | ✓ (only ALL, with array as leading index-key) | ✓ (only ALL, with array as leading index-key) |
| **ANY AND EVERY** | ✓ (both ALL & DISTINCT) | ✓ (both ALL & DISTINCT) | ✘ |
| **EVERY** | ✘ | ✘ | ✘ |

<dl><dt><strong>📌 NOTE</strong></dt><dd>

In Couchbase Server 6.5 and later, you can use any arbitrary alias for the right side of an UNNEST -- the alias does not have to be the same as the ARRAY index variable name in order to use that index.
</dd></dl>
