# Get System Information

<style type="text/css">
  /* No maximum width for table cells */
  .doc table.spread > tbody > tr > *,
  .doc table.stretch > tbody > tr > * {
    max-width: none !important;
  }

  /* Ignore fixed column widths */
  table:not(.fixed-width) col{
    width: auto !important;
  }

  /* Do not hyphenate words in the table */
  td.tableblock p,
  p.tableblock{
    hyphens: manual !important;
  }
</style>

{sqlpp} has a system namespace that stores metadata about data containers, the Query service, and the system as a whole. \

Within the `system` namespace, the following catalogs are provided.
Most catalog names are plural in order to avoid conflicting with {sqlpp} keywords.

|     |
| --- |
| Data Containers |
| Monitoring Catalogs |
| Security Catalogs |
| Other |
| [%hardbreaks] [system:datastores](#query-datastores) [system:namespaces](#query-namespaces) [system:buckets](#query-buckets) [system:scopes](#query-scopes) [system:keyspaces](#query-collections) [system:indexes](#query-indexes) [system:dual](#query-dual) [system:group_info](#query-groups) [system:bucket_info](#query-bucket-information) |
| [%hardbreaks] [system:vitals](n1ql:n1ql-manage/monitoring-n1ql-query.adoc#vitals) [system:active_requests](n1ql:n1ql-manage/monitoring-n1ql-query.adoc#sys-active-req) [system:prepareds](n1ql:n1ql-manage/monitoring-n1ql-query.adoc#sys-prepared) [system:completed_requests](n1ql:n1ql-manage/monitoring-n1ql-query.adoc#sys-completed-req) [system:completed_requests_history](n1ql:n1ql-manage/monitoring-n1ql-query.adoc#sys-history) [system:awr](n1ql:n1ql-manage/query-awr.adoc) |
| [%hardbreaks] [system:my_user_info](#monitor-your-user-info) [system:user_info](#monitor-all-user-info) [system:nodes](#monitor-nodes) [system:applicable_roles](#monitor-applicable-roles) |
| [%hardbreaks] [system:dictionary](#monitor-statistics) [system:dictionary_cache](#monitor-cached-statistics) [system:functions](#monitor-functions) [system:functions_cache](#monitor-cached-functions) [system:tasks_cache](#monitor-cached-tasks) [system:transactions](#monitor-transactions) [system:sequences](#monitor-sequences) [system:all-sequences](#monitor-all-sequences) [system:aus](n1ql:n1ql-language-reference/auto-update-statistics.adoc#system_aus) [system:aus_settings](n1ql:n1ql-language-reference/auto-update-statistics.adoc#system_aus_settings) |

## Authentication and Client Privileges

Client applications must be authenticated with sufficient privileges to access system keyspaces.

* Users must have the **Query System Catalog** role to access restricted system keyspaces.
For more details about user roles, see [Authorization](learn:security/authorization-overview.adoc).
* In addition, users must have permission to access a bucket, scope, or collection to be able to view that item in the system catalog.
Similarly, users must have SELECT permission on the target of an index to be able to view that index in the system catalog.
* The following system keyspaces are considered open, that is, all users can access them without any special privileges:
  * `system:dual`
  * `system:datastores`
  * `system:namespaces`

## Query Datastores

You can query datastores using the `system:datastores` keyspace as follows:

```sqlpp
SELECT * FROM system:datastores
```

This catalog contains the following attributes:

| Name | Description | Schema |
| --- | --- | --- |
| ***id***<br> __required__ | ID of the datastore. | String |
| ***url***<br> __required__ | URL of the datastore instance. | String |

## Query Namespaces

You can query namespaces using the `system:namespaces` keyspace as follows:

```sqlpp
SELECT * FROM system:namespaces
```

This catalog contains the following attributes:

| Name | Description | Schema |
| --- | --- | --- |
| ***id***<br> __required__ | ID of the namespace. | String |
| ***name***<br> __required__ | Name of the namespace. | String |
| ***datastore_id***<br> __required__ | ID of the datastore to which the namespace belongs. | String |

## Query Buckets

You can query buckets using the `system:buckets` keyspace as follows:

```sqlpp
SELECT * FROM system:buckets
```

This catalog contains the following attributes:

| Name | Description | Schema |
| --- | --- | --- |
| ***datastore_id***<br> __required__ | ID of the datastore to which the bucket belongs. | String |
| ***name***<br> __required__ | Name of the bucket. | String |
| ***namespace***<br> __required__ | Namespace to which the bucket belongs. | String |
| ***namespace_id***<br> __required__ | ID of the namespace to which the bucket belongs. | String |
| ***path***<br> __required__ | Path of the bucket. | String |

## Query Scopes

You can query scopes using the `system:scopes` keyspace as follows:

```sqlpp
SELECT * FROM system:scopes
```

This catalog contains the following attributes:

| Name | Description | Schema |
| --- | --- | --- |
| ***bucket***<br> __required__ | Bucket to which the scope belongs. | String |
| ***datastore_id***<br> __required__ | ID of the datastore to which the scope belongs. | String |
| ***name***<br> __required__ | Name of the scope. | String |
| ***namespace***<br> __required__ | Namespace to which the scope belongs. | String |
| ***namespace_id***<br> __required__ | ID of the namespace to which the scope belongs. | String |
| ***path***<br> __required__ | Path of the scope. | String |

**📌 NOTE**\
Querying `system:scopes` only returns named scopes -- that is, non-default scopes.
To return all scopes, including the default scopes, you can query `system:all_scopes`.

## Query Collections

You can query collections using the `system:keyspaces` keyspace as follows:

```sqlpp
SELECT * FROM system:keyspaces
```

This catalog contains the following attributes:

| Name | Description | Schema |
| --- | --- | --- |
| ***bucket***<br> __optional__ | For a named, non-default collection: Bucket to which the keyspace belongs. | String |
| ***datastore_id***<br> __required__ | ID of the datastore to which the keyspace belongs. | String |
| ***id***<br> __required__ | For the default collection in the default scope: ID of the bucket to which the keyspace belongs. ''' For a named, non-default collection: ID of the keyspace. | String |
| ***name***<br> __required__ | For the default collection in the default scope: Bucket to which the keyspace belongs. ''' For a named, non-default collection: Name of the keyspace. | String |
| ***namespace***<br> __required__ | Namespace to which the keyspace belongs. | String |
| ***namespace_id***<br> __required__ | ID of the namespace to which the keyspace belongs. | String |
| ***path***<br> __required__ | Path of the keyspace. | String |
| ***scope***<br> __optional__ | For a named, non-default collection: Scope to which the keyspace belongs. | String |

**📌 NOTE**\
Querying `system:keyspaces` only returns non-system keyspaces.
To return all keyspaces, including the system keyspaces, you can query `system:all_keyspaces`.

## Query Indexes

You can query indexes using the `system:indexes` keyspace as follows:

```sqlpp
SELECT * FROM system:indexes
```

This catalog contains the following attributes:

| Name | Description | Schema |
| --- | --- | --- |
| ***bucket_id***<br> __optional__ | For an index on a named, non-default collection: ID of the bucket to which the index belongs. | String |
| ***condition***<br> __optional__ | Index filter, if present. | String |
| ***datastore_id***<br> __required__ | ID of the datastore to which the index belongs. | String |
| ***id***<br> __required__ | ID of the index. | String |
| ***index_key***<br> __required__ | List of index keys. | String array |
| ***is_primary***<br> __required__ | True if the index is a primary index. | Boolean |
| ***keyspace_id***<br> __required__ | For an index on the default collection in the default scope: ID of the bucket to which the index belongs. ''' For an index on a named, non-default collection: ID of the keyspace to which the index belongs. | String |
| ***name***<br> __required__ | Name of the index. | String |
| ***metadata***<br> __required__ | Metadata for the index. | [Metadata](#metadata) object |
| ***namespace_id***<br> __required__ | ID of the namespace to which the index belongs. | String |
| ***state***<br> __required__ | State of index. **Example**: `online` | String |
| ***using***<br> __required__ | Type of index. **Example**: `gsi` | String |

<a name="metadata"></a>***Metadata***
| Name | Description | Schema |
| --- | --- | --- |
| ***last_scan_time***<br> __required__ | The last scan timestamp of the index. | String |
| ***num_replica***<br> __required__ | The index replica count. | String |
| ***stats***<br> __required__ | Statistics for the index. | [Stats](#stats) object |

<a name="stats"></a>***Stats***
| Name | Description | Schema |
| --- | --- | --- |
| ***last_known_scan_time***<br> __required__ | The index last scan time from the indexer, in UNIX Epoch format. | Number |

**📌 NOTE**\
Querying `system:indexes` only returns indexes on non-system keyspaces.
To return all indexes, including indexes on system keyspaces, you can query `system:all_indexes`.

## Query Dual

You can use dual to evaluate constant expressions.

```sqlpp
SELECT 2+5 FROM system:dual
```

The query returns the result of the expression, 7 in this case.

## Query Groups

You can query group information using the `system:group_info` keyspace as follows:

```sqlpp
SELECT * FROM system:group_info;
```

This catalog contains the following attributes:

| Name | Description | Schema |
| --- | --- | --- |
| ***description***<br> __required__ | User-defined description associated with the group. | String |
| ***id***<br> __required__ | ID of the group. | String |
| ***ldap_group_ref***<br> __optional__ | LDAP mapping associated with the group. | String |
| ***roles***<br> __required__ | List of RBAC roles for the group. | Array of [roles](#roles) objects |

<a name="roles"></a>***Roles***
| Name | Description | Schema |
| --- | --- | --- |
| ***bucket_name***<br> __optional__ | Name of the bucket to which the role applies. | String |
| ***collection_name***<br> __optional__ | Name of the collection to which the role applies. | String |
| ***role***<br> __required__ | Specifies the RBAC role. | String |
| ***scope_name***<br> __optional__ | Name of the scope to which the role applies. | String |

## Query Bucket Information

The `system:bucket_info` (alias: `system:database_info`) keyspace provides comprehensive information about all buckets, including their metadata, configuration settings, memory usage, and other details.

You can query the keyspace as follows:

```sqlpp
SELECT * FROM system:bucket_info;
```

The query returns the same data as the [pools/default/buckets](server:rest-api:rest-buckets-summary.adoc) REST API.
However, the `vBucketServerMap.vBucketMap` field is returned in a more compact format as a pipe-delimited string, rather than an array of arrays.

## Monitor Your User Info

The `system:my_user_info` catalog maintains a list of all information of your profile.

To see your current information, use:

```sqlpp
SELECT * FROM system:my_user_info;
```

This will result in a list similar to:

```json
[
  {
    "my_user_info": {
      "domain": "local",
      "external_groups": [],
      "groups": [],
      "id": "jane",
      "name": "Jane Doe",
      "password_change_date": "2019-05-07T02:31:53.000Z",
      "roles": [
        {
          "origins": [
            {
              "type": "user"
            }
          ],
          "role": "admin"
        }
      ]
    }
  }
]
```

## Monitor All User Info

The `system:user_info` catalog maintains a list of all current users in your bucket and their information.

To see the list of all current users, use:

```sqlpp
SELECT * FROM system:user_info;
```

This will result in a list similar to:

```json
[
  {
    "user_info": {
      "domain": "local",
      "external_groups": [],
      "groups": [],
      "id": "jane",
      "name": "Jane Doe",
      "password_change_date": "2019-05-07T02:31:53.000Z",
      "roles": [
        {
          "origins": [
            {
              "type": "user"
            }
          ],
          "role": "admin"
        }
      ]
    }
  },
  {
    "user_info": {
      "domain": "ns_server",
      "id": "Administrator",
      "name": "Administrator",
      "roles": [
        {
          "role": "admin"
        }
      ]
    }
  }
]
```

## Monitor Nodes

The `system:nodes` catalog shows the datastore topology information.
This is separate from the Query clustering view, in that Query clustering shows a map of the Query cluster, as provided by the cluster manager, while `system:nodes` shows a view of the nodes and services that make up the actual datastore, which may or may not include Query nodes.

* The dichotomy is important in that Query nodes could be clustered by one entity (e.g. Zookeeper) and be connected to a clustered datastore (e.g. Couchbase) such that each does not have visibility of the other.
* Should {sqlpp} be extended to be able to concurrently connect to multiple datastores, each datastore will report its own topology, so that `system:nodes` offers a complete view of all the storage nodes, whatever those may be.
* The `system:nodes` keyspace provides a way to report services advertised by each node as well as services that are actually running.
This is datastore dependent.
* Query clustering is still reported by the `/admin` endpoints.

To see the list of all current node information, use:

```sqlpp
SELECT * FROM system:nodes;
```

This will result in a list similar to:

```json
[
  {
    "nodes": {
      "name": "127.0.0.1:8091",
      "ports": {
        "cbas": 8095,
        "cbasAdmin": 9110,
        "cbasCc": 9111,
        "cbasSSL": 18095,
        "eventingAdminPort": 8096,
        "eventingSSL": 18096,
        "fts": 8094,
        "ftsSSL": 18094,
        "indexAdmin": 9100,
        "indexHttp": 9102,
        "indexHttps": 19102,
        "indexScan": 9101,
        "indexStreamCatchup": 9104,
        "indexStreamInit": 9103,
        "indexStreamMaint": 9105,
        "kv": 11210,
        "kvSSL": 11207,
        "n1ql": 8093,
        "n1qlSSL": 18093
      },
      "services": [
        "cbas",
        "eventing",
        "fts",
        "index",
        "kv",
        "n1ql"
      ]
    }
  }
]
```

## Monitor Applicable Roles

The `system:applicable_roles` catalog maintains a list of all applicable roles and grantee of each bucket.

To see the list of all current applicable role information, use:

```sqlpp
SELECT * FROM system:applicable_roles;
```

This will result in a list similar to:

```json
[
  {
    "applicable_roles": {
      "grantee": "anil",
      "role": "replication_admin"
    }
  },
  {
    "applicable_roles": {
      "bucket_name": "travel-sample",
      "grantee": "anil",
      "role": "select"
    }
  },
  {
    "applicable_roles": {
      "bucket_name": "*",
      "grantee": "anil",
      "role": "select"
    }
  }
]
```

For more examples, take a look at the blog: [Optimize {sqlpp} performance using request profiling](https://blog.couchbase.com/optimize-n1ql-performance-using-request-profiling/).

## Monitor Statistics

The `system:dictionary` catalog maintains a list of the on-disk optimizer statistics stored in the `_query` collection within the `_system` scope.

If you have multiple query nodes, the data retrieved from this catalog will be the same, regardless of the node on which you run the query.

To see the list of on-disk optimizer statistics, use:

```sqlpp
SELECT * FROM system:dictionary;
```

This will result in a list similar to:

```json
[
  {
    "dictionary": {
      "avgDocKeySize": 12,
      "avgDocSize": 278,
      "bucket": "travel-sample",
      "distributionKeys": [
        "airportname",
        "faa",
        "city"
      ],
      "docCount": 1968,
      "indexes": [
        {
          "indexId": "bc3048e87bf84828",
          "indexName": "def_inventory_airport_primary",
          "indexStats": [
            {
              "avgItemSize": 24,
              "avgPageSize": 11760,
              "numItems": 1968,
              "numPages": 4,
              "resRatio": 1
            }
          ]
        },
        // ...
      ],
      "keyspace": "airport",
      "namespace": "default",
      "scope": "inventory"
    }
  },
  // ...
]
```

This catalog contains an array of dictionaries, one for each keyspace for which optimizer statistics are available.
Each dictionary gives the following information:

| Name | Description | Schema |
| --- | --- | --- |
| ***avgDocKeySize***<br> __required__ | Average doc key size. | Integer |
| ***avgDocSize***<br> __required__ | Average doc size. | Integer |
| ***bucket***<br> __required__ | The bucket for which statistics are available. | String |
| ***keyspace***<br> __required__ | The keyspace for which statistics are available. | String |
| ***namespace***<br> __required__ | The namespace for which statistics are available. | String |
| ***scope***<br> __required__ | The scope for which statistics are available. | String |
| ***distributionKeys***<br> __required__ | Distribution keys for which histograms are available. | String array |
| ***docCount***<br> __required__ | Document count. | Integer |
| ***indexes***<br> __required__ | An array of indexes in this keyspace for which statistics are available. | [Indexes](#indexes) array |
| ***node***<br> __required__ | The query node where this dictionary cache is resident. | String |

<a name="indexes"></a>***Indexes***

| Name | Description | Schema |
| --- | --- | --- |
| ***indexId***<br> __required__ | The index ID. | String |
| ***indexName***<br> __required__ | The index name. | String |
| ***indexStats***<br> __required__ | An array of statistics for each index, with one element for each index partition. | [Index Statistics](#indexStats) array |

<a name="indexStats"></a>***Index Statistics***

| Name | Description | Schema |
| --- | --- | --- |
| ***avgItemSize***<br> __required__ | Average item size. | Integer |
| ***avgPageSize***<br> __required__ | Average page size. | Integer |
| ***numItems***<br> __required__ | Number of items. | Integer |
| ***numPages***<br> __required__ | Number of pages. | Integer |
| ***resRatio***<br> __required__ | Resident ratio. | Integer |

For further details, see [n1ql:n1ql-language-reference/updatestatistics.adoc](n1ql:n1ql-language-reference/updatestatistics.adoc).

## Monitor Cached Statistics

The `system:dictionary_cache` catalog maintains a list of the in-memory cached subset of the optimizer statistics.

If you have multiple query nodes, the data retrieved from this node shows cached optimizer statistics from all nodes.
Individual nodes may have a different subset of cached information.

To see the list of in-memory optimizer statistics, use:

```sqlpp
SELECT * FROM system:dictionary_cache;
```

This will result in a list similar to:

```json
[
  {
    "dictionary_cache": {
      "avgDocKeySize": 12,
      "avgDocSize": 278,
      "bucket": "travel-sample",
      "distributionKeys": [
        "airportname",
        "faa",
        "city"
      ],
      "docCount": 1968,
      "indexes": [
        {
          "indexId": "bc3048e87bf84828",
          "indexName": "def_inventory_airport_primary",
          "indexStats": [
            {
              "avgItemSize": 24,
              "avgPageSize": 11760,
              "numItems": 1968,
              "numPages": 4,
              "resRatio": 1
            }
          ]
        },
        // ...
      ],
      "keyspace": "airport",
      "namespace": "default",
      "node": "172.23.0.3:8091",
      "scope": "inventory"
    }
  },
  // ...
]
```

This catalog contains an array of dictionary caches, one for each keyspace for which optimizer statistics are available.
Each dictionary cache gives the same information as the [system:dictionary](#monitor-statistics) catalog.

For further details, see [n1ql:n1ql-language-reference/updatestatistics.adoc](n1ql:n1ql-language-reference/updatestatistics.adoc).

## Monitor Functions

The `system:functions` catalog maintains a list of all user-defined functions across all nodes.
To see the list of all user-defined functions, use:

```sqlpp
SELECT * FROM system:functions;
```

This will result in a list similar to:

```json
[
  {
    "functions": {
      "definition": {
        "#language": "inline",
        "expression": "(((`fahrenheit` - 32) * 5) / 9)",
        "parameters": [
          "fahrenheit"
        ],
        "text": "((fahrenheit - 32) * 5/9)"
      },
      "identity": {
        "bucket": "travel-sample",
        "name": "celsius",
        "namespace": "default",
        "scope": "inventory",
        "type": "scope"
      }
    }
  },
  {
    "functions": {
      "definition": {
        "#language": "javascript",
        "library": "geohash-js",
        "name": "geohash-js",
        "object": "calculateAdjacent",
        "parameters": [
          "src",
          "dir"
        ]
      },
      "identity": {
        "name": "adjacent",
        "namespace": "default",
        "type": "global"
      }
    }
  },
  // ...
]
```

This catalog contains the following attributes:

| Name | Description | Schema |
| --- | --- | --- |
| ***definition***<br> __required__ | The definition of the function. | [Definition](#definition) object |
| ***identity***<br> __required__ | The identity of the function. | [Identity](#identity) object |

<a name="definition"></a>***Definition***

| Name | Description | Schema |
| --- | --- | --- |
| ***#language***<br> __required__ | The language of the function. **Example**: `inline` | String |
| ***parameters***<br> __required__ | The parameters required by the function. | String array |
| ***expression***<br> __optional__ | For inline functions only: the expression defining the function. | String |
| ***text***<br> __optional__ | For inline functions: the verbatim text of the function. ''' For {sqlpp} managed user-defined functions: the external code defining the function. | String |
| ***library***<br> __optional__ | For external functions only: the library containing the function. | String |
| ***name***<br> __optional__ | For external functions only: the relative name of the library. | String |
| ***object***<br> __optional__ | For external functions only: the object defining the function. | String |

<a name="identity"></a>***Identity***

| Name | Description | Schema |
| --- | --- | --- |
| ***name***<br> __required__ | The name of the function. | String |
| ***namespace***<br> __required__ | The namespace of the function. **Example**: `default` | String |
| ***type***<br> __required__ | The type of the function. **Example**: `global` | String |
| ***bucket***<br> __optional__ | For scoped functions only: the bucket containing the function. | String |
| ***scope***<br> __optional__ | For scoped functions only: the scope containing the function. | String |

## Monitor Cached Functions

The `system:functions_cache` catalog maintains a list of recently-used user-defined functions across all nodes.
The catalog also lists user-defined functions that have been called recently, but do not exist.
To see the list of recently-used user-defined functions, use:

```sqlpp
SELECT * FROM system:functions_cache;
```

This will result in a list similar to:

```json
[
  {
    "functions_cache": {
      "#language": "inline",
      "avgServiceTime": "3.066847ms",
      "expression": "(((`fahrenheit` - 32) * 5) / 9)",
      "lastUse": "2022-03-09 00:17:59.60659793 +0000 UTC m=+35951.429537902",
      "maxServiceTime": "3.066847ms",
      "minServiceTime": "0s",
      "name": "celsius",
      "namespace": "default",
      "node": "127.0.0.1:8091",
      "parameters": [
        "fahrenheit"
      ],
      "scope": "inventory",
      "text": "((fahrenheit - 32) * 5/9)",
      "type": "scope",
      "uses": 1
    }
  },
  {
    "functions_cache": {
      "#language": "javascript",
      "avgServiceTime": "56.892636ms",
      "lastUse": "2022-03-09 00:15:46.289934029 +0000 UTC m=+35818.007560703",
      "library": "geohash-js",
      "maxServiceTime": "146.025426ms",
      "minServiceTime": "0s",
      "name": "geohash-js",
      "namespace": "default",
      "node": "127.0.0.1:8091",
      "object": "calculateAdjacent",
      "parameters": [
        "src",
        "dir"
      ],
      "type": "global",
      "uses": 4
    }
  },
  {
    "functions_cache": {
      "avgServiceTime": "3.057421ms",
      "lastUse": "2022-03-09 00:17:25.396840275 +0000 UTC m=+35917.199008929",
      "maxServiceTime": "3.057421ms",
      "minServiceTime": "0s",
      "name": "notFound",
      "namespace": "default",
      "node": "127.0.0.1:8091",
      "type": "global",
      "undefined_function": true,
      "uses": 1
    }
  }
]
```

This catalog contains the following attributes:

| Name | Description | Schema |
| --- | --- | --- |
| ***#language***<br> __required__ | The language of the function. **Example**: `inline` | String |
| ***name***<br> __required__ | The name of the function. | String |
| ***namespace***<br> __required__ | The namespace of the function. **Example**: `default` | String |
| ***parameters***<br> __required__ | The parameters required by the function. | String array |
| ***type***<br> __required__ | The type of the function. **Example**: `global` | String |
| ***scope***<br> __optional__ | For scoped functions only: the scope containing the function. | String |
| ***expression***<br> __optional__ | For inline functions only: the expression defining the function. | String |
| ***text***<br> __optional__ | For inline functions: the verbatim text of the function. ''' For {sqlpp} managed user-defined functions: the external code defining the function. | String |
| ***library***<br> __optional__ | For external functions only: the library containing the function. | String |
| ***object***<br> __optional__ | For external functions only: the object defining the function. | String |
| ***avgServiceTime***<br> __required__ | The mean service time for the function. | String |
| ***lastUse***<br> __required__ | The date and time when the function was last used. | String |
| ***maxServiceTime***<br> __required__ | The maximum service time for the function. | String |
| ***minServiceTime***<br> __required__ | The minimum service time for the function. | String |
| ***node***<br> __required__ | The query node where the function is cached. | String |
| ***undefined_function***<br> __required__ | Whether the function exists or is undefined. | Boolean |
| ***uses***<br> __required__ | The number of uses of the function. | Number |

Each query node keeps its own cache of recently-used user-defined functions, so you may see the same function listed for multiple nodes.

## Monitor Cached Tasks

The `system:tasks_cache` catalog maintains a list of recently-used scheduled tasks, such as index advisor sessions.
To see the list of recently-used scheduled tasks, use:

```sqlpp
SELECT * FROM system:tasks_cache;
```

This will result in a list similar to:

```json
[
  {
    "tasks_cache": {
      "class": "advisor",
      "delay": "1h0m0s",
      "id": "bcd9f8e4-b324-504c-a98b-ace90dba869f",
      "name": "aa7f688a-bf29-438f-888f-eeaead87ca40",
      "node": "10.143.192.101:8091",
      "state": "scheduled",
      "subClass": "analyze",
      "submitTime": "2019-09-17 05:18:12.903122381 -0700 PDT m=+8460.550715992"
    }
  },
  {
    "tasks_cache": {
      "class": "advisor",
      "delay": "5m0s",
      "id": "254abec5-5782-543e-9ee0-d07da146b94e",
      "name": "ca2cfe56-01fa-4563-8eb0-a753af76d865",
      "node": "10.143.192.101:8091",
      "results": [
        // ...
      ],
      "startTime": "2019-09-17 05:03:31.821597725 -0700 PDT m=+7579.469191487",
      "state": "completed",
      "stopTime": "2019-09-17 05:03:31.963133954 -0700 PDT m=+7579.610727539",
      "subClass": "analyze",
      "submitTime": "2019-09-17 04:58:31.821230131 -0700 PDT m=+7279.468823737"
    }
  }
]
```

This catalog contains the following attributes:

| Name | Description | Schema |
| --- | --- | --- |
| ***class***<br> __required__ | The class of the task. For tasks related to [Auto Update Statistics (AUS)](n1ql:n1ql-language-reference/auto-update-statistics.adoc), the class is `auto_update_statistics`. **Example**: ``advisor`` | string |
| ***delay***<br> __required__ | The scheduled duration of the task. | string |
| ***id***<br> __required__ | The internal ID of the task. | string |
| ***name***<br> __required__ | The name of the task. | string |
| ***node***<br> __required__ | The node where the task was started. | string |

|string

|***subClass***\
__required__
|The subclass of the task.

**Example**: `analyze`
|string

|***submitTime***\
__required__
|The date and time when the task was submitted.
|string

|***results***\
__optional__
|Not scheduled tasks: the results of the task.
|Any array

|***startTime***\
__optional__
|Not scheduled tasks: the date and time when the task started.
|string (date-time)

|***stopTime***\
__optional__
|Not scheduled tasks: the date and time when the task stopped.
|string (date-time)

Refer to [ADVISOR Function](n1ql:n1ql-language-reference/advisor.adoc) for more information on index advisor sessions.

## Monitor Transactions

The `system:transactions` catalog maintains a list of active Couchbase transactions.
To see the list of active transactions, use:

```sqlpp
SELECT * FROM system:transactions;
```

This will result in a list similar to:

```json
[
  {
    "transactions": {
      "durabilityLevel": "majority",
      "durabilityTimeout": "2.5s",
      "expiryTime": "2021-04-21T12:53:48.598+01:00",
      "id": "85aea637-2288-434b-b7c5-413ad8e7c175",
      "isolationLevel": "READ COMMITED",
      "lastUse": "2021-04-21T12:51:48.598+01:00",
      "node": "127.0.0.1:8091",
      "numAtrs": 1024,
      "scanConsistency": "unbounded",
      "status": 0,
      "timeout": "2m0s",
      "usedMemory": 960,
      "uses": 1
    }
  // ...
  }
]
```

This catalog contains the following attributes:

| Name | Description | Schema |
| --- | --- | --- |
| ***durabilityLevel***<br> __required__ | Durability level for all mutations within a transaction. | string |
| ***durabilityTimeout***<br> __required__ | Durability timeout per mutation within the transaction. | string (duration) |
| ***expiryTime***<br> __required__ |  | string (date-time) |
| ***id***<br> __required__ | The transaction ID. | string |
| ***isolationLevel***<br> __required__ | The isolation level of the transaction. | string |
| ***lastUse***<br> __required__ |  | string (date-time) |
| ***node***<br> __required__ | The node where the transaction was started. | string |
| ***numAtrs***<br> __required__ | The total number of active transaction records. | integer |
| ***scanConsistency***<br> __required__ | The transactional scan consistency. | string |
| ***status***<br> __required__ |  | integer |
| ***timeout***<br> __required__ | The transaction timeout duration. | string (duration) |
| ***usedMemory***<br> __required__ |  | integer |
| ***uses***<br> __required__ |  | integer |

Refer to [{sqlpp} Support for Couchbase Transactions](n1ql:n1ql-language-reference/transactions.adoc) for more information.

## Monitor Sequences

The `system:sequences` catalog maintains a list of loaded sequences on any node: that is, sequences that have been accessed since the last restart.
To see the list of loaded sequences, use:

```sqlpp
SELECT * FROM system:sequences;
```

This will result in a list similar to:

```json
[
  {
    "sequences": {
      "bucket": "travel-sample",
      "cache": 50,
      "cycle": false,
      "increment": 1,
      "max": 9223372036854776000,
      "min": -9223372036854776000,
      "name": "seq1",
      "namespace": "default",
      "namespace_id": "default",
      "path": "`default`:`travel-sample`.`inventory`.`seq1`",
      "scope_id": "inventory",
      "value": {
        "73428daec3c68d8632ae66b09b70f14d": null,
        "~next_block": 0
      }
    }
  },
// ...
]
```

This catalog contains the following attributes:

| Name | Description | Schema |
| --- | --- | --- |
| ***bucket***<br> __required__ | The bucket containing the sequence. | string |
| ***cache***<br> __required__ | The sequence’s cache size. | integer |
| ***cycle***<br> __required__ | Whether the sequence is set to cycle. | boolean |
| ***increment***<br> __required__ | The sequence step value. | integer |
| ***min***<br> __required__ | The minimum value permitted for the sequence. | integer |
| ***max***<br> __required__ | The maximum value permitted for the sequence. | integer |
| ***name***<br> __required__ | The name of the sequence. | string |
| ***namespace***<br> __required__ | Namespace to which the sequence belongs. | string |
| ***namespace_id***<br> __required__ | ID of the namespace to which the sequence belongs. | string |
| ***path***<br> __required__ | The fully qualified sequence name. | string |
| ***scope_id***<br> __required__ | ID of the scope to which the sequence belongs. | string |
| ***value***<br> __required__ | The current value of the sequence on each Query node. | [Values](#value) object |

<a name="value"></a>***Values***

| Name | Description | Schema |
| --- | --- | --- |
| ***<UUID>***<br> __required__ | The name of this property is the UUID of a Query node. The value of this property is the current value of the sequence on that node. | Integer |
| ***~next_block***<br> __optional__ | The starting vale of the next block of values that can be reserved for the sequence. | Integer |

For further details, see [n1ql:n1ql-language-reference/createsequence.adoc](n1ql:n1ql-language-reference/createsequence.adoc).

## Monitor All Sequences

The `system:all_sequences` catalog maintains a list of all defined sequences.
To see the list of all defined sequences, use:

```sqlpp
SELECT * FROM system:all_sequences;
```

This will result in a list similar to:

```json
[
  {
    "sequences": {
      "bucket": "travel-sample",
      "cache": 50,
      "cycle": false,
      "increment": -1,
      "max": 9223372036854776000,
      "min": 0,
      "name": "seq4",
      "namespace": "default",
      "namespace_id": "default",
      "path": "`default`:`travel-sample`.`inventory`.`seq4`",
      "scope_id": "inventory",
      "value": {
        "73428daec3c68d8632ae66b09b70f14d": 10,
        "~next_block": -40
      }
    }
  },
  {
    "sequences": {
      "bucket": "travel-sample",
      "cache": 50,
      "cycle": true,
      "increment": 5,
      "max": 1000,
      "min": 0,
      "name": "seq3",
      "namespace": "default",
      "namespace_id": "default",
      "path": "`default`:`travel-sample`.`inventory`.`seq3`",
      "scope_id": "inventory",
      "value": {
        "73428daec3c68d8632ae66b09b70f14d": 5,
        "~next_block": 255
      }
    }
  },
// ...
]
```

This catalog gives the same information as the [system:sequences](#monitor-sequences) catalog.

For further details, see [n1ql:n1ql-language-reference/createsequence.adoc](n1ql:n1ql-language-reference/createsequence.adoc).

## Related Links

* Refer to [n1ql:n1ql-manage/monitoring-n1ql-query.adoc](n1ql:n1ql-manage/monitoring-n1ql-query.adoc) for more information on the system namespace.
