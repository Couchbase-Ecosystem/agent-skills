# ADVISE

The ADVISE statement provides index recommendations to optimize query response time.

## Purpose

The ADVISE statement invokes the _index advisor_ to provide index recommendations for a single query.
You can use the ADVISE statement with any of the following types of query:

* [SELECT](n1ql-language-reference/selectintro.adoc) queries
* [UPDATE](n1ql-language-reference/update.adoc) queries
* [DELETE](n1ql-language-reference/delete.adoc) queries
* [MERGE](n1ql-language-reference/merge.adoc) queries
* [USING AI](n1ql-language-reference/using-ai.adoc) queries (available in Couchbase Server 8.0 and later)

The index advisor can recommend regular secondary indexes, partial indexes, and array indexes for the following predicates and conditions:

* Predicates in the WHERE clause
* Join conditions in the ON clause for INDEX JOIN, ANSI JOIN, ANSI NEST, INDEX NEST, and ANSI MERGE operations
* Predicates of elements in an UNNEST array
* Predicates with the ANY expression
* Predicates of subqueries in the FROM clause

The index advisor also suggests covering indexes and covering array indexes for queries in a single keyspace, including JOIN operations, ANY expressions, and UNNEST predicates.

The index advisor checks the indexes currently used by the query.
If the query is already using the recommended indexes, the index advisor informs you, and does not recommend an index unnecessarily.
Similarly, if the query is already using the optimal covering index, the index advisor informs you, and does not recommend a covering index.

## Prerequisites

To execute the ADVISE statement, you must have the privileges required for the {sqlpp} statement for which you want advice.
For more details about user roles, see [Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
advise ::= 'ADVISE' 'INDEX'? ( select | update | delete | merge | using-ai )
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/advise.png)

The statement consists of the `ADVISE` keyword, and optionally the `INDEX` keyword, followed by the query for which you want index advice -- a [SELECT](n1ql-language-reference/selectintro.adoc) query, an [UPDATE](n1ql-language-reference/update.adoc) query, a [DELETE](n1ql-language-reference/delete.adoc) query, a [MERGE](n1ql-language-reference/merge.adoc) query, or a [USING AI](n1ql-language-reference/using-ai.adoc) query.

**📌 NOTE**\
You can use `ADVISE` with `USING AI` only in Couchbase Server 8.0 and later.

## Usage

When you run an ADVISE statement in the Query Workbench, you can use the **Table**, **JSON**, or **Tree** link to see the result, just like any other query.
You can also use the **Advice** link in the Query Workbench to see the result of the ADVISE statement in graphical format.

## Return Value

The ADVISE statement returns an object with the following properties.

| Name | Description | Schema |
| --- | --- | --- |
| ***#operator***<br> __required__ | The name of the operator -- in this case, `Advise`. | string |
| ***advice***<br> __required__ | An object giving advice returned by the operator. | [Advice](#advice) |
| ***query***<br> __required__ | The {sqlpp} query used to generate the advice. | string |

<a name="advice"></a>***Advice***

| Name | Description | Schema |
| --- | --- | --- |
| ***#operator***<br> __required__ | The name of the operator -- in this case, `IndexAdvice`. | string |
| ***adviseinfo***<br> __required__ | An object giving index information. | [Information](#information) |

<a name="information"></a>***Information***

| Name | Description | Schema |
| --- | --- | --- |
| ***current_indexes***<br> __required__ | An array of Index objects, each giving information about one of the indexes (primary or secondary) that is currently used by the query. | < [Indexes](#indexes) > array |
| ***recommended_indexes***<br> __required__ | If the index advisor recommends any indexes, this is an object giving information about the recommended indexes. If the index advisor cannot recommend any indexes, this is a string stating that there are no recommended indexes at this time. | [Recommended Indexes](#recommended_indexes) |

<a name="recommended_indexes"></a>***Recommended Indexes***

| Name | Description | Schema |
| --- | --- | --- |
| ***covering_indexes***<br> __optional__ | If there are any recommended covering indexes, this is an array of Index objects, each giving information about one of the recommended covering indexes. If there are no recommended covering indexes, this field does not appear. | < [Indexes](#indexes) > array |
| ***indexes***<br> __required__ | An array of Index objects, each giving information about one of the recommended secondary indexes. | < [Indexes](#indexes) > array |

<a name="indexes"></a>***Indexes***

| Name | Description | Schema |
| --- | --- | --- |
| ***index_statement***<br> __required__ | The {sqlpp} command used to define the index. | string |
| ***keyspace_alias***<br> __required__ | The keyspace to which the index belongs. If the query specifies an alias for this keyspace, the alias is appended to the keyspace name, joined by an underscore. This may help to distinguish the indexes for either side of a JOIN operation. | string |
| ***index_property***<br> __optional__ | The [index pushdowns](#pushdown-properties) supported by the index. This field is only returned for covering indexes. If no index pushdowns are supported by the covering index, this field does not appear. | string |
| ***index_status***<br> __optional__ | Information on the status of the index, stating whether the index is identical to the recommended index, or whether the index is an optimal covering index. This field is only returned for current indexes. If the index is not identical to the recommended index, or if it is not an optimal covering index, this field does not appear. | string |
| ***recommending_rule***<br> __optional__ | The [rules](#recommendation-rules) used to generate the recommendation. This field is only returned for recommended indexes, or for current indexes if they are identical to the recommended index. | string |
| ***update_statistics***<br> __optional__ | The {sqlpp} command recommended for updating statistics on the index, for use by the cost-based optimizer. This field is only returned for indexes which are recommended by the cost-based optimizer, and only if optimizer statistics are missing for the index. | string |

### Recommendation Rules

The index advisor recommends secondary indexes based on the query predicate.

In Couchbase Server 7.0 and later, the index advisor initially makes use of the [cost-based optimizer](n1ql-language-reference/cost-based-optimizer.adoc).
To do this, the cost-based optimizer must be enabled, and statistics for the keyspace must already exist.
If these prerequisites are met, the cost-based optimizer analyzes the query predicate and attempts to recommend an index.

If the cost-based optimizer cannot recommend an index, the index advisor falls back on a rules-based approach.
The rules are listed below in priority order.
Within each recommended index, if there is more than one index key, they are sorted according to the priority order of these rules.

|     |     |     |
| --- | --- | --- |
| Rule | Description | Recommendation |
```
UNNEST schedule AS x
WHERE x.day = 1
```
| [start=1] . Leading array index for UNNEST | The query uses a predicate which applies to individual elements in an unnested array. .Example | An [array index](indexes:indexing-and-query-perf.adoc#array-index), where the leading index key is an array expression indexing all elements in the unnested array. |
```
WHERE ANY v IN schedule
SATISFIES v.utc = "19:00" END

WHERE LOWER(name) = "john"

WHERE id = 10
```
| [#rule-2,reftext="Rule 2",start=2] . Equality / NULL / MISSING | The query has a predicate with an [equality](n1ql-language-reference/comparisonops.adoc), [IS NULL](n1ql-language-reference/comparisonops.adoc), or [IS MISSING](n1ql-language-reference/comparisonops.adoc) expression. .Examples | If the predicate contains an [ANY](n1ql-language-reference/collectionops.adoc#collection-op-any) expression: an [array index](indexes:indexing-and-query-perf.adoc#array-index), where the index key is an array expression recursively indexing all elements referenced by the predicate expression. If the predicate contains an indexable function: a [functional index](indexes:indexing-and-query-perf.adoc#functional-index), where the index key contains the function referenced by the predicate expression. Otherwise: a [secondary index](indexes:indexing-and-query-perf.adoc#secondary-index), where one index key is the field referenced by the predicate expression. |
```
WHERE ANY v IN schedule
SATISFIES v.utc
IN ["19:00", "20:00"] END

WHERE LOWER(name)
IN ["jo", "john"]

WHERE id IN [10, 20]
```
| [start=3] . IN predicates | The query has a predicate with an [IN](n1ql-language-reference/collectionops.adoc#collection-op-in) expression. .Examples | Refer to [rule-2](#rule-2). |
```
WHERE ANY v IN schedule
SATISFIES v.utc BETWEEN
"19:00" AND "20:00" END

WHERE LOWER(name)
BETWEEN "jo" AND "john"

WHERE id BETWEEN 10 AND 25
```
| [start=4] . Not less than / between / not greater than | The query has a predicate with a [+<=+](n1ql-language-reference/comparisonops.adoc), [BETWEEN](n1ql-language-reference/comparisonops.adoc), or [+>=+](n1ql-language-reference/comparisonops.adoc) expression. .Examples | Refer to [rule-2](#rule-2). |
```
WHERE ANY v IN schedule
SATISFIES v.utc > "19:00" END

WHERE LOWER(name) > "jo"

WHERE id > 10 AND id < 25
```
| [start=5] . Less than / greater than | The query has a predicate with a [<](n1ql-language-reference/comparisonops.adoc) or [>](n1ql-language-reference/comparisonops.adoc) expression. .Examples | Refer to [rule-2](#rule-2). |
```
FROM route r JOIN airline a
ON r.airlineid = META(a).id
```
| [start=6] . Derived join filter as leading key | The query has a [join](n1ql-language-reference/join.adoc) using an ON clause which filters on the left-hand side keyspace. .Example | A [secondary index](indexes:indexing-and-query-perf.adoc#secondary-index), where the leading index key is the field from the left-hand side keyspace in the ON clause. |
```
WHERE ANY v IN schedule
SATISFIES v.utc IS NOT NULL
END

WHERE LOWER(name) IS NOT NULL

WHERE id IS NOT NULL
```
| [start=7] . IS NOT NULL / MISSING / VALUED predicates | The query has a predicate with [IS NOT NULL](n1ql-language-reference/comparisonops.adoc), [IS NOT MISSING](n1ql-language-reference/comparisonops.adoc), or [IS NOT VALUED](n1ql-language-reference/comparisonops.adoc). .Examples | Refer to [rule-2](#rule-2). |
```
WHERE name LIKE "%base"
```
| [start=8] . LIKE predicates | The query has a predicate with a [LIKE](n1ql-language-reference/comparisonops.adoc) expression, where there is a `%` wildcard at the start of the match string. .Example | A [secondary index](indexes:indexing-and-query-perf.adoc#secondary-index), where one index key is the field referenced by the predicate expression. |
```
FROM route r JOIN airline a
ON r.airline = a.iata
```
| [start=9] . Non-static join predicate | The query has a [join](n1ql-language-reference/join.adoc) using an ON clause in which neither the left-hand side source object nor the right-hand side source object is static. .Example | A [secondary index](indexes:indexing-and-query-perf.adoc#secondary-index), where one index key is the field from the right-hand side keyspace in the ON clause. |
```
WHERE type = "hotel"
```
| [start=10] . Flavor for partial index | The query includes filters on a particular [flavor](n1ql-language-reference/infer.adoc#schema-output) of document. .Example | A [partial index](indexes:indexing-and-query-perf.adoc#partial-index) for that flavor of document. |

### Pushdown Properties

The index advisor optimizes any covering indexes that it recommends, in order to support the following pushdowns:

* LIMIT pushdown
* OFFSET pushdown
* ORDER pushdown
* Partial GROUP BY and aggregates pushdown
* Full GROUP BY and aggregates pushdown

The GROUP BY and aggregate pushdowns support aggregation using the [MIN()](n1ql-language-reference/aggregatefun.adoc#min), [MAX()](n1ql-language-reference/aggregatefun.adoc#max), [SUM()](n1ql-language-reference/aggregatefun.adoc#sum), [COUNTN()](n1ql-language-reference/aggregatefun.adoc#countn), and [AVG()](n1ql-language-reference/aggregatefun.adoc#avg) functions, with the [DISTINCT](n1ql-language-reference/aggregatefun.adoc#aggregate-quantifier) aggregate quantifier if necessary.

The GROUP BY and aggregate pushdowns may be _full_ or _partial_.
Full pushdown means the indexer handles the group aggregation fully, and the query engine can skip the entire operator.
Partial pushdown means the indexer sends part of the group aggregation to the query, and the query engine merges the intermediate groups to create the final group and aggregation.

### Index Names

The index advisor suggests a name for each index it recommends, starting with `adv_`, followed by the `DISTINCT` or `ALL` keyword for array indexes if applicable, and including the names of the fields referenced in the index definition, separated by underscores -- for example, `adv_city_type_name`.
Some field names may be truncated if they are too long.

**📌 NOTE**\
The names that the index advisor suggests are not guaranteed to be unique.
You should check the suggested index names and change any that are duplicates.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Recommended index only**

Assume that the cost-based optimizer is enabled, and that statistics exist for the keyspace.

```sqlpp
ADVISE SELECT * FROM hotel a WHERE a.country = 'France';
```

**Result**

```json
[
  {
    "#operator": "Advise",
    "advice": {
      "#operator": "IndexAdvice",
      "adviseinfo": {
        "current_indexes": [
          {
            "index_statement": "CREATE PRIMARY INDEX def_inventory_hotel_primary ON `default`:`travel-sample`.`inventory`.`hotel`",
            "keyspace_alias": "hotel_a"
          }
        ],
        "recommended_indexes": {
          "indexes": [
            {
              "index_statement": "CREATE INDEX adv_country ON `default`:`travel-sample`.`inventory`.`hotel`(`country`)",
              "keyspace_alias": "hotel_a",
              "recommending_rule": "Index keys follow cost-based order.", // ①
              "update_statistics": "UPDATE STATISTICS FOR `default`:`travel-sample`.`inventory`.`hotel`(`country`)" // ②
            }
          ]
        }
      }
    },
    "query": "SELECT * FROM `travel-sample`.inventory.hotel a WHERE a.country = 'France';"
  }
]
```

1. Index is recommended by the cost-based optimizer
2. Recommended command for updating statistics

**Recommended index and covering index**

```sqlpp
ADVISE SELECT airportname FROM airport
WHERE geo.alt NOT BETWEEN 0 AND 100;
```

**Result**

```json
[
  {
    "#operator": "Advise",
    "advice": {
      "#operator": "IndexAdvice",
      "adviseinfo": {
        "current_indexes": [
          {
            "index_statement": "CREATE PRIMARY INDEX idx_airport_primary ON `default`:`travel-sample`.`inventory`.`airport`",
            "keyspace_alias": "airport"
          }
        ],
        "recommended_indexes": {
          "covering_indexes": [
            {
              "index_statement": "CREATE INDEX adv_geo_alt_airportname ON `default`:`travel-sample`.`inventory`.`airport`(`geo`.`alt`,`airportname`)",
              "keyspace_alias": "airport"
            }
          ],
          "indexes": [
            {
              "index_statement": "CREATE INDEX adv_geo_alt ON `default`:`travel-sample`.`inventory`.`airport`(`geo`.`alt`)",
              "keyspace_alias": "airport",
              "recommending_rule": "Index keys follow order of predicate types: 1. Common leading key for disjunction (5. less than/greater than)."
            }
          ]
        }
      }
    },
    "query": "SELECT airportname FROM `travel-sample`.inventory.airport WHERE geo.alt NOT BETWEEN 0 AND 100;"
  }
]
```

**Current index is identical to the recommended index**

```sqlpp
ADVISE SELECT * FROM landmark
WHERE city LIKE "Par%" OR city LIKE "Lon%";
```

**Result**

```json
[
  {
    "#operator": "Advise",
    "advice": {
      "#operator": "IndexAdvice",
      "adviseinfo": {
        "current_indexes": [
          {
            "index_statement": "CREATE INDEX def_inventory_landmark_city ON `default`:`travel-sample`.`inventory`.`landmark`(`city`)",
            "index_status": "SAME TO THE INDEX WE CAN RECOMMEND",
            "keyspace_alias": "landmark",
            "recommending_rule": "Index keys follow order of predicate types: 1. Common leading key for disjunction (4. not less than/between/not greater than)."
          }
        ],
        "recommended_indexes": "No index recommendation at this time."
      }
    },
    "query": "SELECT * FROM `travel-sample`.inventory.landmark WHERE city LIKE \"Par%\" OR city LIKE \"Lon%\";"
  }
]
```

**Current index is an optimal covering index**

```sqlpp
ADVISE SELECT city FROM landmark
WHERE city LIKE "Par%" OR city LIKE "Lon%";
```

**Result**

```json
[
  {
    "#operator": "Advise",
    "advice": {
      "#operator": "IndexAdvice",
      "adviseinfo": {
        "current_indexes": [
          {
            "index_statement": "CREATE INDEX def_inventory_landmark_city ON `default`:`travel-sample`.`inventory`.`landmark`(`city`)",
            "index_status": "THIS IS AN OPTIMAL COVERING INDEX.",
            "keyspace_alias": "landmark"
          }
        ],
        "recommended_indexes": "No index recommendation at this time."
      }
    },
    "query": "SELECT city FROM `travel-sample`.inventory.landmark WHERE city LIKE \"Par%\" OR city LIKE \"Lon%\";"
  }
]
```

**No index can be recommended**

```sqlpp
ADVISE SELECT * FROM landmark LIMIT 5;
```

**Result**

```json
[
  {
    "#operator": "Advise",
    "advice": {
      "#operator": "IndexAdvice",
      "adviseinfo": {
        "current_indexes": [
          {
            "index_statement": "CREATE PRIMARY INDEX def_inventory_landmark_primary ON `default`:`travel-sample`.`inventory`.`landmark`",
            "keyspace_alias": "landmark"
          }
        ],
        "recommended_indexes": "No index recommendation at this time."
      }
    },
    "query": "SELECT * FROM `travel-sample`.inventory.landmark LIMIT 5;"
  }
]
```

## Related Links

* The [Index Advisor](tools:query-workbench.adoc#index-advisor) in the Query Workbench
* The [ADVISOR](n1ql-language-reference/advisor.adoc) function
* Blog post: [Index Advisor for N1QL Query Statement](https://blog.couchbase.com/?p=7370&preview=true)
