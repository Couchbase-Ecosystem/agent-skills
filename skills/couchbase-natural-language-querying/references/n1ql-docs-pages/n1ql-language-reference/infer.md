# INFER

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

The INFER statement enables you to infer the metadata of documents in a keyspace, for example the structure of documents, data types of various attributes, sample values, and so on.
Since a keyspace can contain documents with varying structures, the INFER statement is statistical in nature rather than deterministic.
You can specify the sample size that must be used to analyze and identify the structure of documents in a keyspace.

**📌 NOTE**\
The `describe` statement introduced in the Couchbase Server 4.1 release has been renamed to INFER.

The Query Workbench in the Couchbase Web console (available under the **Query** tab) uses the INFER statement to display the structure of documents in the [Data Insights](tools:query-workbench.adoc#bucket-analyzer) area when you expand the keyspace name.

## RBAC Privileges

To execute the INFER statement, you must have the _Query Select_ privilege granted on the target keyspace.
For more details about user roles, see
[Authorization](learn:security/authorization-overview.adoc).

For example, to execute [Infer metadata for a keyspace](#ex-1) below, you must have the _Query Select_ privilege on the `route` keyspace.

## Syntax

```ebnf
infer ::= 'INFER' ( 'COLLECTION' | 'KEYSPACE' )? keyspace-ref ( 'WITH' options )?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/infer.png)

The `COLLECTION` or `KEYSPACE` keywords are optional.
These keywords are purely a visual mnemonic;
including either of them makes no difference to the operation of the INFER statement.

* **keyspace-ref**\
[Keyspace Reference](#keyspace-reference) icon:caret-down[]
* **options**\
[Options](#options) icon:caret-down[]

### Keyspace Reference

```ebnf
keyspace-ref ::= keyspace-path | keyspace-partial
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-ref.png)

```ebnf
keyspace-path ::= ( namespace ':' )? bucket ( '.' scope '.' collection )?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-path.png)

```ebnf
keyspace-partial ::= collection
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-partial.png)

The simple name or fully-qualified name of a keyspace.
Refer to the [CREATE INDEX](n1ql-language-reference/createindex.adoc#keyspace-ref) statement for details of the syntax.

### Options

An object with one or more of the following properties to guide the INFER statement.

* **`sample_size`**\
Specifies the number of documents to randomly sample in the keyspace when inferring the schema.
The default sample size is 1000 documents.
If a keyspace contains fewer documents than the specified `sample_size`, then all the documents in the keyspace will be used.
* **`array_sample_size`**\
Specifies the number of array elements to sample when inferring an array attribute.
If set to a non-negative value, the statement trims the array samples to this value when their length exceeds it.
The resulting array includes a `sampleSize` field indicating that this option was applied.
* **`num_sample_values`**\
Specifies the number of sample values for each attributes to be returned.
The sample values provide examples of the data format.
The default value is 5.
* **`similarity_metric`**\
The schema inferencing process groups similar schemas into document flavors.
The `similarity_metric` is the degree of similarity that two schemas must have to be considered part of the same flavor.
You can specify a real number between 0 and 1 indicating the percentage match (of attributes) required to establish similarity between two documents.
The default value is 0.6, which means two documents are considered similar if 60% of the top-level attributes are the same.
* **`max_nesting_depth`**\
Specifies the maximum depth of nested fields to explore during schema inference.
If set to a non-negative value, the statement skips fields that are at a nesting depth greater than or equal to this value.
The resulting field includes a `nestingDepth` property indicating the depth of the field, with `0` indicating a top-level field.

* **`flags`**\
An array of strings representing flags that can control the behavior of the INFER statement.
You can specify one or more of the following flags:

  | Flag | Description |
  | --- | --- |
  | `allow_dups` | Allows including duplicate documents in the infer analysis. When multiple retrieval methods (such as secondary index, primary index, sequential scan, random scan, or random entry provider) are used, this flag prevents deduplication and ensures all retrieved documents are included, even if they share the same key. |
  | `include_xattrs` | Includes schema information for the extended attributes (xattrs) of each document in the output. |
  | `include_key` | Includes schema information for the document keys in the output. If specified, it adds a `~meta` attribute, which contains the `id` property representing the document keys. |
* **`dictionary_threshold`**\
Sometimes JSON documents follow the dictionary pattern, where a field has sub-fields that are key-value pairs, instead of general field-name and value pairs.
For example, consider a sub-document called "ratings", where the name of each rating object is a user ID:

  ```json
     "ratings": {
            "brambliertypo75631": {
              "created": 1439939260000,
              "rating": 1
            },
            "croakerraisiny16166": {
              "created": 1440066307000,
              "rating": 3
            },
            "libidinizeddepleting17126": {
              "created": 1439991036000,
              "rating": 1
            },
            "lightnots66650": {
              "created": 1440204913000,
              "rating": 1
            },
        },
  ```

  While this pattern may not be ideal for a number of reasons, if your data follows this pattern it might seem that the data has a huge number of ‘fields’, since a data value is being used as a field name.
  When the schema inferencing process sees more than `dictionary_threshold` fields with different names, but the same sub-document schema, it collapses them into a single schema field marked as a dictionary.

## Schema Output

The statement returns the output in the [JSON Schema draft](http://json-schema.org/documentation.html) format as specified by [json-schema.org](http://json-schema.org/).
It supports the following data types: array, boolean, null, number, and object.

At the top level, the output contains an array of schemas.
Each schema recursively describes the structure of a flavor of document.
For each identified attribute, the schema may contain the following details:

* **Common Details**\
`#docs`;; Specifies the number of documents in the sample that contain this attribute.
`%docs`;; Specifies the percentage of documents in the sample that contain this attribute.
`samples`;; Contains sample values for the attribute found in the sample population.
`type`;; Specifies specifying the identified data type of the attribute.
* **Details for Array Data Type**\
`items`;; Contains details of the elements in the array.
`minItems`;; Specifies the minimum number of elements (array size).
`maxItems`;; Specifies the maximum number of elements (array size).
* **Details for Object Data Type**\
`properties`;; Contains details of the properties of the object.

  Each property is described by a key-value pair, in which the key is the name of the property, and the value gives recursive details of that property.
* **Details for Documents and Subdocuments**\
`$schema`;; Specifies the version of the JSON Schema standard.
`Flavor`;; Specifies the flavor of a document or sub-document.
* **Details for Document Keys**\
`~meta`;; Contains the `id` property that holds the document keys.

  By default, the INFER statement includes this attribute in the output.
  However, you can control this behavior using the `flags` option in the WITH clause.

  * If you do not use `flags`, INFER automatically includes the `~meta` attribute.
  * If you add any value for `flags`, INFER will not return `~meta` unless you explicitly specify the `include_key` flag.
  For more information about the available flags, see [flags](#infer-flags).
  **📌 NOTE**\
  The `~meta` attribute is only available in Couchbase Server 8.0 and later.

## Examples

<a name="ex-1"></a>**Infer metadata for a keyspace**

For this example, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

```sqlpp
INFER route
WITH {"sample_size": 1000, "num_sample_values": 2, "similarity_metric": 0.1};
```

**Results**

```json
[
    [{
        "#docs": 1000,
        "$schema": "http://json-schema.org/draft-06/schema",
        "Flavor": "`stops` = 0, `type` = \"route\"",
        "properties": {
            "airline": {
                "#docs": 1000,
                "%docs": 100,
                "nestingDepth": 0,
                "samples": [
                    "AS",
                    "DY"
                ],
                "type": "string"
            },
            "airlineid": {
                "#docs": 1000,
                "%docs": 100,
                "nestingDepth": 0,
                "samples": [
                    "airline_3737",
                    "airline_439"
                ],
                "type": "string"
            },
            "destinationairport": {
                "#docs": 1000,
                "%docs": 100,
                "nestingDepth": 0,
                "samples": [
                    "ANC",
                    "PDX"
                ],
                "type": "string"
            },
            "distance": {
                "#docs": 1000,
                "%docs": 100,
                "nestingDepth": 0,
                "samples": [
                    527.1102210477263,
                    787.4315848714039
                ],
                "type": "number"
            },
            "equipment": {
                "#docs": [
                    1,
                    999
                ],
                "%docs": [
                    0.1,
                    99.9
                ],
                "nestingDepth": 0,
                "samples": [
                    [
                        null
                    ],
                    [
                        "DH4",
                        "SF3"
                    ]
                ],
                "type": [
                    "null",
                    "string"
                ]
            },
            "id": {
                "#docs": 1000,
                "%docs": 100,
                "nestingDepth": 0,
                "samples": [
                    11629,
                    12027
                ],
                "type": "number"
            },
            "schedule": {
                "#docs": 1000,
                "%docs": 100,
                "items": {
                    "#docs": 21104,
                    "$schema": "http://json-schema.org/draft-06/schema",
                    "properties": {
                        "day": {
                            "nestingDepth": 2,
                            "type": "number"
                        },
                        "flight": {
                            "nestingDepth": 2,
                            "type": "string"
                        },
                        "utc": {
                            "nestingDepth": 2,
                            "type": "string"
                        }
                    },
                    "type": "object"
                },
                "maxItems": 31,
                "minItems": 9,
                "nestingDepth": 0,
                "sampleSize": 0,
                "samples": [
                    [{
                            "day": 0,
                            "flight": "AS801",
                            "utc": "02:11:00"
                        },
                        {
                            "day": 0,
                            "flight": "AS337",
                            "utc": "22:04:00"
                        },
                        {
                            "day": 0,
                            "flight": "AS194",
                            "utc": "00:57:00"
                        },
                        {
                            "day": 1,
                            "flight": "AS415",
                            "utc": "13:27:00"
                        },
                        {
                            "day": 1,
                            "flight": "AS036",
                            "utc": "08:47:00"
                        },
                        {
                            "day": 1,
                            "flight": "AS787",
                            "utc": "06:06:00"
                        },
                        {
                            "day": 2,
                            "flight": "AS054",
                            "utc": "09:31:00"
                        },
                        {
                            "day": 2,
                            "flight": "AS629",
                            "utc": "11:16:00"
                        },
                        {
                            "day": 3,
                            "flight": "AS662",
                            "utc": "05:27:00"
                        },
                        {
                            "day": 3,
                            "flight": "AS025",
                            "utc": "15:24:00"
                        },
                        {
                            "day": 4,
                            "flight": "AS671",
                            "utc": "09:52:00"
                        },
                        {
                            "day": 4,
                            "flight": "AS391",
                            "utc": "18:28:00"
                        },
                        {
                            "day": 5,
                            "flight": "AS624",
                            "utc": "21:10:00"
                        },
                        {
                            "day": 5,
                            "flight": "AS162",
                            "utc": "14:11:00"
                        },
                        {
                            "day": 6,
                            "flight": "AS547",
                            "utc": "16:24:00"
                        },
                        {
                            "day": 6,
                            "flight": "AS154",
                            "utc": "05:07:00"
                        }
                    ],
                    [{
                            "day": 0,
                            "flight": "AS844",
                            "utc": "23:22:00"
                        },
                        {
                            "day": 0,
                            "flight": "AS611",
                            "utc": "22:13:00"
                        },
                        {
                            "day": 0,
                            "flight": "AS181",
                            "utc": "16:33:00"
                        },
                        {
                            "day": 1,
                            "flight": "AS944",
                            "utc": "16:11:00"
                        },
                        {
                            "day": 2,
                            "flight": "AS855",
                            "utc": "01:18:00"
                        },
                        {
                            "day": 3,
                            "flight": "AS763",
                            "utc": "22:32:00"
                        },
                        {
                            "day": 3,
                            "flight": "AS463",
                            "utc": "21:54:00"
                        },
                        {
                            "day": 3,
                            "flight": "AS010",
                            "utc": "09:15:00"
                        },
                        {
                            "day": 3,
                            "flight": "AS186",
                            "utc": "06:48:00"
                        },
                        {
                            "day": 4,
                            "flight": "AS652",
                            "utc": "18:43:00"
                        },
                        {
                            "day": 5,
                            "flight": "AS204",
                            "utc": "15:30:00"
                        },
                        {
                            "day": 5,
                            "flight": "AS450",
                            "utc": "09:03:00"
                        },
                        {
                            "day": 6,
                            "flight": "AS135",
                            "utc": "04:46:00"
                        },
                        {
                            "day": 6,
                            "flight": "AS673",
                            "utc": "23:17:00"
                        },
                        {
                            "day": 6,
                            "flight": "AS436",
                            "utc": "02:48:00"
                        },
                        {
                            "day": 6,
                            "flight": "AS174",
                            "utc": "03:47:00"
                        }
                    ]
                ],
                "type": "array"
            },
            "sourceairport": {
                "#docs": 1000,
                "%docs": 100,
                "nestingDepth": 0,
                "samples": [
                    "DLG",
                    "STS"
                ],
                "type": "string"
            },
            "stops": {
                "#docs": 1000,
                "%docs": 100,
                "nestingDepth": 0,
                "samples": [
                    0
                ],
                "type": "number"
            },
            "type": {
                "#docs": 1000,
                "%docs": 100,
                "nestingDepth": 0,
                "samples": [
                    "route"
                ],
                "type": "string"
            },
            "~meta": {
                "#docs": 1000,
                "%docs": 100,
                "nestingDepth": 0,
                "properties": {
                    "id": {
                        "#docs": 1000,
                        "%docs": 100,
                        "nestingDepth": 1,
                        "samples": [
                            "route_11629",
                            "route_12027"
                        ],
                        "type": "string"
                    }
                },
                "samples": [{
                        "id": "route_11629"
                    },
                    {
                        "id": "route_12027"
                    }
                ],
                "type": "object"
            }
        },
        "type": "object"
    }]
]
```

<a name="ex-2"></a>**Infer metadata for a keyspace containing multiple document flavors**

For this example, unset the query context.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

```sqlpp
INFER `beer-sample`
WITH {"sample_size": 1500, "num_sample_values": 5, "similarity_metric": 0.0};
```

**Results**

```json
[
  [
    {
      "#docs": 1500,
      "$schema": "http://json-schema.org/draft-06/schema",
      "Flavor": "",
      "properties": {
        "abv": {
          "#docs": 1209,
          "%docs": 80.6,
          "samples": [0, 4, ...],
          "type": "number"
        },
        "address": {
          "#docs": 291,
          "%docs": 19.4,
          "samples": [["1201 First Avenue South"], ...],
          "type": "array"
        },
        "brewery_id": {
          "#docs": 1209,
          "%docs": 80.6,
          "samples": ["boston_beer_company", ...],
          "type": "string"
        },
        "category": {
          "#docs": 914,
          "%docs": 60.93,
          "samples": ["British Ale", ...],
          "type": "string"
        },
        "geo": {
          "#docs": 261,
          "%docs": 17.4,
          "properties": {
            "accuracy": {
              "#docs": 261,
              "%docs": 100,
              "samples": ["APPROXIMATE", ...],
              "type": "string"
            },
            "lat": {
              "#docs": 261,
              "%docs": 100,
              "samples": [8.4841, ...],
              "type": "number"
            },
            "lon": {
              "#docs": 261,
              "%docs": 100,
              "samples": [-122.445, ...],
              "type": "number"
            }
          },
          "type": "object"
        },
        "name": {
          "#docs": 1500,
          "%docs": 100,
          "samples": ["Eldridge, Pope and Co.", ...],
          "type": "string"
        },
        "style": {
          "#docs": 914,
          "%docs": 60.93,
          "samples": ["American-Style Amber/Red Ale", ...],
          "type": "string"
        },
        "type": {
          "#docs": 1500,
          "%docs": 100,
          "samples": ["beer", "brewery"],
          "type": "string"
        },
        "~meta": {
          "#docs": 1500,
          "%docs": 100,
          "properties": {
            "id": {
              "samples": ["eldridge_pope_and_co", ...],
              "type": "string"
            }
          },
          "type": "object"
        },
        ...
      },
      "type": "object"
    }
  ]
]
```

<a name="ex-3"></a>**Infer metadata for a keyspace using flags**

For this example, unset the query context.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).
```sqlpp
INFER `beer-sample`
WITH {"sample_size": 1500, "num_sample_values": 10, "similarity_metric": 0.0,
      "flags": ["allow_dups", "include_xattrs"]};
```
**Results**

```json
[
  [
    {
      "#docs": 1500,
      "$schema": "http://json-schema.org/draft-06/schema",
      "properties": {
        "abv": {
          "#docs": 1199,
          "%docs": 79.93,
          "samples": [0, 3.5, 5, 5.3, 5.5, ...],
          "type": "number"
        },
        "brewery_id": {
          "#docs": 1199,
          "%docs": 79.93,
          "samples": ["anchor_brewing", "brasserie_duyck", ...],
          "type": "string"
        },
        "name": {
          "#docs": 1500,
          "%docs": 100,
          "samples": ["All Saints Belgian Golden Ale", "Cornhusker Lager", ...],
          "type": "string"
        },
        "type": {
          "#docs": 1500,
          "%docs": 100,
          "samples": ["beer", "brewery"],
          "type": "string"
        },
        "xattrs": {
          "#docs": 1500,
          "%docs": 100,
          "samples": [null, null, ...],
          "type": "missing"
        }
      },
      "type": "object"
    }
  ]
]
```
