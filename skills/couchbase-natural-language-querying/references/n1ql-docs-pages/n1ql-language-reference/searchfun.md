# Search Functions

Search functions enable you to use [Full Text Search (FTS)](search:search.adoc) queries directly within a {sqlpp} query.

### Prerequisites

To use any of the search functions, the Search Service must be available on the cluster.
It’s recommended that you create a suitable Search index for the searches that you want to run.
For more information, refer to [search:create-search-indexes.adoc](search:create-search-indexes.adoc).

The examples on this page assume you have created a full-text search index using the following definition.

```json
{
 "name": "travel-sample-inventory-hotels",
 "type": "fulltext-index",
 "params": {
  "doc_config": {
   "mode": "scope.collection.type_field",
   "type_field": "type"
  },
  "mapping": {
   "default_analyzer": "standard",
   "default_datetime_parser": "dateTimeOptional",
   "default_field": "_all",
   "default_mapping": {
    "dynamic": true,
    "enabled": false
   },
   "default_type": "_default",
   "docvalues_dynamic": false,
   "index_dynamic": true,
   "store_dynamic": false,
   "type_field": "_type",
   "types": {
    "inventory.hotel": {
     "dynamic": true,
     "enabled": true
    }
   }
  },
  "store": {
   "indexType": "scorch",
   "segmentVersion": 15
  }
 },
 "sourceType": "gocbcore",
 "sourceName": "travel-sample",
 "sourceUUID": "",
 "sourceParams": {},
 "planParams": {
  "indexPartitions": 1
 },
 "uuid": ""
}
```

### Authorization

You do not need credentials for the Search Service to be able to use the search functions in a query.
The role **Data Admin** must be assigned to those who intend to create indexes; and the role **Data Reader** to those who intend to perform searches.
For information on creating users and assigning roles, see [Authorization](learn:security/authorization-overview.adoc).

### When to Use Search Functions

The search functions are useful when you need to combine a Full Text Search with the power of a {sqlpp} query; for example, combining joins and natural-language search in the same query.

If your database is running Couchbase Server version 7.6.2 and later, you can also use the search functions to use document metadata stored in Extended Attributes (XATTRs) inside a {sqlpp} query.

If you only need to use the capabilities of a Full Text Search without any {sqlpp} features, consider making use of the Search Service directly, through the user interface, the REST API, or an SDK.

## SEARCH(`identifier`, `query`[, `options`])

### Description

This function enables you to use a Full Text Search to filter a result set, or as a join predicate.
It is only allowed in the [WHERE](n1ql-language-reference/where.adoc) clause or the [ON](n1ql-language-reference/join.adoc) clause.

If a query contains a SEARCH function, the Query engine analyzes the entire query, including the search specification, to select the best index to use with this search, taking any index hints into account.
The Query engine then passes the search specification over to the Search engine to perform the search.

If no suitable Search index can be selected, or no Search index exists, the Query engine falls back on a Primary index or qualified GSI index to produce document keys, and then fetches the documents.
The Search Service then creates a temporary index in memory to perform the search.
This process may be slower than using a suitable Search index.

If there is no suitable Search index, but you want to return XATTRs data from your documents in another part of your {sqlpp} query, you must use the [META function](n1ql-language-reference/metafun.adoc#meta) to select the XATTRs field you want to return.
{sqlpp} cannot return XATTRs data without a specific field name.

If you do have a Search index available for your query that includes XATTRs data, and you still want to use that data outside of the SEARCH function, you must use the [SEARCH_META() function](#search_metaidentifier) to select the XATTRs field.
You must also include the [fields property](search:search-request-params.adoc#fields) with the name of the XATTRs field in your Search request.

**📌 NOTE**\
From Couchbase Server 7.6 and later, when you use the SEARCH function, you do not need to use the [keyword analyzer](search:default-analyzers-reference.adoc#keyword) in your Search index to run a non-analytic query.
You also do not need to match the analyzer in a query to the analyzer in the Search index for an analytic query.
For more information about how to set the analyzer for a Search index, see [search:set-advanced-settings.adoc](search:set-advanced-settings.adoc) or the [Mapping Object](search:search-index-params.adoc#mapping).

### Arguments

* **identifier**\
[Required] An expression in the form `__keyspaceAlias__[.__path__]`, consisting of the keyspace or keyspace alias in which to search, followed by the path to a field in which to search, using dot notation.

  * The identifier must contain the keyspace or keyspace alias if there is more than one input source in the FROM clause.
  If there is only one input source in the FROM clause, and the identifier contains a path, the keyspace or keyspace alias may be omitted.
  However, if the path is omitted, the keyspace or keyspace alias is mandatory.
  * When the identifier contains a path, it is used as the default field in the _query_ argument, as long as the _query_ argument is a query string.
  If the path is omitted, the default field is set to `_all`.
  If the _query_ argument is a query string which specifies a field, this field takes priority, and the path in the identifier is ignored.
  Similarly, if the _query_ argument is a query object, the path is ignored.
  * The path must use Search syntax rather than {sqlpp} syntax; in other words, you cannot specify array locations such as `[*]` or `[3]` in the path.
  * If the keyspace, keyspace alias, or path contains any characters such as `-`, you must surround that part of the identifier with backticks `{backtick}{backtick}`.

  The _identifier_ argument cannot be replaced by a {sqlpp} query parameter.
* **query**\
[Required] The Full Text Search query.
This may be one of the following:

  |     |     |
  | --- | --- |
  | Type | Description |
  | string | A query string. For more information about how to format a query string, refer to [Query String Query](search:search-request-params.adoc#query-string-query-syntax). |
  | object | The `query` object within a Full Text Search request. For more information about how to format the `query` object, see [Query object](search:search-request-params.adoc#query-object). |
  | object | A complete Full Text Search request, including sort and pagination options, and so on. For more information about how to format a full search request object, refer to [search:search-request-params.adoc](search:search-request-params.adoc). |
  <dl><dt><strong>📌 NOTE</strong></dt><d When specifying a complete Full Text Search request with the {sqlpp} SEARCH() function, if the value of the `size` parameter is greater than the [maximum number of Full Text Search results](fts:fts-search-response.adoc), the query ignores the `size` parameter and returns all matching results. This is different to the behavior of a complete Full Text Search request in the Search Service, where the query returns an error if the value of the `size` parameter is greater than the maximum number of Full Text Search results. |

  </dd></dl>

  The _query_ argument may be replaced by a {sqlpp} query parameter, as long as the query parameter resolves to a string or an object.
* **options**\
[Optional] A JSON object containing options for the search.
The object may contain the following fields:

  |     |     |     |
  | --- | --- | --- |
  | Name | Type | Description |
  | `index` | string, object | The `index` field can be a string, containing the name of a Search index in the keyspace. (This might be a Search index alias, but only if the Search index is in the same keyspace.) This provides an index hint to the Query engine. If the Search index does not exist, an error occurs. You can also provide an index hint to the Query engine with the [USE INDEX clause](n1ql-language-reference/hints.adoc#use-index-clause). This takes precedence over a hint provided by the `index` field. |

  ---

  The `index` field may also be an object, containing an example of a Search index mapping.
  This is treated as an input to the index mapping.
  It overrides the default mapping and is used during index selection and filtering.

  The object must either have a default mapping with no type mapping, or a single type mapping with the default mapping disabled.
  For more information, refer to [search:customize-index.adoc](search:customize-index.adoc).

  | `indexUUID`
  | string
  | A string, containing the [UUID](search:search-index-params.adoc#uuid) of a Search index in the keyspace.
  This provides an index hint to the Query engine.
  If the Search index cannot be identified, an error occurs.

  You can use the `indexUUID` field alongside the `index` field to help identify a Search index.
  The `indexUUID` field and the `index` field must both identify the same Search index.
  If they identify different Search indexes, or if either of them does not identify a Search index, an error occurs.

  View the UUID for an existing index from the Couchbase Server Web Console by selecting an existing index, and clicking btn:[Edit Index].
  The UUID displays in the Index Definition Preview on the Edit Index page.

  You can also use the [Index Definition](rest-api:rest-fts-indexing.adoc) endpoints provided by the Search REST API.

  | `out`
  | string
  | A name given to this Full Text Search operation in this keyspace.
  You can use this name to refer to this operation using the [SEARCH_META()](#search_metaidentifier) and [SEARCH_SCORE()](#search_scoreidentifier) functions.
  If this field is omitted, the name of this Full Text Search operation defaults to `"out"`.

  | (other)
  | (any)
  | Other fields are ignored by the Query engine and are passed on to the Search engine as options.
  The values of these options may be replaced with {sqlpp} query parameters, such as `"analyzer": $analyzer`.

+
The _options_ argument cannot be replaced by a {sqlpp} query parameter, but it may contain {sqlpp} query parameters.

### Return Value

A boolean, representing whether the search query is found within the input path.

This returns `true` if the search query is found within the input path, or `false` otherwise.

### Limitations

The Query service can select a Search index for efficient search in the following cases:

* If the SEARCH() function is used in a WHERE clause or in an ANSI JOIN.
The SEARCH() function must be on the leftmost (first) JOIN.
It may be on the outer side of a nested-loop JOIN, or either side of a hash JOIN.
RIGHT OUTER JOINs are rewritten as LEFT OUTER JOINs.
* If the SEARCH() function is evaluated on the `true` condition in positive cases: for example, `SEARCH(_field_, _query_, _options_)`, `SEARCH(_field_, _query_, _options_) = true`, `SEARCH(_field_, _query_, _options_) IN [true, true, true]`, or a condition including one of these with `AND` or `OR`.

The Query service cannot select a Search index for efficient search in the following cases:

* If a USE KEYS hint is present; or if the SEARCH() function is used on the inner side of a nested-loop JOIN, a lookup JOIN or lookup NEST, an index JOIN or index NEST, an UNNEST clause, a subquery expression, a subquery result, or a correlated query.
* If the SEARCH() function is evaluated on the `false` condition, or in negative cases: for example, `NOT SEARCH(_field_, _query_, _options_)`, `SEARCH(_field_, _query_, _options_) = false`, `SEARCH(_field_, _query_, _options_) != false`, `SEARCH(_field_, _query_, _options_) IN [false, true, 1, "a"]`, or in a condition using the relation operators `<`, `{lt}=`, `>`, `>=`, `BETWEEN`, `NOT`, `LIKE`, or `NOT LIKE`.

In these cases, the Query service must fetch the documents, and the Search service creates a temporary index in memory to perform the search.
This may affect performance.

If the SEARCH() function is present for a keyspace, no GSI covering scan is possible on that keyspace.
If more than one FTS or GSI index are used in the plan, IntersectScan or Ordered IntersectScan is performed.
To avoid this, use a USE INDEX hint.

Order pushdown is possible only if query ORDER BY has only [SEARCH_SCORE()](#search_scoreidentifier) on the leftmost keyspace.
Offset and Limit pushdown is possible if the query only has a SEARCH() predicate, using a single search index -- no IntersectScan or OrderIntersectScan.
Group aggregates and projection are not pushed.

**📌 NOTE**\
If you do not specify the `index` setting in the options, {sqlpp} automatically selects a qualifying FTS index for the query.
If multiple indexes qualify for the query, {sqlpp} selects the most precise one.

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Search using a query string**

The following queries are equivalent:

**Query**

```sqlpp
SELECT META(t1).id
FROM hotel AS t1
WHERE SEARCH(t1.country, "+United +States");
```

**Query**

```sqlpp
SELECT META(t1).id
FROM hotel AS t1
WHERE SEARCH(t1, "country:\"United States\"");
```

**Results**

```json
[
 {
    "id": "hotel_27826"
  },
  {
    "id": "hotel_12928"
  },
  {
    "id": "hotel_25795"
  },
  {
    "id": "hotel_25507"
  },
  ...
]
```

The results are unordered, so they may be returned in a different order each time.

**Search using a query object**

**Query**

```sqlpp
SELECT t1.name
FROM hotel AS t1
WHERE SEARCH(t1, {
  "match": "bathrobes",
  "field": "reviews.content",
  "analyzer": "standard"
});
```

**Results**

```json
[
  {
    "name": "Typoeth Cottage"
  },
  {
    "name": "Great Orme Lighthouse"
  },
  {
    "name": "New Road Guest House (B&B)"
  },
  ...
]
```

The results are unordered, so they may be returned in a different order each time.

**Search using a complete Full Text Search request**

**Query**

```sqlpp
SELECT t1.name
FROM hotel AS t1
WHERE SEARCH(t1, {
  "explain": false,
  "fields": [
     "*"
   ],
   "highlight": {},
   "query": {
     "match": "bathrobes",
     "field": "reviews.content",
     "analyzer": "standard"
   },
   "size" : 5,
   "sort": [
      {
       "by" : "field",
       "field" : "reviews.ratings.Overall",
       "mode" : "max",
       "missing" : "last"
      }
   ]
});
```

**Results**

```json
[
  {
    "name": "The Aviator Hotel"
  },
  {
    "name": "Premier Inn Birmingham Central East"
  },
  {
    "name": "Castle Hotel"
  },
  {
    "name": "Suites at Fisherman's Wharf"
  },
  {
    "name": "Waunifor"
  }
]
```
This query returns 5 results, and the results are ordered, as specified by the search options.
As an alternative, you could limit the number of results and order them using the {sqlpp} [LIMIT](n1ql-language-reference/limit.adoc) and [ORDER BY](n1ql-language-reference/orderby.adoc) clauses.

**Search against a Full Text Search index that carries a custom type mapping**

Before running the query, create a Search index with a custom type mapping using the following definition:

```json
{
  "name": "travel-sample-hotels",
  "type": "fulltext-index",
  "params": {
    "doc_config": {
      "mode": "type_field",
      "type_field": "type"
    },
    "mapping": {
      "default_analyzer": "standard",
      "default_datetime_parser": "dateTimeOptional",
      "default_field": "_all",
      "default_mapping": {
        "dynamic": true,
        "enabled": false
      },
      "default_type": "_default",
      "index_dynamic": true,
      "store_dynamic": true,
      "type_field": "type",
      "types": {
        "hotel": {
          "dynamic": true,
          "enabled": true
        }
      }
    },
    "store": {
      "indexType": "scorch",
      "segmentVersion": 15
    }
  },
  "sourceType": "gocbcore",
  "sourceName": "travel-sample",
  "sourceUUID": "",
  "sourceParams": {},
  "planParams": {
    "indexPartitions": 1
  },
  "uuid": ""
}
```

**Query**

```sqlpp
SELECT META(t1).id
FROM hotel AS t1
WHERE t1.type = "hotel" AND SEARCH(t1.description, "amazing");
```

**Results**

```json
[
  {
    "id": "hotel_20422"
  },
  {
    "id": "hotel_22096"
  },
  {
    "id": "hotel_25243"
  },
  {
    "id": "hotel_27741"
  }
]
```
If the Full Text Search index being queried has its default mapping disabled and has a custom type mapping defined, the query needs to specify the type explicitly.

For more information about defining custom type mappings within a Search index, refer to [Create a Type Mapping](search:create-type-mapping.adoc).
Note that for {sqlpp} queries, only Search indexes with one type mapping are searchable.
Also the supported type identifiers at the moment are "type_field" and "docid_prefix"; "docid_regexp" isn’t supported yet for SEARCH queries via {sqlpp}.

**Search against a Vector Search index for the closest 2 vectors**

**📌 NOTE**\
This example does not use the travel sample data or query context mentioned before, as it requires documents that contain vector data.

**Query**

```sqlpp
SELECT t1.color
FROM rgb AS t1
WHERE SEARCH(t1,
  {
    "fields": ["*"],
    "knn": [
      {
        "k": 2,
        "field": "colorvect_dot",
        "vector": [ 0.707106781186548, 0, 0.707106781186548 ]
      }
    ]
  }
)
```

**Results**

```
[
  {
    "color": "magenta / fuchsia"
  },
  {
    "color": "dark lavender"
  }
]
```
Using a Search index that contains vectors that describe colors, the query returns the color names of the closest `k` vectors to the vector in the `knn` object.

For more information about Vector Search and the Search Services, see [vector-search:vector-search.adoc](vector-search:vector-search.adoc).

**Search with XATTRs data and no suitable Search index**

If there is no suitable Search index, but you want to return XATTRs data from your documents in another part of your {sqlpp} query, you must use the [META function](n1ql-language-reference/metafun.adoc#meta) to select the XATTRs field you want to return.
{sqlpp} cannot return XATTRs data without a specific field name in your `SEARCH` function.

Add `_$xattrs` with a period (.) to the start of the field name you want to return in the `SEARCH` function.

**📌 NOTE**\
Documents in the `travel-sample` do not include any XATTRs data.
You can add XATTRs to the `travel-sample` documents yourself to use with these queries.

**Query**

```sqlpp
SELECT META().xattrs.field
FROM `travel-sample` T
WHERE SEARCH(T, "_$xattrs.field:*");
```

**Results**

```
[
  {
    "field": "field data"
  }
]
```

**Search with XATTRs data and a specific Search index**

If you have a Search index available for your query that includes XATTRs data, and you still want to use that data outside of the SEARCH function, you must use the [SEARCH_META() function](#search_metaidentifier) to select the XATTRs field.
You must also include the [fields property](search:search-request-params.adoc#fields) with the name of the XATTRs field in your Search request.

Add `_$xattrs` with a period (.) to the start of the field name you want to return in the `SEARCH_META` and `SEARCH` functions.

**📌 NOTE**\
Documents in the `travel-sample` do not include any XATTRs data.
You can add XATTRs to the `travel-sample` documents yourself to use with these queries.

**Query**

```sqlpp
SELECT SMETA().fields.`_$xattrs.field`
FROM `travel-sample` T
LET SMETA = SEARCH_META()
WHERE SEARCH(T,
  { "query": {"query": "_$xattrs.field:*"}, "fields": ["_$xattrs.field"]},
  {"index": "travel-sample._default.xattrsTest"});
```

**Results**

```
[
  {
    "_$xattrs.field": "field data"
  }
]
```

## SEARCH_META([`identifier`])

### Description

This function is intended to be used in a query which contains a [SEARCH()](#searchidentifier-query-options) function.
It returns the metadata given by the Search engine for each document found by the [SEARCH()](#searchidentifier-query-options) function.
If there is no [SEARCH()](#searchidentifier-query-options) function in the query, or if a Search index was not used to evaluate the search, the function returns MISSING.

If you want to return XATTRs data from a Search index in a <<search,>> function, you must use the `SEARCH_META()` function to select the XATTRs field you want.

### Arguments

* **identifier**\
[Optional] An expression in the form `{startsb}__keyspaceAlias__.{endsb}__outname__`, consisting of the keyspace or keyspace alias in which the Full Text Search operation was performed, followed by the outname of the Full Text Search operation, using dot notation.

* The identifier must contain the keyspace or keyspace alias if there is more than one input source in the FROM clause.
If there is only one input source in the FROM clause, the keyspace or keyspace alias may be omitted.
* The identifier must contain the outname if there is more than one [SEARCH()](#searchidentifier-query-options) function in the query.
If there is only one [SEARCH()](#searchidentifier-query-options) function in the query, the identifier may be omitted altogether.
* The outname is specified by the `out` field within the [SEARCH()](#searchidentifier-query-options) function’s _options_ argument.
If an outname was not specified by the [SEARCH()](#searchidentifier-query-options) function, the outname defaults to `"out"`.
* If the keyspace or keyspace alias contains any characters such as `-`, you must surround that part of the identifier with backticks `{backtick}{backtick}`.

### Return Value

A JSON object containing the metadata returned by the Search engine.
By default, the metadata includes the score and ID of the search result.
It may also include other metadata requested by advanced search options, such as the location of the search terms or an explanation of the search results.

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Select search metadata**

**Query**

```sqlpp
SELECT SEARCH_META() AS meta -- ①
FROM hotel AS t1
WHERE SEARCH(t1, {
  "query": {
    "match": "bathrobes",
    "field": "reviews.content",
    "analyzer": "standard"
  },
  "includeLocations": true
}) -- ②
LIMIT 3;
```

1. There is only one [SEARCH()](#searchidentifier-query-options) function in this query, so the SEARCH_META() function does not need to specify the outname.
2. The Full Text Search specifies that locations should be included in the search result metadata.

**Result**

```json
[
  {
    "meta": {
      "id": "hotel_12068", // ①
      "locations": { // ②
        "reviews.content": {
          "bathrobes": [
            {
              "array_positions": [
                8
              ],
              "end": 664,
              "pos": 122,
              "start": 655
            }
          ]
        }
      },
      "score": 0.3471730605306995 // ③
    }
  },
  ...
]
```

1. The id is included in the search result metadata by default.
2. The location of the search term is included in the search result metadata as requested.
3. The score is included in the search result metadata by default.

**Select the search metadata by outname**

**Query**

```sqlpp
SELECT t1.name, SEARCH_META(s1) AS meta -- ①
FROM hotel AS t1
WHERE SEARCH(t1.description, "mountain", {"out": "s1"}) -- ②
AND SEARCH(t1, {
  "query": {
    "match": "bathrobes",
    "field": "reviews.content",
    "analyzer": "standard"
  }
});
```

1. This query contains two [SEARCH()](#searchidentifier-query-options) functions.
The outname indicates which metadata we want.
2. The outname is set by the _options_ argument in this [SEARCH()](#searchidentifier-query-options) function.
This query only uses one data source, so there is no need to specify the keyspace.

**Results**

```json
[{
    "name": "Marina del Rey Marriott",
    "meta": {
        "id": "hotel_17598",
        "score": 2.1256278997816835
    }
}]
```

## SEARCH_SCORE([`identifier`])

### Description

This function is intended to be used in a query which contains a [SEARCH()](#searchidentifier-query-options) function.
It returns the score given by the Search engine for each document found by the [SEARCH()](#searchidentifier-query-options) function.
If there is no [SEARCH()](#searchidentifier-query-options) function in the query, or if a Search index was not used to evaluate the search, the function returns MISSING.

This function is the same as [SEARCH_META().score](#search_metaidentifier).

### Arguments

* **identifier**\
[Optional] An expression in the form `{startsb}__keyspaceAlias__.{endsb}__outname__`, consisting of the keyspace or keyspace alias in which the Full Text Search operation was performed, followed by the outname of the Full Text Search operation, using dot notation.

* The identifier must contain the keyspace or keyspace alias if there is more than one input source in the FROM clause.
If there is only one input source in the FROM clause, the keyspace or keyspace alias may be omitted.
* The identifier must contain the outname if there is more than one [SEARCH()](#searchidentifier-query-options) function in the query.
If there is only one [SEARCH()](#searchidentifier-query-options) function in the query, the identifier may be omitted altogether.
* The outname is specified by the `out` field within the [SEARCH()](#searchidentifier-query-options) function’s _options_ argument.
If an outname was not specified by the [SEARCH()](#searchidentifier-query-options) function, the outname defaults to `"out"`.
* If the keyspace or keyspace alias contains any characters such as `-`, you must surround that part of the identifier with backticks `{backtick}{backtick}`.

### Return Value
A number reflecting the score of the result.

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Select the search score**

```sqlpp
SELECT name, description, SEARCH_SCORE() AS score -- ①
FROM hotel AS t1
WHERE SEARCH(t1.description, "mountain")
ORDER BY score DESC
LIMIT 3;
```

1. There is only one [SEARCH()](#searchidentifier-query-options) function in this query, so the SEARCH_SCORE() function does not need to specify the outname.

**Results**

```json
[{
        "name": "Marina del Rey Marriott",
        "description": "370 guest rooms
            offering both water and mountain view.",
        "score": 2.1256278997816835
    },
    {
        "name": "Clwydian Holidays",
        "description": "Log cabin glamping
            in a rural setting with panoramic views
            toward the Clwydian Mountain Range.",
        "score": 1.6956645086702617
    },
    {
        "name": "The Royal Victoria Hotel",
        "description": "3 Star Hotel next to
          the Mountain Railway terminus
          and set in 30 acres of grounds
          which include Dolbadarn Castle",
        "score": 1.5030458987111712
    }
]
```

## Related Links

* [search:search.adoc](search:search.adoc)
* [rest-api:rest-fts.adoc](rest-api:rest-fts.adoc)
* [vector-search:vector-search.adoc](vector-search:vector-search.adoc)
