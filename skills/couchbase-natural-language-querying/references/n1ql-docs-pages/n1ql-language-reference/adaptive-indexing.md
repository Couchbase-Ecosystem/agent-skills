# Adaptive Index

Adaptive Indexes are a special type of GSI array index that can index all or specified fields of a document.
Such an index is generic in nature, and it can efficiently index and lookup any of the index-key values.
This enables efficient ad hoc queries (that may have WHERE clause predicates on any of the index-key fields) without requiring to create various composite indexes for different combinations of fields.
Adaptive Index is a functional array index created using the {sqlpp} function [PAIRS()](n1ql-language-reference/metafun.adoc#pairs).

Basically, the idea is to be able to simply load data and start querying:

* using a single secondary index, and
* not worrying about creating appropriate secondary indexes for each query.

Note that without Adaptive Indexes:

* Only primary index can help run any ad hoc query.
But using primary index can be expensive for queries with predicates on any of the non-key fields of the document.
* Each query will need a compatible secondary index that can qualify for the predicates in the WHERE clause.
See section [Contrast with Composite Indexes](#contrast-with-composite-indexes) for details.

For instance, consider a user profile or hotel reservation search use case.
A person’s profile may need to be searched based on any of the personal attributes such as first name, last name, age, city, address, job, title, company, etc.
Similarly, a hotel room availability may be searched based on wide criteria, such as room facilities, amenities, price, and other features.
In this scenario, traditional secondary indexes or composite indexes can’t be used effectively -- see section [Contrast with Composite Indexes](#contrast-with-composite-indexes) to understand some of the concerns.
Adaptive indexes can help effectively and efficiently run such ad hoc search queries.

## Syntax

An adaptive index is a type of array index.
To create an adaptive index, the overall syntax is the same as for an array index.

Refer to the [CREATE INDEX](n1ql-language-reference/createindex.adoc) statement for details of the syntax.

### Index Key

```ebnf
simple-array-expr ::= ( 'ALL' | 'DISTINCT' ) expr
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/simple-array-expr.png)

To create an adaptive index, the index key must be a simple array expression containing a [PAIRS()](n1ql-language-reference/metafun.adoc#pairs) function.

### PAIRS() Function

```ebnf
pairs-function ::= 'PAIRS' '(' ( 'SELF' | index-key-object ) ')'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/pairs-function.png)

When the `SELF` keyword is used, the adaptive index is created with all fields in the documents of the keyspace.

If you want to create an adaptive index on selected fields only, you must specify an index key object.

### Index Key Object

```ebnf
object ::= '{' ( ( name-expr ':' )? expr (',' ( name-expr ':' )? expr)* )? '}'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/object.png)

For the purposes of an adaptive index, the index key object should be an [object constructor](n1ql-language-reference/constructionops.adoc#object-construction) that generates an object of name-value pairs from the document fields to be indexed.

* **_name-expr_**\
The field name that corresponds to `_expr_`.
* **_expr_**\
A {sqlpp} expression that is allowed in [CREATE INDEX](n1ql-language-reference/createindex.adoc).
This must be an expression over any document fields.

When the value expression is an identifier directly referring to a named document field, then you may omit the name expression.
In this case, the name of the field in the data source will be used as the name of the field in the object constructor.

<dl><dt><strong>📌 NOTE</strong></dt><dd>

When using [PAIRS()](n1ql-language-reference/metafun.adoc#pairs) with an object constructor, you need to keep in mind:

* If two fields have the same name, such as `{a, c.a}` -- when evaluated, both will inherit the same name of `a`, causing one value to overwrite the other.
Neither value will be indexed.
A better way to handle this is to name one field explicitly, such as `{a, "ca":c.a}`.
* If the value expression is _not_ an identifier directly referring to a named document field, such as `{abs(a)}` -- the name of the object field is null, and this will generate an error.
A better way to handle this is to use a field name explicitly, such as `{"abs_a":abs(a)}`.
</dd></dl>

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

Consider the following indexes, which are included with the `travel-sample` data that is shipped with the product.
To install sample data, see [manage:manage-settings/install-sample-buckets.adoc](manage:manage-settings/install-sample-buckets.adoc).

<a name="C1"></a>**C{counter:ai}**

```sqlpp
CREATE INDEX `def_inventory_airport_airportname`
ON `travel-sample`.`inventory`.`airport`(`airportname`) WITH { "defer_build":true }
```

<a name="C2"></a>**C{counter:ai}**

```sqlpp
CREATE INDEX `def_inventory_airport_city`
ON `travel-sample`.`inventory`.`airport`(`city`) WITH { "defer_build":true }
```

<a name="C3"></a>**C{counter:ai}**

```sqlpp
CREATE INDEX `def_inventory_airport_faa`
ON `travel-sample`.`inventory`.`airport`(`faa`) WITH { "defer_build":true }
```

Here, three different indexes are needed to help different queries whose WHERE clause predicates may refer to different fields.
For instance, the following queries [Q{counter:q1}](#Q1), [Q{counter:q1}](#Q2), and [Q{counter:q1}](#Q3) will use the indexes created in [C{counter:ai}](#C1), [C{counter:ai}](#C2), and [C{counter:ai}](#C3), respectively:

<a name="Q1"></a>**Q{counter:q1}**

```sqlpp
SELECT * FROM airport WHERE airportname LIKE "San Francisco%";
```

<a name="Q2"></a>**Q{counter:q1}**

```sqlpp
SELECT * FROM airport WHERE city = "San Francisco";
```

<a name="Q3"></a>**Q{counter:q1}**

```sqlpp
SELECT * FROM airport WHERE faa = "SFO";
```

However, the following single adaptive index [C{counter:ai}](#C4) can serve all three of the following queries [Q{counter:q2}A](#Q1A), [Q{counter:q2}A](#Q2A), and [Q{counter:q2}A](#Q3A):

<a name="C4"></a>**C{counter:ai}**

```sqlpp
CREATE INDEX `ai_airport_day_faa`
ON airport(DISTINCT PAIRS({airportname, city, faa, type}));
```

<a name="Q1A"></a>**Q{counter:q2}A**

```sqlpp
SELECT * FROM airport
USE INDEX (ai_airport_day_faa)
WHERE airportname LIKE "San Francisco%";
```

<a name="Q2A"></a>**Q{counter:q2}A**

```sqlpp
SELECT * FROM airport
USE INDEX (ai_airport_day_faa)
WHERE city = "San Francisco";
```

<a name="Q3A"></a>**Q{counter:q2}A**

```sqlpp
SELECT * FROM airport
USE INDEX (ai_airport_day_faa)
WHERE faa = "SFO";
```

Similarly, the following adaptive index over `SELF` in [C{counter:ai}](#C5) is also qualified for these queries.
In fact, an adaptive index that includes all fields in the documents can serve any query on the keyspace, though it might have different performance characteristics when compared to specific indexes created for a particular query.
See the section [Performance Implications](#performance-implications) for details.
For example, the following queries [Q{ai}](#Q5) and [Q{ai}A](#Q5A) show how the generic adaptive index [C{counter:ai}](#C5) is used to query predicates on different fields of the "airport" documents.

<a name="C5"></a>**C{counter:ai}**

```sqlpp
CREATE INDEX `ai_self`
ON airport(DISTINCT PAIRS(self));
```

<a name="Q5"></a>**Q{ai}**

```sqlpp
EXPLAIN SELECT * FROM airport
USE INDEX (ai_self)
WHERE faa = "SFO";
```

**Result**

```json
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
            "index": "ai_self",
            "index_id": "1243095ed73061b5",
            "index_projection": {
              "primary_key": true
            },
            "keyspace": "airport",
            "namespace": "default",
            "scope": "inventory",
            "spans": [
              {
                "exact": true,
                "range": [
                  {
                    "high": "[\"faa\", \"SFO\"]",
                    "inclusion": 3,
                    "low": "[\"faa\", \"SFO\"]"
                  }
                ]
              }
            ],
            "using": "gsi"
          }
// ...
```

<a name="Q5A"></a>**Q{ai}A**

```sqlpp
EXPLAIN SELECT *
FROM airport
USE INDEX (ai_self)
WHERE tz = "Europe/Paris";
```

**Result**

```json
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
            "index": "ai_self",
            "index_id": "1243095ed73061b5",
            "index_projection": {
              "primary_key": true
            },
            "keyspace": "airport",
            "namespace": "default",
            "scope": "inventory",
            "spans": [
              {
                "exact": true,
                "range": [
                  {
                    "high": "[\"tz\", \"Europe/Paris\"]",
                    "inclusion": 3,
                    "low": "[\"tz\", \"Europe/Paris\"]"
                  }
                ]
              }
            ],
            "using": "gsi"
          }
// ...
```

## Contrast with Composite Indexes

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

Traditionally, composite secondary indexes are used to create indexes with multiple index keys.
For example, consider the following index in [C{counter:ai}](#C6):

<a name="C6"></a>**C{counter:ai}**

```sqlpp
CREATE INDEX `idx_city_faa_airport`
ON airport(city, faa, airportname);
```

Such composite indexes are very different from the adaptive index in [C{counter:ai}](#C4) in many ways:

1. **Order of index keys is vital for composite indexes.**  When an index key is used in the WHERE clause, all prefixing index keys in the index definition must also be specified in the WHERE clause.
For example, to use the index [C{counter:ai}](#C6), a query to _"find details of airports with FAA code SFO"_, must specify the prefixing index key `city` also in the WHERE clause just to qualify the index [C{counter:ai}](#C6).
Contrast the following query [Q{ai}](#Q6) with [Q{counter:q1}](#Q3) above that uses the adaptive index in [C{counter:ai}](#C3).

   <a name="Q6"></a>**Q{ai}**

   ```sqlpp
   SELECT * FROM airport
   WHERE faa = "SFO"
   AND city IS NOT MISSING;
   ```

   The problem is not just the addition of an extraneous predicate, but the performance.
   The predicate on the first index key `city IS NOT MISSING` is highly selective (i.e.
   most of the index entries in the index will match it) and hence, it will result in almost a full index scan.
2. **Complication in Queries.**  If a document has many fields to index, then the composite index will end up with all those fields as index keys.
Subsequently, queries that only need to use index keys farther in the index key order will need many unnecessary predicates referring to all the preceding index keys.
For example, if the index is:

   ```sqlpp
   CREATE INDEX idx_name ON `travel-sample`(field1, field2, ..., field9);
   ```

   A query that has a predicate on `field9` will get unnecessarily complicated, as it needs to use all preceding index keys from `field1` to `field8`.
3. **Explosion of number of indexes for ad hoc queries.** At some point, it becomes highly unnatural and overly complicated to write ad hoc queries using composite indexes.
For instance, consider a user profile or inventory search use case where a person or item may need to be searched based on many criteria.

   One approach is to create indexes on all possible attributes.
   If that query can include any of the attributes, then it may require creation of innumerable indexes.
   For example, a modest 20 attributes will result in 20 factorial (2.43×10^18^) indexes in order to consider all combinations of sort orders of the 20 attributes.

## Partial Adaptive Indexes

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

An adaptive index may also be a [partial index](indexes:indexing-and-query-perf.adoc#partial-index).
For a partial adaptive index, you must ensure that any fields filtered by the WHERE clause in the index definition are also referenced by the [PAIRS()](n1ql-language-reference/metafun.adoc#pairs) function.

For example, the following query [Q{ai}](#Q9) cannot select the index defined in [C{counter:ai}A](#C9A).

<a name="C9A"></a>**C{counter:ai}A**

```sqlpp
CREATE INDEX ai_geo ON landmark
(DISTINCT PAIRS({geo.alt, geo.lat, geo.lon}))
WHERE activity = "see"; -- ①
```

1. The WHERE clause filters on `activity`, but the [PAIRS()](n1ql-language-reference/metafun.adoc#pairs) function does not include the `activity` field.

<a name="Q9"></a>**Q{ai}**

```sqlpp
EXPLAIN SELECT META(t).id FROM landmark t
WHERE t.geo.alt > 1000 AND t.activity = "see";
```

**Result**

```json
[
  {
    "plan": {
      "#operator": "Sequence",
      "~children": [
        {
          "#operator": "PrimaryScan3",
          "as": "t",
          "bucket": "travel-sample",
          "index": "def_inventory_landmark_primary", // ①
// ...
```

1. The query does not use the incorrectly-defined partial adaptive index.

However, the same query [Q{ai}](#Q9) does select the partial adaptive index defined in [C{ai}B](#C9B).

<a name="C9B"></a>**C{ai}B**

```sqlpp
CREATE INDEX ai_geo_activity ON landmark
(DISTINCT PAIRS({geo.alt, geo.lat, geo.lon, activity}))
WHERE activity = "see"; -- ①
```

1. The WHERE clause filters on `activity`, and the [PAIRS()](n1ql-language-reference/metafun.adoc#pairs) function includes the `activity` field.

**Result**

```json
[
  {
    "plan": {
      "#operator": "Sequence",
      "~children": [
        {
          "#operator": "IntersectScan",
          "scans": [
            {
              "#operator": "DistinctScan",
              "scan": {
                "#operator": "IndexScan3",
                "as": "t",
                "bucket": "travel-sample",
                "index": "ai_geo_activity", // ①
                "index_id": "29640ebd837e32fb",
                "index_projection": {
                  "primary_key": true
                },
// ...
```

1. The query does an IntersectScan, including the correct partial adaptive index.

Alternatively, you can use the `SELF` keyword to ensure that the fields used in the WHERE clause are included in the [PAIRS()](n1ql-language-reference/metafun.adoc#pairs) function.
Refer to [C{counter:ai}](#C5) for an example.

An IntersectScan does not eliminate redundant queries, and this may impact performance.
Refer to [Performance Implications](#performance-implications) for details.

## Performance Implications

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

While Adaptive Indexes are very useful, there are performance implications you need to keep in mind:

1. **If a query is not covered by a regular index, then an unnested index will not have any elimination of redundant indexes**; and it will instead do an IntersectScan on all the indexes, which can impact performance.

   ```sqlpp
   CREATE INDEX idx_name ON hotel(name); -- ①
   CREATE INDEX idx_self ON hotel(DISTINCT PAIRS(self)); -- ②
   EXPLAIN SELECT * FROM hotel WHERE name IS NOT NULL;
   ```

   1. Index on the `name` field.
   2. Adaptive index on the whole document.

   **Results**

   ```json
   [
     {
       "plan": {
         "#operator": "Sequence",
         "~children": [
           {
             "#operator": "IntersectScan", // ①
             "scans": [
               {
                 "#operator": "IndexScan3",
                 "bucket": "travel-sample",
                 "index": "idx_name",
   // ...
               },
               {
                 "#operator": "DistinctScan",
                 "scan": {
                   "#operator": "IndexScan3",
                   "bucket": "travel-sample",
                   "index": "idx_self",
   // ...
   ```

   1. IntersectScan of `idx_name` AND `idx_self`.

   Here’s another example with a partial Adaptive Index that uses IntersectScan on the index conditions:

   ```sqlpp
   CREATE INDEX idx_adpt ON landmark(DISTINCT PAIRS(self))
   WHERE city="Paris";

   CREATE INDEX idx_reg1 ON landmark(name) WHERE city="Paris";

   CREATE INDEX idx_reg2 ON landmark(city);

   SELECT * FROM landmark
   WHERE city="Paris" AND name IS NOT NULL;
   ```

   The above query requires only a regular index, so it uses index `idx_reg1` and ignores index `idx_reg2`.
   When the adaptive index `idx_adpt` has only the clause `city="Paris"` and is used with the above query, then index `idx_adpt` will still use IntersectScan.
   Here, we have only a single adaptive index instead of a reduction in the number of indexes.
   To fix this, you may need to remove the index condition from the predicate while spanning generations.

## Functional Limitations

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

It is important to understand that adaptive indexes are not a panacea and that they have trade-offs compared to traditional composite indexes:

1. **Adaptive Indexes are bound to the limitations of Array Indexes** because they are built over [Array Indexing](n1ql-language-reference/indexing-arrays.adoc) technology.
Index Joins can’t use Adaptive Indexes because Index Joins can’t use array indexes, and Adaptive Index is basically an array index.
2. **Indexed entries of the Adaptive Index are typically larger in size compared to the simple index** on respective fields because the indexed items are elements of the [PAIRS()](n1ql-language-reference/metafun.adoc#pairs) array, which are basically name-value pairs of the document fields.
So, it may be relatively slower when compared with equivalent simple index.
For example, in the following equivalent queries, [C{counter:ai}](#C7)/[Q{ai}](#Q7) may perform better than [C{counter:ai}](#C8)/[Q{ai}](#Q8).

   This example uses the `def_inventory_hotel_city` index, which is installed with the `travel-sample` bucket.

   <a name="C7"></a>**C{counter:ai}**

   ```sqlpp
   CREATE INDEX `def_inventory_hotel_city`
   ON `travel-sample`.`inventory`.`hotel`(`city`) WITH { "defer_build":true };
   ```

   <a name="Q7"></a>**Q{ai}**

   ```sqlpp
   EXPLAIN SELECT city FROM hotel
   USE INDEX (def_inventory_hotel_city)
   WHERE city = "San Francisco";
   ```

   **Result**

   ```json
   {
     "plan": {
       "#operator": "Sequence",
       "~children": [
         {
           "#operator": "IndexScan3",
           "bucket": "travel-sample",
           "covers": [
             "cover ((`hotel`.`city`))",
             "cover ((meta(`hotel`).`id`))"
           ],
           "filter": "(cover ((`hotel`.`city`)) = \"San Francisco\")",
           "index": "def_inventory_hotel_city",
           "index_id": "581febfa2f2a8923",
           "index_projection": {
             "entry_keys": [
               0
             ]
           },
           "keyspace": "hotel",
           "namespace": "default",
           "scope": "inventory",
           "spans": [
             {
               "exact": true,
               "range": [
                 {
                   "high": "\"San Francisco\"",
                   "inclusion": 3,
                   "low": "\"San Francisco\""
                 }
               ]
             }
           ],
           "using": "gsi"
         },
   // ...
   ```

   <a name="C8"></a>**C{counter:ai}**

   ```sqlpp
   CREATE INDEX `ai_city` ON hotel(DISTINCT PAIRS({city}));
   ```

   <a name="Q8"></a>**Q{ai}**

   ```sqlpp
   EXPLAIN SELECT city FROM hotel
   USE INDEX (ai_city)
   WHERE city = "San Francisco";
   ```

   **Result**

   ```json
   {
     "plan": {
       "#operator": "Sequence",
       "~children": [
         {
           "#operator": "DistinctScan",
           "scan": {
             "#operator": "IndexScan3",
             "bucket": "travel-sample",
             "index": "ai_city",
             "index_id": "64e238e4686486d2",
             "index_projection": {
               "primary_key": true
             },
             "keyspace": "hotel",
             "namespace": "default",
             "scope": "inventory",
             "spans": [
               {
                 "exact": true,
                 "range": [
                   {
                     "high": "[\"city\", \"San Francisco\"]",
                     "inclusion": 3,
                     "low": "[\"city\", \"San Francisco\"]" // ①
                   }
                 ]
               }
             ],
             "using": "gsi"
           }
         },
   // ...
   ```

   1. Note how the index key values are represented in the spans.
3. **Adaptive index requires more storage and memory**, especially in case of Memory Optimized Indexes.
   1. The size of the index and the number of indexed items in an Adaptive Index grow rapidly with the number of fields in the documents, as well as, with the number of different values for various fields in the documents or keyspace.
   2. Moreover, if the documents have nested sub-objects, then the adaptive index will index the sub-documents and related fields at each level of nesting.
   3. Similarly, if the documents have array fields, then each of array elements are explored and indexed.
   4. For example, the following queries show that a single route document in `travel-sample` generates 103 index items and that all route documents produce ~2.3 million items.

      ```sqlpp
      SELECT array_length(PAIRS(self)) FROM route
      LIMIT 1;
      ```

      **Result**

      ```json
      [
        {
          "$1": 103
        }
      ]
      ```

      ```sqlpp
      SELECT sum(array_length(PAIRS(self))) FROM route
      LIMIT 1;
      ```

      **Result**

      ```json
      [
        {
          "$1": 2285464
        }
      ]
      ```

+
So, the generic adaptive indexes (with `SELF`) should be employed carefully.
Whenever applicable, it is recommended to use the following techniques to minimize the size and scope of the adaptive index:

* Instead of `SELF`, use selective adaptive indexes by specifying the field names of interest to the [PAIRS()](n1ql-language-reference/metafun.adoc#pairs) function.
For examples, refer to [C{counter:ai}](#C4), [Q{counter:q1}](#Q1), [Q{counter:q1}](#Q2), and [Q{counter:q1}](#Q3) above.
* Use partial adaptive indexes with a WHERE clause that will filter the number of documents that will be indexed.
For examples, refer to [C{counter:ai}](#C5), [Q{ai}](#Q5), and [Q{ai}A](#Q5A) above.
  1. **A generic adaptive index (on SELF) will be qualified for all queries on the keyspace**.
  So, when using with other GSI indexes, this will result in more IntersectScan operations for queries that qualify other non-adaptive indexes.
  This may impact query performance and overall load on query and indexer nodes.
  To alleviate the negative effects, you may want to specify the `USE INDEX` clause in `SELECT` queries whenever possible.
  2. **Adaptive Indexes cannot be used as Covered Indexes** for any queries.
  See example [Q{ai}](#Q8) above.
  3. **Adaptive Indexes can be created only on document field identifiers**, not on functional expressions on the fields.
  For example, the following query uses a default index, such as `def_inventory_hotel_city`, instead of the specified adaptive index `ai_city1`:

     ```sqlpp
     CREATE INDEX `ai_city1`
     ON hotel(DISTINCT PAIRS({"city" : LOWER(city)}));
     ```

     ```sqlpp
     EXPLAIN SELECT city FROM hotel
     USE INDEX (ai_city1)
     WHERE LOWER(city) = "san francisco";
     ```

     **Result**

     ```json
     [
       {
         "plan": {
           "#operator": "Sequence",
           "~children": [
             {
               "#operator": "IndexScan3",
               "bucket": "travel-sample",
               "covers": [
                 "cover ((`hotel`.`city`))",
                 "cover ((meta(`hotel`).`id`))"
               ],
               "filter": "(lower(cover ((`hotel`.`city`))) = \"san francisco\")",
               "index": "def_inventory_hotel_city", // ①
               "index_id": "581febfa2f2a8923",
     // ...
     ```

     1. The query does not use the specified `ai_city1` index because the index uses a functional index expression on the field `city`.
  4. **Adaptive Indexes do not work with NOT LIKE predicates with a leading wildcard** (see [MB-23981](https://issues.couchbase.com/browse/MB-23981)).
  For example, the following query also uses a default index, such as `def_city`, instead of the specified adaptive index `ai_city`.
  However, it works fine for LIKE predicates with a leading wildcard.

     **Query: NOT LIKE with leading wildcard**

     ```sqlpp
     EXPLAIN SELECT city FROM hotel
     USE INDEX (ai_city)
     WHERE city NOT LIKE "%Francisco";
     ```

     **Result**

     ```json
     [
       {
         "plan": {
           "#operator": "Sequence",
           "~children": [
             {
               "#operator": "IndexScan3",
               "bucket": "travel-sample",
               "covers": [
                 "cover ((`hotel`.`city`))",
                 "cover ((meta(`hotel`).`id`))"
               ],
               "filter": "(not (cover ((`hotel`.`city`)) like \"%Francisco\"))",
               "index": "def_inventory_hotel_city", // ①
               "index_id": "581febfa2f2a8923",
     // ...
     ```

     1. Doesn’t use `ai_city` with `NOT LIKE` and leading wildcard.

     **Query: LIKE with leading wildcard**

     ```sqlpp
     EXPLAIN SELECT city FROM hotel
     USE INDEX (ai_city)
     WHERE city LIKE "%Francisco";
     ```

     **Result**

     ```json
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
                 "index": "ai_city", // ①
                 "index_id": "64e238e4686486d2",
     // ...
     ```

     1. Uses `ai_city` with `LIKE` and leading wildcard.
  5. **Adaptive indexes can’t use Covered Scans**.
  An adaptive index can’t be a covering index, as seen in the following example:

     ```sqlpp
     CREATE INDEX `ai_city2`
     ON hotel(DISTINCT PAIRS({"city" : city}));
     ```

     ```sqlpp
     EXPLAIN SELECT city FROM hotel
     WHERE city = "San Francisco"; -- ①
     ```

     1. No index specified in query.

     **Result**

     ```json
     [
       {
         "plan": {
           "#operator": "Sequence",
           "~children": [
             {
               "#operator": "IndexScan3",
               "bucket": "travel-sample",
               "covers": [
                 "cover ((`hotel`.`city`))",
                 "cover ((meta(`hotel`).`id`))"
               ],
               "filter": "(cover ((`hotel`.`city`)) = \"San Francisco\")",
               "index": "def_inventory_hotel_city", // ①
               "index_id": "581febfa2f2a8923",
     // ...
     ```

     1. Doesn’t use `ai_city2` as a covering index.
