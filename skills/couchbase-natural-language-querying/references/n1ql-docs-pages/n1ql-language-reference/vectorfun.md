# Vector Functions

Vector functions enable you to work with vector values.

Vector functions include similarity functions to find the distance between two vectors, functions that check for a vector value, and functions that modify vector values.

For more information about vectors and vector indexes, see [vector-index:vectors-and-indexes-overview.adoc](vector-index:vectors-and-indexes-overview.adoc).

## APPROX_VECTOR_DISTANCE(`vec`, `queryvec`, `metric` [,&#160;``nprobes`` [,&#160;``rerank`` [,&#160;``topNScan``]]])

This function has an alias [ANN_DISTANCE()](#aliases).

### Description

Finds the approximate distance between a provided vector and the content of a specified field that contains vector embeddings.

This function works best with a Hyperscale Vector index or Composite Vector index.
If a query contains this function, and all of the following are true:

* The cluster has a Hyperscale Vector index or a Composite Vector index with a vector index key which is the same as the vector field referenced by the function
* The vector index key uses a similarity setting which is the same as the distance metric referenced by the function
* The vector index key has the same dimension as the vector provided by the function

... then the Query optimizer selects that Hyperscale Vector index or Composite Vector index for use with the query containing this function.

This function is faster, but less precise than [VECTOR_DISTANCE()](#vector_distancevec-queryvec-metric).
You should use this function in your production queries.

### Arguments

* **vec**\
The name of a field that contains vector embeddings.
The field must contain an array of floating point numbers, or a base64 encoded string.
* **queryvec**\
An array of floating point numbers, or a base64 encoded string, representing the vector value to search for in the vector field.
* **metric**\
A string representing the distance metric to use when comparing the vectors.
To select a Hyperscale Vector index or Composite Vector index for the query, the distance metric should match the `similarity` setting that you used when you created the index.

  COSINE;; [Cosine Similarity](vector-index:vectors-and-indexes-overview.adoc#cosine)
  DOT;; [Dot Product](vector-index:vectors-and-indexes-overview.adoc#dot)
  L2;;
  EUCLIDEAN;; [Euclidean Distance](vector-index:vectors-and-indexes-overview.adoc#euclidean)
  L2_SQUARED;;
  EUCLIDEAN_SQUARED;; [Euclidean Squared Distance](vector-index:vectors-and-indexes-overview.adoc#euclidean-squared)
* **nprobes**\
[Optional] An integer representing the number of centroids to probe for matching vectors.
If the Query Service selects a Hyperscale Vector index or Composite Vector index for the query, this option defaults to the `scan_nprobes` setting that you used when you created the index.
If an invalid value is provided, defaults to `1`.
* **rerank**\
[Optional; can only be used when `nprobes` is specified]
A Boolean.
If `false`, the function uses quantized vectors.
If `true`, the function uses full vectors to reorder the results.
The default is `false`.
* **topNScan**\
[Optional; can only be used when `nprobes` and `rerank` are specified]
This option only applies if using a Hyperscale Vector index.
A positive integer representing the number of records to scan.
The default is `0`, meaning the function uses the indexer default.

### Return Value

Returns a numeric value representing the approximate vector distance.

### Examples

To try the examples in this section, you must do the following:

* Install the `rgb` and `rgb-questions` collections from the supplied vector sample, as described in [Prerequisites](vector-index:hyperscale-vector-index.adoc#prerequisites).
* Create a Composite Vector index in the `rbg` collection on the field named `colorvect_l2`, as described in [CREATE INDEX Example 6](n1ql:n1ql-language-reference/createindex.adoc#ex-create-rgb-idx).
* Create a Hyperscale Vector index in the `rbg` collection on the field named `embedding-vector-dot`, as described in [CREATE VECTOR INDEX Example 1](n1ql:n1ql-language-reference/createvectorindex.adoc#ex-create-rgb-idx).

<a name="approx_vector_distance_ex_simple"></a>**APPROX_VECTOR_DISTANCE() Example 1**

This example finds the approximate vector distance between a query vector and three different embedded vectors.

**Query**

```sqlpp
WITH data AS ([
  {"vector": [1, 2, 3, 4], "similarity": "identical"},
  {"vector": [1, 2, 3, 5], "similarity": "close"},
  {"vector": [6, 7, 8, 9], "similarity": "distant"}
])
SELECT
  similarity,
  APPROX_VECTOR_DISTANCE(vector, [1, 2, 3, 4], "COSINE") AS cosine,
  APPROX_VECTOR_DISTANCE(vector, [1, 2, 3, 4], "DOT") AS dot,
  APPROX_VECTOR_DISTANCE(vector, [1, 2, 3, 4], "L2") AS l2,
  APPROX_VECTOR_DISTANCE(vector, [1, 2, 3, 4], "L2_SQUARED") AS l2_squared
FROM data;
```

The results show how the distance changes as the similarity decreases.

**Results**

```json
[
    {
        "similarity": "identical",
        "cosine": 0,
        "dot": -30,
        "l2": 0,
        "l2_squared": 0
    },
    {
        "similarity": "close",
        "cosine": 0.00600091145203363,
        "dot": -34,
        "l2": 1,
        "l2_squared": 1
    },
    {
        "similarity": "distant",
        "cosine": 0.0369131753138463,
        "dot": -80,
        "l2": 10,
        "l2_squared": 100
    }
]
```

Compare this with the result of [VECTOR_DISTANCE() Example 1](#vector_distance_ex_simple).
In this case, the results are identical because the query is not using a Hyperscale Vector index or Composite Vector index.

<a name="approx_vector_distance_ex_rbg"></a>**APPROX_VECTOR_DISTANCE() Example 2**

This example finds the colors from the `rgb` collection that are similar to gray, which has an RGB value of `[128, 128, 128]`.

**Query**

```sqlpp
SELECT b.color, b.colorvect_l2, b.brightness from `rgb` AS b
ORDER BY APPROX_VECTOR_DISTANCE(b.colorvect_l2,[128,128,128],"L2") 
LIMIT 5;
```

The top result is the entry for gray.
The other results are all shades of gray:

**Results**

```json
[
    {
        "color": "grey",
        "colorvect_l2": [
            128,
            128,
            128
        ],
        "brightness": 128
    },
    {
        "color": "slate gray",
        "colorvect_l2": [
            112,
            128,
            144
        ],
        "brightness": 125.04
    },
    {
        "color": "light slate gray",
        "colorvect_l2": [
            119,
            136,
            153
        ],
        "brightness": 132.855
    },
    {
        "color": "light gray",
        "colorvect_l2": [
            144,
            144,
            144
        ],
        "brightness": 144
    },
    {
        "color": "dim gray",
        "colorvect_l2": [
            105,
            105,
            105
        ],
        "brightness": 105
    }
]
```

<a name="approx_vector_distance_ex_embedded"></a>**APPROX_VECTOR_DISTANCE() Example 3**

This example compares embedded vector values.
The query finds the colors from the `rgb` collection whose descriptions are most similar to the following presupplied question:

> What is the color that is often linked to feelings of peace and tranquility, and is reminiscent of the clear sky on a calm day?

**Query**

```sqlpp
WITH question_vec AS (
        SELECT RAW couchbase_search_query.knn[0].vector 
        FROM `vector-sample`.`color`.`rgb-questions` 
        WHERE meta().id = "#87CEEB"
    ), 
colors AS (
    SELECT b.color
    FROM `vector-sample`.`color`.`rgb` AS b
    ORDER BY VECTOR_DISTANCE(b.embedding_vector_dot, question_vec[0], "l2")
    LIMIT 10 )
SELECT RAW colors;
```

1. The `vector` field in the `rgb-questions` collection contains the embedded vectors associated with the presupplied questions. @/couchbase_search_query.knn/
2. The `embedding_vector_dot` field in the `rgb` collection contains the embedded vectors associated with the color descriptions. @/embedding_vector_dot/

The query returns 10 colors where the embedded vector associated with the color description is most similar to the embedded vector associated with the presupplied question.

**Results**

```json
[
    [{
            "color": "deep sky blue"
        },
        {
            "color": "sky blue"
        },
        {
            "color": "light sky blue"
        },
        {
            "color": "pale turquoise"
        },
        {
            "color": "blue"
        },
        {
            "color": "slate blue"
        },
        {
            "color": "light cyan"
        },
        {
            "color": "cadet blue"
        },
        {
            "color": "light blue"
        },
        {
            "color": "medium blue"
        }
    ]
]
```

Compare this with the result of [VECTOR_DISTANCE() Example 2](#vector_distance_ex_embedded).
In this case, the approximate vector distance does not give accurate results.

<a name="approx_vector_distance_ex_nprobe"></a>**APPROX_VECTOR_DISTANCE() Example 4**

This example improves on [APPROX_VECTOR_DISTANCE() Example 3](#approx_vector_distance_ex_embedded) by increasing the number of centroids to probe.

**Query**

```sqlpp
WITH question_vec AS (
        SELECT RAW couchbase_search_query.knn[0].vector 
        FROM `vector-sample`.`color`.`rgb-questions` 
        WHERE meta().id = "#87CEEB"
    ), 
colors AS (
    SELECT b.color
    FROM `vector-sample`.`color`.`rgb` AS b
    ORDER BY APPROX_VECTOR_DISTANCE(b.embedding_vector_dot, question_vec[0], "l2", 4)
    LIMIT 10 )
SELECT RAW colors;
```

**Results**

```json
[
    [{
            "color": "deep sky blue"
        },
        {
            "color": "sky blue"
        },
        {
            "color": "light sky blue"
        },
        {
            "color": "pale turquoise"
        },
        {
            "color": "light cyan"
        },
        {
            "color": "slate blue"
        },
        {
            "color": "blue"
        },
        {
            "color": "cadet blue"
        },
        {
            "color": "light blue"
        },
        {
            "color": "medium blue"
        }
    ]
]
```

Compare this with the result of [VECTOR_DISTANCE() Example 2](#vector_distance_ex_embedded).
The approximate vector distance now gives much more accurate results.

<a name="approx_vector_distance_ex_rerank"></a>**APPROX_VECTOR_DISTANCE() Example 5**

This example is similar to [APPROX_VECTOR_DISTANCE() Example 4](#approx_vector_distance_ex_nprobe), but also uses reranking to improve its accuracy.
The query finds colors from the `rgb` collection whose descriptions are most similar to the following presupplied question:

> What is a soft and gentle hue that can add warmth and brightness to a room?

**Query**

```sqlpp
WITH question_vec AS (
        SELECT RAW couchbase_search_query.knn[0].vector  
        FROM `vector-sample`.`color`.`rgb-questions` 
        WHERE meta().id = "#FFFFE0")
    SELECT b.color, b.description, b.id
    FROM `vector-sample`.`color`.`rgb` AS b
    ORDER BY APPROX_VECTOR_DISTANCE(b.embedding_vector_dot, question_vec[0], "l2", 4, TRUE)
    LIMIT 3;
```

1. The `vector` field in the `rgb-questions` collection contains the embedded vectors associated with the presupplied questions. @/couchbase_search_query.knn/
2. The `embedding_vector_dot` field in the `rgb` collection contains the embedded vectors associated with the color descriptions. @/embedding_vector_dot/

The query returns 3 colors where the embedded vector associated with the color description is most similar to the embedded vector associated with the presupplied question.

**Results**

```json
[{
        "color": "peach",
        "description": "Peach is a soft and warm color that can enliven any space. It has 
                       a delicate and gentle quality, like the softness of a peach's skin. 
                       This color can soften the harshness of other colors and bring a sense 
                       of warmth and comfort. It is a versatile color that can be both calming 
                       and invigorating, making it a popular choice in interior design. Peach 
                       is a color that evokes feelings of happiness and positivity, making it 
                       a perfect addition to any room.",
        "id": "#FF8C3C"
    },
    {
        "color": "light yellow",
        "description": "Light yellow is a delicate and gentle color that can soften the overall 
                       tone of a room. It has a bright and cheerful quality that can brighten up 
                       any space. This color also has the ability to illuminate a room, making it 
                       feel more open and airy. Light yellow is a perfect choice for creating a 
                       warm and inviting atmosphere.",
        "id": "#FFFFE0"
    },
    {
        "color": "apricot",
        "description": "Apricot is a warm and inviting color, reminiscent of the soft glow of a 
                       sunset. It has the ability to soften the harshness of other colors and 
                       enliven any space it is used in. It is a delicate and soothing hue, perfect 
                       for creating a cozy and welcoming atmosphere.",
        "id": "#FB8737"
    }
]
```

For more information and examples, see [vector-index:hyperscale-reranking.adoc](vector-index:hyperscale-reranking.adoc).

## DECODE_VECTOR(`vector` [,&#160;``byte_order``])

This function has an alias [VECTOR_DECODE()](#aliases).

### Description

Reverses the encoding done by the [ENCODE_VECTOR()](#encode_vectorvector-160byte_order) function.

### Arguments

* **vector**\
String, or any {sqlpp} expression that evaluates to a string, representing the base64 encoding of a vector value.
* **byte_order**\
[Optional] A boolean which determines the byte order of the vector value.
If `true`, it’s big-endian.
If `false`, it’s little-endian.
The default is `false`.

### Return Value

An array of floating point numbers.

### Example

<a name="decode_vector_ex"></a>**DECODE_VECTOR() Example**

The following query decodes the base64 encoding of a vector value using two different byte orders.

**Query**

```sqlpp
SELECT DECODE_VECTOR("AACAPwAAAEAAAEBAAACAQA==") AS little_endian,
       DECODE_VECTOR("P4AAAEAAAABAQAAAQIAAAA==", true) AS big_endian;
```

**Results**

```json
[
  {
    "little_endian": [
      1,
      2,
      3,
      4
    ],
    "big_endian": [
      1,
      2,
      3,
      4
    ]
  }
]
```

## ENCODE_VECTOR(`vector` [,&#160;``byte_order``])

This function has an alias [VECTOR_ENCODE()](#aliases).

### Description

Returns the [base64](https://en.wikipedia.org/wiki/Base64) encoding of a vector value.

### Arguments

* **vector**\
An array of floating point numbers, or any {sqlpp} expression that evaluates to an array of floating point numbers.
* **byte_order**\
[Optional] A boolean which determines the byte order of the vector value.
If `true`, it’s big-endian.
If `false`, it’s little-endian.
The default is `false`.

### Return Value

A string representing the base64 encoding of the input expression.

### Example

<a name="encode_vector_ex"></a>**ENCODE_VECTOR() Example**

The following query encodes an array of floating point numbers using two different byte orders.

**Query**

```sqlpp
SELECT ENCODE_VECTOR([1, 2, 3, 4]) AS little_endian,
       ENCODE_VECTOR([1, 2, 3, 4], true) AS big_endian;
```

**Results**

```json
[
  {
    "little_endian": "AACAPwAAAEAAAEBAAACAQA==",
    "big_endian": "P4AAAEAAAABAQAAAQIAAAA=="
  }
]
```

## ISVECTOR(`vector`, `dimension`, `format`)

### Description

Checks if the supplied expression is an array of floating point numbers with the specified number of dimensions.
This can be used to determine whether a field contains a vector value.

### Arguments

* **vector**\
 An array of floating point numbers, or any {sqlpp} expression that evaluates to an array of floating point numbers.
* **dimension**\
An integer representing the number of dimensions.
* **format**\
A string.
This argument must always be present and must have the value `"float32"`.

### Return Value

Returns `true` if the expression is an array of floating point numbers with the specified number of dimensions.

### Examples

To try the examples in this section, you must install the `rgb` and `rgb-questions` collections from the supplied vector sample, as described in [Prerequisites](vector-index:hyperscale-vector-index.adoc#prerequisites).

<a name="isvector_ex_simple"></a>**ISVECTOR() Example 1**

**Query**

```sqlpp
SELECT ISVECTOR([1, 2, 3, 4], 4, "float32") as vector,
       ISVECTOR([1, 2, 3, 4], 3, "float32") as wrong_dimension,
       ISVECTOR(["a", "b", "c", "d"], 4, "float32") as wrong_values;
```

**Results**

```json
[
  {
    "vector": true,
    "wrong_dimension": false,
    "wrong_values": false
  }
]
```

<a name="isvector_ex2"></a>**ISVECTOR() Example 2**

Check whether the specified fields in the `rgb` collection contain vector values.

**Query**

```sqlpp
SELECT ISVECTOR(description, 1, "float32") AS description,
       ISVECTOR(colorvect_l2, 3, "float32") AS colorvect_l2,
       ISVECTOR(embedding_vector_dot, 1536, "float32") AS embedding_vector_dot
FROM `vector-sample`.color.rgb LIMIT 1;
```

**Results**

```json
[{
    "description": false,
    "colorvect_l2": true,
    "embedding_vector_dot": true
}]
```

The results show that the `description` field is not a vector field. The `colorvect_l2` and `embedding_vector_dot` fields are vector fields, with the specified number of dimensions.

## NORMALIZE_VECTOR(`vector`)

This function has aliases [NORMALISE_VECTOR()](#aliases), [VECTOR_NORMALISE()](#aliases), and [VECTOR_NORMALIZE()](#aliases).

### Description

Normalizes a vector.
This function changes the magnitude of a vector, but not its direction, so that the vector has unit length.
This is useful in cases where you only need the direction of the vector, not its magnitude.

To normalize a vector $x$, the function first calculates the length of the vector, $|x|$.
This is the square root of the sum of the squares of each component of the vector.

```math
|x| = sqrt(x_1^2 + x_2^2 + ... + x_n^2)
```

To find the normalized vector, $hat x$, the function then divides each component of the vector by the length of the vector.

```math
hat x = (x_1/|x|, x_2/|x|, ... x_n/|x|)
```

### Arguments

* **vector**\
An array of floating point numbers, or any {sqlpp} expression that evaluates to an array of floating point numbers.

### Return Value

An array of floating point numbers representing the normalized vector.

### Example

<a name="normalize_vector_ex"></a>**NORMALIZE_VECTOR() Example**

The following query normalizes a vector.

**Query**

```sqlpp
SELECT NORMALIZE_VECTOR([1, 2, 3, 4]) AS normalized;
```

**Results**

```json
[{
    "normalized": [
        0.18257418583505536,
        0.3651483716701107,
        0.5477225575051661,
        0.7302967433402214
    ]
}]
```

## VECTOR_DISTANCE(`vec`, `queryvec`, `metric`)

This function has an alias [KNN_DISTANCE()](#aliases).

### Description

Finds the exact distance between a provided vector and the content of a specified field that contains vector embeddings.

This function does not use a Hyperscale Vector index or Composite Vector index to perform the comparison.
Instead, it performs a brute-force search for similar vectors.

This function is slower, but more precise than [APPROX_VECTOR_DISTANCE()](#approx_vector_distancevec-queryvec-metric-160nprobes-160rerank-160topnscan).
You should use this function to check the accuracy of your production queries, and adjust the index and query settings to improve the recall accuracy.

### Arguments

* **vec**\
The name of a field that contains vector embeddings.
The field must contain an array of floating point numbers, or a base64 encoded string.
* **queryvec**\
An array of floating point numbers, or a base64 encoded string, representing the vector value to search for in the vector field.
* **metric**\
A string representing the distance metric to use when comparing the vectors.

  COSINE;; [Cosine Similarity](vector-index:vectors-and-indexes-overview.adoc#cosine)
  DOT;; [Dot Product](vector-index:vectors-and-indexes-overview.adoc#dot)
  L2;;
  EUCLIDEAN;; [Euclidean Distance](vector-index:vectors-and-indexes-overview.adoc#euclidean)
  L2_SQUARED;;
  EUCLIDEAN_SQUARED;; [Euclidean Squared Distance](vector-index:vectors-and-indexes-overview.adoc#euclidean-squared)

### Return Value

Returns a numeric value representing the vector distance.

### Examples

To try the examples in this section, you must install the `rgb` and `rgb-questions` collections from the supplied vector sample, as described in [Prerequisites](vector-index:hyperscale-vector-index.adoc#prerequisites).

<a name="vector_distance_ex_simple"></a>**VECTOR_DISTANCE() Example 1**

The following query finds the exact vector distance between a query vector and three different embedded vectors.

**Query**

```sqlpp
WITH data AS ([
  {"vector": [1, 2, 3, 4], "similarity": "identical"},
  {"vector": [1, 2, 3, 5], "similarity": "close"},
  {"vector": [6, 7, 8, 9], "similarity": "distant"}
])
SELECT
  similarity,
  VECTOR_DISTANCE(vector, [1, 2, 3, 4], "COSINE") AS cosine,
  VECTOR_DISTANCE(vector, [1, 2, 3, 4], "DOT") AS dot,
  VECTOR_DISTANCE(vector, [1, 2, 3, 4], "L2") AS l2,
  VECTOR_DISTANCE(vector, [1, 2, 3, 4], "L2_SQUARED") AS l2_squared
FROM data;
```

The results show how the distance changes as the similarity decreases.

**Results**

```json
[
    {
        "similarity": "identical",
        "cosine": 0,
        "dot": -30,
        "l2": 0,
        "l2_squared": 0
    },
    {
        "similarity": "close",
        "cosine": 0.00600091145203363,
        "dot": -34,
        "l2": 1,
        "l2_squared": 1
    },
    {
        "similarity": "distant",
        "cosine": 0.0369131753138463,
        "dot": -80,
        "l2": 10,
        "l2_squared": 100
    }
]
```

Compare this with the result of [APPROX_VECTOR_DISTANCE() Example 1](#approx_vector_distance_ex_simple).

<a name="vector_distance_ex_embedded"></a>**VECTOR_DISTANCE() Example 2**

This example compares embedded vector values.
The query finds colors from the `rgb` collection whose descriptions are most similar to the following presupplied question:

> What is the color that is often linked to feelings of peace and tranquility, and is reminiscent of the clear sky on a calm day?

**Query**

```sqlpp
WITH question_vec AS (
        SELECT RAW couchbase_search_query.knn[0].vector 
        FROM `vector-sample`.`color`.`rgb-questions` 
        WHERE meta().id = "#87CEEB"
    ), 
colors AS (
    SELECT b.color
    FROM `vector-sample`.`color`.`rgb` AS b
    ORDER BY VECTOR_DISTANCE(b.embedding_vector_dot, question_vec[0], "l2")
    LIMIT 10 )
SELECT RAW colors;
```

1. The `vector` field in the `rgb-questions` collection contains the embedded vectors associated with the presupplied questions. @/couchbase_search_query.knn/
2. The `embedding_vector_dot` field in the `rgb` collection contains the embedded vectors associated with the color descriptions. @/embedding_vector_dot/

The query returns 10 colors where the embedded vector associated with the color description is most similar to the embedded vector associated with the presupplied question.

**Results**

```json
[
    [{
            "color": "deep sky blue"
        },
        {
            "color": "sky blue"
        },
        {
            "color": "light sky blue"
        },
        {
            "color": "pale turquoise"
        },
        {
            "color": "blue"
        },
        {
            "color": "slate blue"
        },
        {
            "color": "light cyan"
        },
        {
            "color": "cadet blue"
        },
        {
            "color": "light blue"
        },
        {
            "color": "medium blue"
        }
    ]
]
```

For more information and examples, see [Determine Recall Rate](vector-index:vector-index-best-practices.adoc#recall-accuracy).

## Aliases

Some vector functions have aliases.

* `ANN_DISTANCE()` is an alias for [APPROX_VECTOR_DISTANCE()](#approx_vector_distancevec-queryvec-metric-160nprobes-160rerank-160topnscan).
* `KNN_DISTANCE()` is an alias for [VECTOR_DISTANCE()](#vector_distancevec-queryvec-metric).
* `NORMALISE_VECTOR()` is an alias for [NORMALIZE_VECTOR()](#normalize_vectorvector).
* `VECTOR_DECODE()` is an alias for [DECODE_VECTOR()](#decode_vectorvector-160byte_order).
* `VECTOR_ENCODE()` is an alias for [ENCODE_VECTOR()](#encode_vectorvector-160byte_order).
* `VECTOR_NORMALISE()` is an alias for [NORMALIZE_VECTOR()](#normalize_vectorvector).
* `VECTOR_NORMALIZE()` is an alias for [NORMALIZE_VECTOR()](#normalize_vectorvector).
