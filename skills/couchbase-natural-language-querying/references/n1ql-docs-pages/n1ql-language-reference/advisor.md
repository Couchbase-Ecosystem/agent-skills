# ADVISOR Function

The ADVISOR function provides index recommendations to optimize query response time.
There are two main scenarios for using this function.
One is to invoke the index advisor _immediately_ for a given query or set of queries; the other is to start a session in which every query of interest is collected for a set time period, then invoke the index advisor _asynchronously_ for that collection of queries when the session ends.
Within these two scenarios, this function has several different usages.
The operation and output of each usage depends on the function’s single argument.
For clarity, each usage is listed separately on this page.

## ADVISOR(`string`)

### Description

When used with a string argument, the function invokes the index advisor for a single {sqlpp} query.
The index advisor works with [SELECT](n1ql-language-reference/selectintro.adoc), [UPDATE](n1ql-language-reference/update.adoc), [DELETE](n1ql-language-reference/delete.adoc), or [MERGE](n1ql-language-reference/merge.adoc) queries.

### Arguments

* **string**\
A string, or an expression which resolves to a string, containing a single {sqlpp} query.

### Return Value

Returns an index advisor results object with the following properties.

<a name="results"></a>***Results***

| Name | Description | Schema |
| --- | --- | --- |
| ***current_used_indexes***<br> __optional__ | If the query engine can select any current primary or secondary indexes to use with an input query, this is an array of Index objects, each giving information about one of the current indexes. If the query engine cannot select a current index to use with an input query, this field does not appear. | < [Indexes](#indexes) > array |
| ***recommended_covering_indexes***<br> __optional__ | If the index advisor recommends any indexes, this is an array of Index objects, each giving information about one of the recommended indexes. If the index advisor cannot recommend any covering indexes, this field does not appear. | < [Indexes](#indexes) > array |
| ***recommended_indexes***<br> __optional__ | If the index advisor recommends any indexes, this is an array of Index objects, each giving information about one of the recommended indexes. If the index advisor cannot recommend any indexes, this field does not appear. | < [Indexes](#indexes) > array |

<a name="indexes"></a>***Indexes***

| Name | Description | Schema |
| --- | --- | --- |
| ***index***<br> __required__ | The {sqlpp} command used to define the index. | string |
| ***statements***<br> __required__ | An array of Statement objects, each giving information about one of the {sqlpp} input queries associated with this index. | < [Statements](#statements) > array |

<a name="statements"></a>***Statements***

| Name | Description | Schema |
| --- | --- | --- |
| ***run_count***<br> __required__ | When the function is used with a single {sqlpp} input query, this is always 1. When the function is used with an array of queries, or a collection of queries from a session, this is the number of times that this {sqlpp} input query occurs in the input array or session. | integer |
| ***statement***<br> __required__ | The {sqlpp} input query. | string |

### Example

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Get index advice for a single query**

**Query**

```sqlpp
SELECT ADVISOR("SELECT * FROM landmark
WHERE activity = 'eat' AND city = 'Paris'") AS Single;
```

**Result**

```json
[
  {
    "Single": {
      "current_used_indexes": [
        {
          "index": "CREATE INDEX def_inventory_landmark_city ON `default`:`travel-sample`.`inventory`.`landmark`(`city`)",
          "statements": [
            {
              "run_count": 1,
              "statement": "SELECT * FROM `travel-sample`.inventory.landmark\nWHERE activity = 'eat' AND city = 'Paris'"
            }
          ]
        }
      ],
      "recommended_indexes": [
        {
          "index": "CREATE INDEX adv_city_activity ON `default`:`travel-sample`.`inventory`.`landmark`(`city`,`activity`)",
          "statements": [
            {
              "run_count": 1,
              "statement": "SELECT * FROM `travel-sample`.inventory.landmark\nWHERE activity = 'eat' AND city = 'Paris'"
            }
          ]
        }
      ]
    }
  }
]
```

Only one statement occurs in these results, because the function was called with a single query input.
In this case, the index advisor identifies one index which is currently used by the query, and recommends one secondary index.
No covering indexes are recommended.

## ADVISOR(`array`)

### Description

When used with an array argument, the function invokes the index advisor for multiple {sqlpp} queries.
The index advisor works with [SELECT](n1ql-language-reference/selectintro.adoc), [UPDATE](n1ql-language-reference/update.adoc), [DELETE](n1ql-language-reference/delete.adoc), or [MERGE](n1ql-language-reference/merge.adoc) queries.

### Arguments

* **array**\
An array of strings, or an expression which resolves to an array of strings, each of which contains a {sqlpp} query.

### Return Value

Returns an [index advisor results](#results) object.

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Get index advice for multiple queries**

**Query**

```sqlpp
SELECT ADVISOR([
  "SELECT * FROM landmark
   WHERE activity = 'eat' AND city = 'Paris'",
  "SELECT * FROM landmark
   WHERE activity = 'see' AND city = 'San Francisco'"
]) AS Multiple;
```

**Result**

```json
[
  {
    "Multiple": {
      "current_used_indexes": [
        {
          "index": "CREATE INDEX def_inventory_landmark_city ON `default`:`travel-sample`.`inventory`.`landmark`(`city`)",
          "statements": [
            {
              "run_count": 1,
              "statement": "SELECT * FROM `travel-sample`.inventory.landmark\n   WHERE activity = 'eat' AND city = 'Paris'"
            },
            {
              "run_count": 1,
              "statement": "SELECT * FROM `travel-sample`.inventory.landmark\n   WHERE activity = 'see' AND city = 'San Francisco'"
            }
          ]
        }
      ],
      "recommended_indexes": [
        {
          "index": "CREATE INDEX adv_city_activity ON `default`:`travel-sample`.`inventory`.`landmark`(`city`,`activity`)",
          "statements": [
            {
              "run_count": 1,
              "statement": "SELECT * FROM `travel-sample`.inventory.landmark\n   WHERE activity = 'eat' AND city = 'Paris'"
            }
          ]
        },
        {
          "index": "CREATE INDEX adv_activity_city ON `default`:`travel-sample`.`inventory`.`landmark`(`activity`,`city`)",
          "statements": [
            {
              "run_count": 1,
              "statement": "SELECT * FROM `travel-sample`.inventory.landmark\n   WHERE activity = 'see' AND city = 'San Francisco'"
            }
          ]
        }
      ]
    }
  }
]
```

In this case, the index advisor recommends an index which would be suitable for both of the input queries.

**Get index advice for recent completed requests**

This example uses a subquery to get an array of statements from the [system:completed_requests](n1ql:n1ql-manage/monitoring-n1ql-query.adoc#sys-completed-req) catalog.

**Query**

```sqlpp
SELECT ADVISOR((SELECT RAW statement FROM system:completed_requests)) AS Recent;
```

**Result**

```json
[
  {
    "Recent": {
      "current_used_indexes": [
        {
          "index": "CREATE PRIMARY INDEX def_inventory_route_primary ON `default`:`travel-sample`.`inventory`.`route`",
          "statements": [
            {
              "run_count": 3,
              "statement": "SELECT * FROM `travel-sample`.inventory.route r JOIN `travel-sample`.inventory.airline a ON r.airlineid= META(a).id WHERE a.country = \"France\";"
            },
            {
              "run_count": 2,
              "statement": "SELECT d.id, d.destinationairport, RATIO_TO_REPORT(d.distance) OVER (PARTITION BY d.destinationairport) AS `distance-ratio` FROM `travel-sample`.inventory.route AS d LIMIT 7;"
            },
// ...
          ]
        },
        {
          "index": "CREATE PRIMARY INDEX def_inventory_airport_primary ON `default`:`travel-sample`.`inventory`.`airport`",
          "statements": [
            {
              "run_count": 1,
              "statement": "SELECT airportname FROM `travel-sample`.inventory.airport WHERE geo.alt NOT BETWEEN 0 AND 100;"
            }
          ]
        }
      ],
      "recommended_covering_indexes": [
        {
          "index": "CREATE INDEX adv_geo_alt_airportname ON `default`:`travel-sample`.`inventory`.`airport`(`geo`.`alt`,`airportname`)",
          "statements": [
            {
              "run_count": 1,
              "statement": "SELECT airportname FROM `travel-sample`.inventory.airport WHERE geo.alt NOT BETWEEN 0 AND 100;"
            }
          ]
        }
      ],
      "recommended_indexes": [
        {
          "index": "CREATE INDEX adv_geo_alt ON `default`:`travel-sample`.`inventory`.`airport`(`geo`.`alt`)",
          "statements": [
            {
              "run_count": 1,
              "statement": "SELECT airportname FROM `travel-sample`.inventory.airport WHERE geo.alt NOT BETWEEN 0 AND 100;"
            }
          ]
        },
        {
          "index": "CREATE INDEX adv_airlineid ON `default`:`travel-sample`.`inventory`.`route`(`airlineid`)",
          "statements": [
            {
              "run_count": 3,
              "statement": "SELECT * FROM `travel-sample`.inventory.route r JOIN `travel-sample`.inventory.airline a ON r.airlineid= META(a).id WHERE a.country = \"France\";"
            }
// ...
```

In this case, the index advisor recommends several covering indexes and secondary indexes, each of which would be suitable for multiple recent queries.
(Results are truncated for brevity.)

## ADVISOR(`start_obj`)

### Description

When used with a `start_obj` object argument, the function can be used to start an index advisor session.
As long as the session is running, any queries that meet the criteria you specify are collected for later analysis.

By default, the session continues running for the duration you specify when you start the session.
At the end of the duration, the index advisor analyzes any queries that have been collected by this session.
The session and any resulting index advice are retained in the _tasks cache_.
You can then [get the results](#advisorget_obj) for this session to see the index advice.

### Arguments

* **start_obj**\
An object with the following properties:

action;;
[Required] The string `start`.

profile;;
[Optional] A string specifying the user profile whose queries you want to collect.
If omitted, all queries are collected.

response;;
[Optional] A string representing a duration.
All completed queries lasting longer than this threshold are collected for analysis by the index advisor.
Valid time units are `ns` (nanoseconds), `us` (microseconds), `ms` (milliseconds), `s` (seconds), `m` (minutes), or `h` (hours).
If omitted, the default setting is `0s`.

duration;;
[Required] A string representing a duration.
The index advisor session runs for the length of this duration.
Valid time units are `ns` (nanoseconds), `us` (microseconds), `ms` (milliseconds), `s` (seconds), `m` (minutes), or `h` (hours).

query_count;;
[Optional] An integer specifying the maximum number of queries to be collected for analysis by the index advisor.
If omitted, the default setting is the same as the service-level [completed-limit](n1ql:n1ql-manage/query-settings.adoc#completed-limit) setting.
You can change the service-level `completed-limit` setting to change the default for this property.

### Return Value

Returns an object with the following property:

| Name | Description | Schema |
| --- | --- | --- |
| ***session***<br> __required__ | The name of the index advisor session. You will need to refer to this name to [get the results](#advisorget_obj) for this session, or to [stop](#advisorstop_obj), [abort](#advisorabort_obj), or [purge](#advisorpurge_obj) this session. | string (UUID) |

### Example

**Start an index advisor session**

The following example starts an index advisor session to run for one hour.
All completed queries taking longer than 0 seconds will be collected.

**Query**

```sqlpp
SELECT ADVISOR({"action": "start", "response": "0s", "duration": "1h"}) AS Collect;
```

**Result**

```json
[
  {
    "Collect": {
      "session": "0cd09ae4-a083-4a7e-86cd-85e42c140d60"
    }
  }
]
```

## ADVISOR(`list_obj`)

### Description

When used with a `list_obj` object argument, the function can be used to list index advisor sessions.
Each index advisor session is stored as a scheduled task in the [system:tasks_cache](n1ql:n1ql-manage/monitoring-n1ql-query.adoc#sys-tasks-cache) catalog.

### Arguments

* **list_obj**\
An object with the following properties:

action;;
[Required] The string `list`.

status;;
[Optional] A string specifying the status of the index advisor sessions to list.
This must be one of the following:
+
* `completed` -- only list completed sessions
* `active` -- only list active sessions
* `all` -- list all sessions
+
If omitted, the default is `all`.

### Return Value

Returns an array of tasks cache objects, each of which has the following properties.

<a name="tasks-cache"></a>***Tasks Cache***

| Name | Description | Schema |
| --- | --- | --- |
| ***tasks_cache***<br> __required__ | A nested object that gives information about an index advisor session. | [Session](#session) |

<a name="session"></a>***Session***

| Name | Description | Schema |
| --- | --- | --- |
| ***class***<br> __required__ | The class of the session; in this case, `advisor`. | string |
| ***delay***<br> __required__ | The scheduled duration of the session. | string (duration) |
| ***id***<br> __required__ | The internal ID of the session. | string (UUID) |
| ***name***<br> __required__ | The name of the session. You will need to refer to this name to [get the results](#advisorget_obj) for this session, or to [stop](#advisorstop_obj), [abort](#advisorabort_obj), or [purge](#advisorpurge_obj) this session. | string (UUID) |
| ***node***<br> __required__ | The node where the session was started. | string (address) |
| ***state***<br> __required__ | The state of the session: * `scheduled` -- the session is active. * `cancelled` -- the session was stopped. * `completed` -- the session is completed. | enum (cancelled, completed, scheduled) |
| ***subClass***<br> __required__ | The subclass of the session; in this case, `analyze`. | string |
| ***submitTime***<br> __required__ | The date and time when the function was called to start the session. | string (date-time) |
| ***startTime***<br> __optional__ | The date and time when the session started. If the session is still active, this field is not present. | string (date-time) |
| ***stopTime***<br> __optional__ | The date and time when the session stopped. If the session is still active, this field is not present. | string (date-time) |
| ***results***<br> __optional__ | An array containing a single [index advisor results](#results) object. If the session is still active, this field is not present. | < [Results](#results) > array |

Returns an empty array if there are no index advisor sessions in the tasks cache.

### Example

**List all index advisor sessions**

**Query**

```sqlpp
SELECT ADVISOR({"action": "list"}) AS List;
```

**Result**

```json
[
  {
    "List": [
      {
        "tasks_cache": {
          "class": "advisor",
          "delay": "10s",
          "id": "583af6ae-841e-5090-9a74-3607784533fa",
          "name": "0cd09ae4-a083-4a7e-86cd-85e42c140d60",
          "node": "127.0.0.1:8091",
          "results": [
// ...
          ],
          "startTime": "2021-01-19 15:57:51.015716783 +0000 UTC m=+19106.791327072",
          "state": "completed",
          "stopTime": "2021-01-19 15:57:51.123751229 +0000 UTC m=+19106.899361513",
          "subClass": "analyze",
          "submitTime": "2021-01-19 15:57:41.01262637 +0000 UTC m=+19096.788236671"
        }
      },
      {
        "tasks_cache": {
          "class": "advisor",
          "delay": "1h0m0s",
          "id": "ce4ec13f-720e-56ae-8790-8136ea0648e3",
          "name": "4e394fad-03d5-4fbf-b9a5-6ad902c8df75",
          "node": "127.0.0.1:8091",
          "results": [
            {}
          ],
          "state": "cancelled",
          "subClass": "analyze",
          "submitTime": "2021-01-19 15:56:12.398458243 +0000 UTC m=+19008.174068538"
        }
      }
    ]
  }
]
```

(Results are truncated for brevity.)

## ADVISOR(`stop_obj`)

### Description

When used with a `stop_obj` object argument, the function can be used to stop an index advisor session.
In this case, the session is stopped, and the index advisor analyzes any queries that have been collected by this session so far.
The session and any resulting index advice are retained in the tasks cache.
You can then [get the results](#advisorget_obj) for this session to see the index advice.

### Arguments

* **stop_obj**\
An object with the following properties:

action;;
[Required] The string `stop`.

session;;
[Required] A string specifying the name of a session.

### Return Value

Returns an empty array.

### Example

**Stop an index advisor session**

**Query**

```sqlpp
SELECT ADVISOR({"action": "stop", "session": "0cd09ae4-a083-4a7e-86cd-85e42c140d60"})
AS Stop;
```

**Result**

```json
[
  {
    "Stop": []
  }
]
```

## ADVISOR(`abort_obj`)

### Description

When used with an `abort_obj` object argument, the function can be used to abort an index advisor session.
In this case, the session is stopped, and the session is removed from the tasks cache.

### Arguments

* **abort_obj**\
An object with the following properties:

action;;
[Required] The string `abort`.

session;;
[Required] A string specifying the name of a session.

### Return Value

Returns an empty array.

### Example

**Abort an index advisor session**

**Query**

```sqlpp
SELECT ADVISOR({"action": "abort", "session": "0cd09ae4-a083-4a7e-86cd-85e42c140d60"})
AS Abort;
```

**Result**

```json
[
  {
    "Abort": []
  }
]
```

## ADVISOR(`get_obj`)

### Description

When used with a `get_obj` object argument, the function can be used to get the results of a completed index advisor session.
The index advisor is invoked for any collected [SELECT](n1ql-language-reference/selectintro.adoc), [UPDATE](n1ql-language-reference/update.adoc), [DELETE](n1ql-language-reference/delete.adoc), or [MERGE](n1ql-language-reference/merge.adoc) queries.

### Arguments

* **get_obj**\
An object with the following properties:

action;;
[Required] The string `get`.

session;;
[Required] A string specifying the name of a session.

### Return Value

Returns an array containing an array, which in turn contains an [index advisor results](#results) object.

Returns an empty array if the specified session collected no queries, or if the specified session does not exist.

### Example

**Get index advice for an index advisor session**

**Query**

```sqlpp
SELECT ADVISOR({"action": "get", "session": "0cd09ae4-a083-4a7e-86cd-85e42c140d60"})
AS Get;
```

**Result**

```json
[
  {
    "Get": [
      [
        {
          "current_used_indexes": [
            {
              "index": "CREATE PRIMARY INDEX idx_airport_primary ON `default`:`travel-sample`.`inventory`.`airport`",
              "statements": [
                {
                  "run_count": 1,
                  "statement": "SELECT airportname FROM `travel-sample`.inventory.airport WHERE geo.alt NOT BETWEEN 0 AND 100;"
                }
              ]
// ...
            }
          ],
          "recommended_covering_indexes": [
            {
              "index": "CREATE INDEX adv_city_name ON `default`:`travel-sample`.`inventory`.`hotel`(`city`,`name`)",
              "statements": [
                {
                  "run_count": 1,
                  "statement": "SELECT h.name, h.city, a.airportname FROM `travel-sample`.inventory.hotel h JOIN `travel-sample`.inventory.airport a ON h.city = a.city LIMIT 5;"
                }
              ]
// ...
            }
          ],
          "recommended_indexes": [
            {
              "index": "CREATE INDEX adv_geo_alt ON `default`:`travel-sample`.`inventory`.`airport`(`geo`.`alt`)",
              "statements": [
                {
                  "run_count": 1,
                  "statement": "SELECT airportname FROM `travel-sample`.inventory.airport WHERE geo.alt NOT BETWEEN 0 AND 100;"
                }
              ]
            }
          ]
        }
      ]
    ]
  }
]
```

(Results are truncated for brevity.)

## ADVISOR(`purge_obj`)

### Description

When used with a `purge_obj` object argument, the function can be used to purge the results of a completed index advisor session from the tasks cache.

### Arguments

* **purge_obj**\
An object with the following properties:

action;;
[Required] The string `purge`.

session;;
[Required] A string specifying the name of a session.

### Return Value

Returns an empty array.

### Example

**Purge an index advisor session**

**Query**

```sqlpp
SELECT ADVISOR({"action": "purge", "session": "0cd09ae4-a083-4a7e-86cd-85e42c140d60"})
AS Purge;
```

**Result**

```json
[
  {
    "Purge": []
  }
]
```

## Related Links

* The [ADVISE](n1ql-language-reference/advise.adoc) statement -- also describes the index advisor [recommendation rules](n1ql-language-reference/advise.adoc#recommendation-rules)
* The [Index Advisor](tools:query-workbench.adoc#index-advisor) in the Query Workbench
* The [system:tasks_cache](n1ql:n1ql-manage/monitoring-n1ql-query.adoc#sys-tasks-cache) catalog
