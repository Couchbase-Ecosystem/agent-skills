# Manage and Monitor Queries

Monitoring and profiling {sqlpp} queries, Query Service nodes, and corresponding system resources is important for smoother operational performance and efficiency of the system.
In fact, often it’s vital for diagnosing and troubleshooting issues such as query performance, resource bottlenecks, and overloading of various services.

System keyspaces provide various monitoring details and statistics about individual queries and the Query Service.
When running on a cluster with multiple query nodes, stats about all queries on all query nodes are collected in the Query management and monitoring system keyspaces.

For example, this can help identify:

* The top 10 slow or fast queries running on a particular query node or the cluster.
* Resource usage statistics of the Query Service, or resources used for a particular query.
* Details about the active, completed, and prepared queries.
* Find long running queries that are running for more than 2 minutes.

These system keyspaces are transient in nature, and are not persisted to disk or permanent storage.
Hence, the information in the keyspaces pertains to the current instantiation of the Query Service.

You can access the Query management and monitoring system keyspaces using any of the following:

* {sqlpp} from the cbq shell or Query Workbench
* The Query Admin REST API
* A monitoring SDK

Using {sqlpp} enables you to obtain further insights from the keyspaces.

## Authentication and Client Privileges

Users must have the **Query System Catalog** role to access restricted system keyspaces.
For more information about user roles, see [Authorization](learn:security/authorization-overview.adoc).

## Examples on this Page

In the REST API examples:

* `$BASE_URL` is the protocol, host name or IP address, and port -- for example, `http://localhost:8093`.
* `$USER` is the user name.
* `$PASSWORD` is the password.

## Monitor System Vitals

The `system:vitals` catalog provides data about the running state and health of the query nodes, such as number of logical cores, active threads, queued threads, CPU utilization, memory usage, network utilization, garbage collection percentage, and so on.
This information can be useful to assess the current workload and performance characteristics of a query node.

### Get System Vitals

To view system vitals, use the [Admin REST API](n1ql:n1ql-rest-api/admin.adoc) or a {sqlpp} query.

* **REST API**

  To view system vitals with the Admin REST API:

  ```sh
  curl -u $USER:$PASSWORD $BASE_URL/admin/vitals
  ```
* **{sqlpp}**

  To view system vitals with {sqlpp}:

  ```sqlpp
  SELECT * FROM system:vitals;
  ```

### System Vitals Details

Getting system vitals, as described in [Get System Vitals](#get-system-vitals), returns results similar to the following.

```json
{
  "uptime": "7h39m32.668577197s",
  "local.time": "2021-04-30 18:42:39.517208807 +0000 UTC m=+27573.945319668",
  "version": "7.0.0-N1QL",
  "total.threads": 191,
  "cores": 2,
  "gc.num": 669810600,
  "gc.pause.time": "57.586373ms",
  "gc.pause.percent": 0,
  "memory.usage": 247985184,
  "memory.total": 11132383704,
  "memory.system": 495554808,
  "cpu.user.percent": 0,
  "cpu.sys.percent": 0,
  "request.completed.count": 140,
  "request.active.count": 0,
  "request.per.sec.1min": 0.0018,
  "request.per.sec.5min": 0.0055,
  "request.per.sec.15min": 0.0033,
  "request_time.mean": "536.348163ms",
  "request_time.median": "54.065567ms",
  "request_time.80percentile": "981.869933ms",
  "request_time.95percentile": "2.543128455s",
  "request_time.99percentile": "4.627922799s",
  "request.prepared.percent": 0
}
```

For field names and meanings, see [Vital Statistics](n1ql-rest-admin:index.adoc#Vitals).

## Monitor and Manage Active Requests

The `system:active_requests` catalog lists all currently executing active requests or queries.

### Get Active Requests

To view active requests, use the [Admin REST API](n1ql:n1ql-rest-api/admin.adoc) or a {sqlpp} query.

* **REST API**

  To view active requests with the Admin REST API:

  ```sh
  curl -u $USER:$PASSWORD $BASE_URL/admin/active_requests
  ```
* **{sqlpp}**

  To view active requests with {sqlpp}:

  ```sqlpp
  SELECT * FROM system:active_requests;
  ```

To get the query plan for active requests, include `meta().plan` in a {sqlpp} query.
See [Query Profiling](#query-profiling).

* **{sqlpp}**

  To view active requests with {sqlpp}, including the query plan:

  ```sqlpp
  SELECT *, meta().plan FROM system:active_requests;
  ```

### Terminate an Active Request

To terminate an active request, for instance, a non-responding or a long-running query, use the [Admin REST API](n1ql:n1ql-rest-api/admin.adoc) or a {sqlpp} query.

* **REST API**

  To terminate an active request `uuid` with the Admin REST API:

  ```sh
  curl -u $USER:$PASSWORD -X DELETE $BASE_URL/admin/active_requests/uuid
  ```
* **{sqlpp}**

  To terminate an active request `uuid` with {sqlpp}:

  ```sqlpp
  DELETE FROM system:active_requests WHERE requestId = "uuid";
  ```

### Active Request Details

Getting active requests, as described in [Get Active Requests](#get-active-requests), returns results similar to the following.

```json
[
  {
    "active_requests": {
        "clientContextID": "8c169ed1-9e1a-486a-a1b9-1c2ac8e327a4",
        "cpuTime": "22.915µs",
        "elapsedTime": "30.092625ms",
        "executionTime": "30.012ms",
        "ioTime": "8.366709ms",
        "memoryQuota": 1152921504606846976,
        "n1qlFeatCtrl": 76,
        "node": "127.0.0.1:8091",
        "phaseOperators": {
            "authorize": 1,
            "fetch": 1,
            "primaryScan": 1,
            "project": 1,
            "stream": 1
        },
        "phaseTimes": {
            "authorize": "7.584µs",
            "fetch": "5.708µs",
            "instantiate": "15.708µs",
            "parse": "266.875µs",
            "plan": "13.737208ms",
            "plan.index.metadata": "13.577125ms",
            "plan.keyspace.metadata": "45.915µs",
            "primaryScan": "8.370458ms",
            "project": "666ns",
            "queued": "1.459µs",
            "setup": "62.375µs",
            "stream": "2.542µs"
        },
        "queryContext": "default:travel-sample.inventory",
        "remoteAddr": "127.0.0.1:34064",
        "requestId": "9860351c-d837-4b42-ad2f-a5b3cbcfeb4b",
        "requestTime": "2025-06-05T10:31:34.423Z",
        "scanConsistency": "unbounded",
        "state": "running",
        "statement": "SELECT * FROM system:active_requests;",
        "statementType": "SELECT",
        "useCBO": true,
        "userAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36",
        "users": "builtin:Administrator",
        "waitTime": "8.376917ms"
    }
  }
]
```

For field names and meanings, see [Requests](n1ql-rest-admin:index.adoc#Requests).

For query plan field names and meanings, see [Query Profiling Details](#query-profiling-details).

## Monitor and Manage Prepared Statements

The `system:prepareds` catalog provides data about the known prepared statements and their state in a query node’s prepared statement cache.
For each prepared statement, this catalog provides information such as name, statement, query plan, last use time, number of uses, and so on.

A prepared statement is created and stored relative to the current [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).
You can create multiple prepared statements with the same name, each stored relative to a different query context.
This enables you to run multiple instances of the same application against different datasets.

When there are multiple prepared statements with the same name in different query contexts, the name of the prepared statement in the `system:prepareds` catalog includes the associated query context in brackets.

### Get Prepared Statements

To get a list of all known prepared statements, use the [Admin REST API](n1ql:n1ql-rest-api/admin.adoc) or a {sqlpp} query.

* **REST API**

  To get a list of all known prepared statements with the Admin REST API:

  ```sh
  curl -u $USER:$PASSWORD $BASE_URL/admin/prepareds
  ```
* **{sqlpp}**

  To get a list of all known prepared statements with a {sqlpp} query:

  ```sqlpp
  SELECT * FROM system:prepareds;
  ```

To get information about a specific prepared statement, use the Admin REST API or a {sqlpp} query.

* **REST API**

  To get information about a specific prepared statement `example1` with the Admin REST API:

  ```sh
  curl -u $USER:$PASSWORD $BASE_URL/admin/prepareds/example1
  ```
* **{sqlpp}**

  To get information about a specific prepared statement `example1` with a {sqlpp} query:

  ```sqlpp
  SELECT * FROM system:prepareds WHERE name = "example1";
  ```

To get the query plan for prepared statements, include `meta().plan` in a {sqlpp} query.
See [Query Profiling](#query-profiling).

* **{sqlpp}**

  To view prepared statements with {sqlpp}, including the query plan:

  ```sqlpp
  SELECT *, meta().plan FROM system:prepareds;
  ```

### Delete Prepared Statements

To delete a specific prepared statement, use the [Admin REST API](n1ql:n1ql-rest-api/admin.adoc) or a {sqlpp} query.

* **REST API**

  To delete a prepared statement `p1` with the Admin REST API:

  ```sh
  curl -u $USER:$PASSWORD -X DELETE $BASE_URL/admin/prepareds/p1
  ```
* **{sqlpp}**

  To delete a prepared statement `p1` with a {sqlpp} query:

  ```sqlpp
  DELETE FROM system:prepareds WHERE name = "p1";
  ```

To delete all the known prepared statements, use a {sqlpp} query.

* **{sqlpp}**

  To delete all known prepared statements:

  ```sqlpp
  DELETE FROM system:prepareds;
  ```

### Prepared Statement Details

To try the examples in this section, first create a couple of prepared statements.

**Create a prepared statement with default query context**

For this example, unset the query context.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Query**

```sqlpp
PREPARE p1 AS SELECT * FROM `travel-sample`.inventory.airline WHERE iata = "U2";
```

**Create a prepared statement with specified query context**

For this example, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Query**

```sqlpp
PREPARE p1 AS SELECT * FROM airline WHERE iata = "U2";
```

Getting prepared statements, as described in [Get Prepared Statements](#get-prepared-statements), returns results similar to the following.

```json
{
  "requestID": "d976e59a-d74e-4350-b0df-fa137099d594",
  "signature": {
    "*": "*",
    "plan": "json"
  },
  "results": [
    {
      "prepareds": {
        "encoded_plan": "H4sIAAAAAAAA/6RTUW/TPBT9K9H5XrbJ30QBMcmIhzJ1AjG0qh3wwKbEJLedmWt71061UIXfjpxkndYhENpbYt97z7nn+GxAtnQVVbk3ykICAgtSsWY6djayMwHy6JWAthXdjr3+TBy0s5Avh7N5qewHaoJXJQXIDSpaqNpEGVmtyfwf1MobOtR2TTY6bg6VZqMtQS6UCdQKWLUiSPgR+u9uFOTdIAg4T6yi4zT+v/sfjOt45Vj/IAh41mttaNmTONUhQn7d4FzxkuL9tL/SEpiyXkMepQ/nA+Sz9rIV+FleaVPtMpjTTU22TG19AZPtcP+5aMp6pbhJcr6AwLe6vO54P+CLQfR+n3zLPh/Y576fcleXe3bfqYydYxsMt/k1NZCR66T+9eAdJO4l+L0NoXQ+nWxhIVAHbZeQWAaNVjxc6YRiefWnXZ6EvYs2VayMIYMneXWiTSSGQOlspXvhsLdXDPyKw0KrqIr97E12gU/PL7D/iMh7q6NWZtpLDwGmUJuYR+JV6ADp1qfCQGaRVouKBzsu28s2vbYd4pFJrZDuBFJOtyE8Go0EbmriJqWVbmOfYKab86aTaz45nRyfJxC9tF2skyoHkDhAKzC0TGeT6Xg2yfwoG8+zvic7yE5mZx+z4oFpxePEZF/eTWaTLMmyFeV19zLo+O3ZsNivAAAA//+q+jhuaAQAAA==",
        "featuresControl": 76,
        "indexApiVersion": 4,
        "indexScanKeyspaces": {
          "default:travel-sample.inventory.airline": false
        },
        "name": "p1", // ①
        "namespace": "default",
        "node": "127.0.0.1:8091",
        "statement": "PREPARE p1 AS SELECT * FROM `travel-sample`.inventory.airline WHERE iata = \"U2\";",
        "uses": 0
      }
    },
    {
      "prepareds": {
        "encoded_plan": "H4sIAAAAAAAA/6STT28TMRDFv8rqcWkrExFAVDLiEKpUIIoaJQUOtNqY3Ulq6tju2Bt1iZbPjry7TWmKQKg3/xnPvPk9zwZkC1dSmXujLCQgsCAVK6YjZyM7EyAPXwloW9LNyOvPxEE7C/myP5sVyn6gOnhVUIDcoKSFqkyUkdWazNOgVt7QQNs12ei4HijNRluCXCgTqBGwakWQ8EN06zYV5G0iCDhPrKLjlP7J3QajKl461j8IAp71WhtadiJOdIiQXzc4U7ykeJftn7IEJqzXkIdp4XyAfNZcNAI/i0ttyl0FM7quyBbpWRfAZNu6/x00Yb1SXCecLyDwrSquWt339KKH3vWTb9Xnvfrcd1lu43LP7jsVsXVsg/42v6IaMnKV6F/13kHiDsGfbQiF8+lkWxYCVdB2CYll0GjE/ZaOKRaXf+vlUbV3q00UK2PI4FFeHWsTiSFQOFvqDhz29ua9vvlgrlVU8/3sTXaOT8/Psf9AyHuro1Zm0qGHAFOoTMwj8Sq0BenGp8BAZpFai4p7Oy6aiyb9th3hkUmtkO4E0pxuh/BwOBS4rojrNK108wDy4HevmK7P6pbibHwyPjpLtfXSttOeYB1A4gCNQJ9pMh1PRtNx5ofZaJZ1b7KD7Hh6+jHreWRf3o2n4ywx2RJ53X4LOnp72nf1KwAA////9+bsZQQAAA==",
        "featuresControl": 76,
        "indexApiVersion": 4,
        "indexScanKeyspaces": {
          "default:travel-sample.inventory.airline": false
        },
        "name": "p1(travel-sample.inventory)", // ②
        "namespace": "default",
        "node": "127.0.0.1:8091",
        "statement": "PREPARE p1 AS SELECT * FROM airline WHERE iata = \"U2\";",
        "uses": 0
      }
    }
  ],
  "status": "success",
  "metrics": {
    "elapsedTime": "25.323496ms",
    "executionTime": "25.173646ms",
    "resultCount": 2,
    "resultSize": 7891,
    "serviceLoad": 12
  }
}
```

In this example, the names of the prepared statements are identical, but they’re associated with different query contexts.

1. The name of the prepared statement for the default query context
2. The name of the prepared statement showing the associated query context

For field names and meanings, see [Prepared Statements](n1ql-rest-admin:index.adoc#Statements).

For query plan field names and meanings, see [Query Profiling Details](#query-profiling-details).

## Monitor and Manage Completed Requests

By default, the `system:completed_requests` catalog maintains a list of the most recent completed requests that have run longer than a predefined threshold of time.
(You can also log completed requests that meet other conditions that you define.)

For each completed request, this catalog maintains information such as requestId, statement text, prepared name (if prepared statement), request time, service time, and so on.
This information provides a general insight into the health and performance of the query node and the cluster.

### Get Completed Requests

To get a list of all logged completed requests, use the [Admin REST API](n1ql:n1ql-rest-api/admin.adoc) or a {sqlpp} query.

* **REST API**

  To get a list of all logged completed requests using the Admin REST API:

  ```sh
  curl -u $USER:$PASSWORD $BASE_URL/admin/completed_requests
  ```
* **{sqlpp}**

  To get a list of all logged completed requests using {sqlpp}:

  ```sqlpp
  SELECT * FROM system:completed_requests;
  ```

The `completed` state means that the request was started and completed by the Query Service, but it does not mean that it was necessarily successful.
The request could have been successful, or completed with errors.

To find requests that completed successfully, search for completed requests whose `state` is `completed` and whose `errorCount` field has the value `0`.

* **{sqlpp}**

  To get a list of all logged completed requests, including only successful requests:

  ```sqlpp
  SELECT * FROM system:completed_requests
  WHERE state = "completed" AND errorCount = 0;
  ```

To get the query plan for completed requests, include `meta().plan` in a {sqlpp} query.
See [Query Profiling](#query-profiling).

* **{sqlpp}**

  To view completed requests with {sqlpp}, including the query plan:

  ```sqlpp
  SELECT *, meta().plan FROM system:completed_requests;
  ```

### Purge the Completed Requests

To purge a specific completed request, use the [Admin REST API](n1ql:n1ql-rest-api/admin.adoc) or a {sqlpp} query.

* **REST API**

  To purge a completed request `uuid` with the Admin REST API:

  ```sh
  curl -u $USER:$PASSWORD -X DELETE $BASE_URL/admin/completed_requests/uuid
  ```
* **{sqlpp}**

  To purge a completed request `uuid` with {sqlpp}:

  ```sqlpp
  DELETE FROM system:completed_requests WHERE requestId = "uuid";
  ```

To purge completed requests for a given time period, use a {sqlpp} query.

* **{sqlpp}**

  To purge the completed requests for a given time period:

  ```sqlpp
  DELETE FROM system:completed_requests WHERE requestTime LIKE "2015-09-09%";
  ```

### Completed Request Details

To try the examples in this section, first run a query which takes at least 1000&#160;ms (the default value of the `completed-threshold` query setting) to get registered in the `system:completed_requests` keyspace.

**Run a long query**

For this example, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Query**

```sqlpp
SELECT * FROM route ORDER BY sourceairport LIMIT 5;
```

Getting completed requests, as described in [Get Completed Requests](#get-completed-requests), returns results similar to the following.

```json
[
  {
    "completed_requests": {
        "clientContextID": "99c776c2-438e-449e-b3f5-7585f2c41b62",
        "cpuTime": "912.042µs",
        "elapsedTime": "10.237875ms",
        "errorCount": 0,
        "errors": [],
        "ioTime": "5.338667ms",
        "memoryQuota": 1152921504606846976,
        "n1qlFeatCtrl": 76,
        "namedArgs": {},
        "phaseCounts": {
            "fetch": 5,
            "indexScan": 5,
            "indexScan.GSI": 5
          },
        "phaseOperators": {
            "authorize": 1,
            "fetch": 1,
            "indexScan": 1,
            "indexScan.GSI": 1,
            "project": 1,
            "stream": 1
          },
        "phaseTimes": {
            "authorize": "19.084µs",
            "fetch": "1.1245ms",
            "indexScan": "4.312417ms",
            "indexScan.GSI": "4.312417ms",
            "instantiate": "233.666µs",
            "parse": "1.087875ms",
            "plan": "1.453375ms",
            "plan.index.metadata": "149.833µs",
            "plan.keyspace.metadata": "13.543µs",
            "project": "49.541µs",
            "queued": "417ns",
            "run": "6.39025ms",
            "setup": "913.667µs",
            "stream": "696µs"
          },
        "queryContext": "default:travel-sample.inventory",
        "remoteAddr": "127.0.0.1:34066",
        "requestId": "73fcdccc-da70-40e9-95f6-f8566acb671c",
        "requestTime": "2025-06-05T10:38:32.904Z",
        "resultCount": 5,
        "resultSize": 17714,
        "scanConsistency": "unbounded",
        "serviceTime": "9.305625ms",
        "sqlID": "4c7b735499e4f5e84d031c1ee327d66e",
        "sessionMemory": 1048576,
        "state": "completed",
        "statement": "SELECT * FROM route ORDER BY sourceairport LIMIT 5;",
        "statementType": "SELECT",
        "useCBO": true,
        "usedMemory": 13374,
        "userAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36",
        "users": "builtin:Administrator",
        "waitTime": "9.836667ms",
        "~analysis": [
            "High IO time"
          ],
        "~qualifier": "threshold"
     }
  }
]
```

For field names and meanings, see [Requests](n1ql-rest-admin:index.adoc#Requests).

For query plan field names and meanings, see [Query Profiling Details](#query-profiling-details).

## Configure Completed Requests

You can configure the `system:completed_requests` keyspace by specifying parameters through the [Admin REST API](n1ql:n1ql-rest-api/admin.adoc) `/admin/settings` endpoint.

You can specify the conditions for completed request logging using the `completed` field.
This field takes a JSON object containing the names and values of logging qualifiers.
Completed requests that meet the defined qualifiers are logged.

```sh
curl $BASE_URL/admin/settings -u $USER:$PASSWORD \
  -H 'Content-Type: application/json' \
  -d '{"completed": {"user": "marco", "error": 12003}}'
```

### Logging Qualifiers

You can specify the following logging qualifiers.
A completed request is logged if any of the qualifiers are met (logical OR).

* **`threshold`**\
The execution time threshold in milliseconds.
* **`aborted`**\
Whether to log requests that generate a panic.
* **`error`**\
Log requests returning this error number.
* **`client`**\
Log requests from this IP address.
* **`user`**\
Log requests with this user name.
* **`context`**\
Log requests with this client context ID.
* **`statement`**\
Log requests that match the specified LIKE search pattern in the query text.
* **`plan`**\
Log requests where the specified plan field values appear in the query plan.
* **`errors`**\
Log requests with at least this many errors.

For full details, see [Logging Parameters](n1ql-rest-admin:index.adoc#Logging_Parameters).

The basic syntax adds a qualifier to the logging parameters.
Any existing qualifiers are not removed.
You can change the value of a logging qualifier by specifying the same qualifier again with a new value.

To add a new instance of an existing qualifier, use a plus sign (`+`) before the qualifier name, such as `+user`.
To remove a qualifier, use a minus sign (`-`) before the qualifier name, such as `-user`.

For example, the following request will add user `simon` to those tracked, and remove error `12003`.

```sh
curl $BASE_URL/admin/settings -u $USER:$PASSWORD \
  -H 'Content-Type: application/json' \
  -d '{"completed": {"+user": "simon", "-error": 12003}}'
```

Similarly, you could remove all logging by execution time with the following request, as long as the value matches the existing threshold.

```sh
curl $BASE_URL/admin/settings -u $USER:$PASSWORD \
  -H 'Content-Type: application/json' \
  -d '{"completed": {"-threshold": 1000}}'
```

### Tagged Sets

You can also specify qualifiers that have to be met as a group for the completed request to be logged (logical AND).

To do this, specify the `tag` field along with a set of qualifiers, like so:

```sh
curl $BASE_URL/admin/settings -u $USER:$PASSWORD \
  -H 'Content-Type: application/json' \
  -d '{"completed": {"user": "marco", "error": 12003, "tag": "both_user_and_error"}}'
```

In this case, the request will be logged when both user and error match.

The tag name can be any string that is meaningful and unique.
Requests that match a tagged set of conditions are logged with a field `~tag`, which is set to the name of the tag.

To add a qualifier to a tagged set, specify the tag name again along with the new qualifier:

```sh
curl $BASE_URL/admin/settings -u $USER:$PASSWORD \
  -H 'Content-Type: application/json' \
  -d '{"completed": {"client": "172.1.2.3", "tag": "both_user_and_error"}}'
```

You cannot add a new instance of an existing qualifier to a tagged set using a plus sign (`+`) before the qualifier name.
For example, you cannot add a `user` qualifier to a tagged set that already contains a `user` qualifier.
If you need to track two users with the same error, create two tagged sets, one per user.

You can remove a qualifier from a tagged set using a minus sign (`-`) before the qualifier name, such as `-user`.
When you remove the last qualifier from a tagged set, the tagged set is removed.

You can specify multiple tagged sets.
In this case, completed requests are logged if they match all of the qualifiers in any of the tagged sets.

You can also specify a mixture of tagged sets and individual qualifiers.
In this case, completed requests are logged if they match any of the individual qualifiers, or all of the qualifiers in any of the tagged sets.

### Completed Threshold

The `completed-threshold` field provides another way of specifying the `threshold` qualifier within the `completed` field.

This field sets the minimum request duration after which requests are added to the `system:completed_requests` catalog.
The default value is 1000&#160;ms.
Specify `0` to log all requests and `-1` to not log any requests to the keyspace.

To specify a different value, use:

```sh
curl $BASE_URL/admin/settings -u $USER:$PASSWORD \
  -H 'Content-Type: application/json' \
  -d '{"completed-threshold":0}'
```

### Completed Limit

The `completed-limit` field sets the number of most recent requests to be tracked in the `system:completed_requests` catalog.
The default value is 4000.
Specify `0` to not track any requests and `-1` to set no limit.

To specify a different value, use:

```sh
curl $BASE_URL/admin/settings -u $USER:$PASSWORD \
  -H 'Content-Type: application/json' \
  -d '{"completed-limit":1000}'
```

**📌 NOTE**\
To optimize performance, the completed requests catalog uses a generic cache that does not guarantee a strict eviction order.
When the catalog reaches the specified limit, it evicts requests based on when they complete, and not when they start.
As a result, it may remove a request with a later start time (`requestTime`) that completes quickly before it removes a long-running request with an earlier start time that completes later.

## Stream Completed Requests

Couchbase Server 7.6.4

In Couchbase Server 7.6.4 and later, you can stream completed requests to disk.

To enable completed request streaming, use the [Admin REST API](n1ql:n1ql-rest-api/admin.adoc) `/admin/settings` endpoint to specify the `completed-stream-size` property.

```sh
curl $BASE_URL/admin/settings -u $USER:$PASSWORD \
  -H 'Content-Type: application/json' \
  -d '{"completed-stream-size": 500}'
```

This property is a file size in MiB.
When set to `0` (the default), completed request streaming is disabled.

When set to any size greater than `0`, completed requests are streamed to archive files.
The value of this property determines the size of the data to retain, per node.
The configuration for completed requests determines which requests are saved.

**📌 NOTE**\
The additional processing required to save completed requests to disk may limit overall request throughput on a Query node, but typically only when every completed request is being recorded, and requests are small or short-lived.
The speed of the file system on which the server logs directory resides may affect the request throughput also.

### Archived Request Files

When streaming is enabled, completed requests are saved to GZIP archives with the prefix `local_request_log` in the Couchbase Server `logs` directory.
Each saved GZIP archive file contains multiple JSON entries, one for each for each recorded completed request.

Couchbase Server writes multiple archive files in parallel, so while the order of requests in a file is sequential, a single given file may not contain a contiguous sequence of requests.

When an archive file reaches or exceeds 100 MiB, it’s finalized and saved to disk.
This is not a hard limit -- entries are not truncated to adhere to it.
Files may also be finalized with less content, if nothing has been written to them for an extended period.
Files that are actively being written are not available for reading, and they do not count towards the configured size limit until they’re finalized.

Couchbase Server tries to manage and retain archive files such that the total disk space used by the files is within the specified limit for the node.
When the specified limit is reached, older files are removed as necessary to make space for newly finalized files.
When a file is removed, it’s not guaranteed that only the oldest requests are evicted, given that Couchbase Server writes to multiple archive files in parallel.

### View Archived Requests

To view archived completed requests, use [gzip](https://www.gnu.org/software/gzip) and [jq](https://jqlang.github.io/jq) on the command line, or a {sqlpp} query.

* **Command Line**

  To view all archived completed requests in `$FILE`:

  ```sh
  gzip -qdc $FILE | jq .
  ```
* **{sqlpp}**

  To get a list of archived completed requests using {sqlpp}:

  ```sqlpp
  SELECT * FROM system:completed_requests_history;
  ```

The `system:completed_requests_history` keyspace is provided for {sqlpp} access to the archived files, but as they’re external GZIP archives performance is restricted, particularly with large histories on clusters with multiple Query Service nodes.
Directly reading the files may be more useful in some cases.

## Query Profiling

Query profiling enables you to obtain more detailed monitoring information and finer execution timings for any query.
You can set query profiling to the following levels:

* `off` -- query profiling is disabled.
* `phases` -- query profiling is enabled, including information about the phases of query execution.
* `timings` -- query profiling is enabled, including information about the phases of query execution, and detailed timing information.

You can set query profiling in the following ways:

* At the [node level](#enable-query-profiling-for-a-query-node), so that it’s enabled for all queries on that node.
* At the [request level](#enable-query-profiling-for-a-request), for individual queries.

For more information about Query settings and parameters, see [n1ql:n1ql-manage/query-settings.adoc](n1ql:n1ql-manage/query-settings.adoc).

### Enable Query Profiling for a Query Node

To activate query profiling at the node level, specify the `profile` setting using the [Admin REST API](n1ql-rest-admin:index.adoc) (`/admin/settings` endpoint).

**See the current node-level query settings**

The following request gets the current node-level query settings.

**Request**

```sh
curl $BASE_URL/admin/settings -u $USER:$PASSWORD
```

**Results**

```json
{
  "atrcollection": "",
  "auto-prepare": false,
  "cleanupclientattempts": true,
  "cleanuplostattempts": true,
  "cleanupwindow": "1m0s",
  "completed": {
    "aborted": null,
    "threshold": 1000
  },
  "completed-limit": 4000,
  "completed-threshold": 1000,
  "controls": false,
  "cpuprofile": "",
  "debug": false,
  "functions-limit": 16384,
  "keep-alive-length": 16384,
  "loglevel": "INFO",
  "max-index-api": 4,
  "max-parallelism": 1,
  "memory-quota": 0,
  "memprofile": "",
  "mutexprofile": false,
  "n1ql-feat-ctrl": 76,
  "numatrs": 1024,
  "pipeline-batch": 16,
  "pipeline-cap": 512,
  "plus-servicers": 16,
  "prepared-limit": 16384,
  "pretty": false,
  "profile": "off",
  "request-size-cap": 67108864,
  "scan-cap": 512,
  "servicers": 4,
  "timeout": 0,
  "txtimeout": "0s",
  "use-cbo": true
}
```

**Save node-level query settings to a file**

The following request saves the current node-level query settings to the file `query_settings.json`.

**Request**

```sh
curl $BASE_URL/admin/settings -u $USER:$PASSWORD -o ./query_settings.json
```

**Set node-level query settings from a file**

Assuming that you have edited the file `query_settings.json` to specify the query settings you want, the following request
sets the node-level query settings according to the file.

**Request**

```sh
curl $BASE_URL/admin/settings -u $USER:$PASSWORD \
  -X POST \
  -d@./query_settings.json
```

**Set node-level query settings explicitly**

The following request explicitly sets query profiling at the node level.

**Request**

```sh
curl $BASE_URL/admin/settings -u $USER:$PASSWORD \
  -H 'Content-Type: application/json' \
  -d '{"profile": "phases"}'
```

**Results**

```json
{
  // ...
  "profile":"phases",
  "request-size-cap": 67108864,
  "scan-cap": 512,
  "servicers": 4,
  "timeout": 0,
  "txtimeout": "0s",
  "use-cbo": true
}
```

### Enable Query Profiling for a Request

To activate profiling at the request level, you can:

* Specify the `profile` setting using the [Query REST API](n1ql-rest-query:index.adoc) (`/query/service` endpoint).
* Specify the `profile` setting using the [cbq](n1ql:n1ql-intro/cbq.adoc) command line tool.

* **REST API**

  To set query settings using the REST API, specify the parameters in the request body.

  ---

  The following statement sets the profiling to phases:

  ```sh
  curl $BASE_URL/query/service -u $USER:$PASSWORD \
    -d 'profile=phases&statement=SELECT * FROM `travel-sample`.inventory.airline LIMIT 1'
  ```

  The following statement sets the profiling to timings:

  ```sh
  curl $BASE_URL/query/service -u $USER:$PASSWORD \
    -d 'profile=timings&statement=SELECT * FROM `travel-sample`.inventory.airline LIMIT 1'
  ```
* **{sqlpp}**

  To set query settings using the cbq shell, use the `\SET` command.

  ---

  The following statement sets the profiling to phases:

  ```sqlpp
  \set -profile "phases";
  SELECT * FROM `travel-sample`.inventory.airline LIMIT 1;
  ```

  The following statement sets the profiling to timings:

  ```sqlpp
  \set -profile "timings";
  SELECT * FROM `travel-sample`.inventory.airline LIMIT 1;
  ```

The Query Workbench automatically enables Query profiling, with detailed timing information.
To disable or enable Query profiling with the Query Workbench, specify the **Collect query timings** option using the [Query Preferences](tools:query-workbench.adoc#query-preferences).

## Query Profiling Details

You can access the profiling information in the following ways:

* In the [query responses](#profiling-details-in-query-responses).
* In the [system catalogs](#profiling-details-in-system-catalogs).

When a query executes a user-defined function, profiling information is available for the {sqlpp} queries within the user-defined function as well.

### Profiling Details in Query Responses

When profiling is enabled:

* If you’re using the cbq shell or the Query REST API, query profiling information is returned with the query results.
* If you’re using the Query workbench, query profiling information is not returned with the query results.

**Phases Profile**

If you’re using the cbq shell or the Query REST API, the following statistics are returned when `profile` is set to `phases`:

```json
{
  "requestID": "06d6c1c2-1a8a-4989-a856-7314f9eddee5",
  "signature": {
    "*": "*"
  },
  "results": [
    {
      "airline": {
        "callsign": "MILE-AIR",
        "country": "United States",
        "iata": "Q5",
        "icao": "MLA",
        "id": 10,
        "name": "40-Mile Air",
        "type": "airline"
      }
    }
  ],
  "status": "success",
  "metrics": {
    "elapsedTime": "12.77927ms",
    "executionTime": "12.570648ms",
    "resultCount": 1,
    "resultSize": 254,
    "serviceLoad": 12
  },
  "profile": {
    "phaseTimes": {
      "authorize": "19.629µs",
      "fetch": "401.997µs",
      "instantiate": "147.686µs",
      "parse": "4.545234ms",
      "plan": "409.364µs",
      "primaryScan": "6.103775ms",
      "run": "6.699056ms"
    },
    "phaseCounts": {
      "fetch": 1,
      "primaryScan": 1
    },
    "phaseOperators": {
      "authorize": 1,
      "fetch": 1,
      "primaryScan": 1
    },
    "requestTime": "2021-04-30T18:37:56.394Z",
    "servicingHost": "127.0.0.1:8091"
  }
}
```

**Timings Profile**

If you’re using the cbq shell or the Query REST API, the following statistics are returned when `profile` is set to `timings`:

```json
{
  "requestID": "268a1240-6864-43a2-af13-ccb8d1e50abf",
  "signature": {
    "*": "*"
  },
  "results": [
    {
      "airline": {
        "callsign": "MILE-AIR",
        "country": "United States",
        "iata": "Q5",
        "icao": "MLA",
        "id": 10,
        "name": "40-Mile Air",
        "type": "airline"
      }
    }
  ],
  "status": "success",
  "metrics": {
    "elapsedTime": "2.915245ms",
    "executionTime": "2.755355ms",
    "resultCount": 1,
    "resultSize": 254,
    "serviceLoad": 12
  },
  "profile": {
    "phaseTimes": {
      "authorize": "18.096µs",
      "fetch": "388.122µs",
      "instantiate": "31.702µs",
      "parse": "646.157µs",
      "plan": "120.427µs",
      "primaryScan": "1.402918ms",
      "run": "1.936852ms"
    },
    "phaseCounts": {
      "fetch": 1,
      "primaryScan": 1
    },
    "phaseOperators": {
      "authorize": 1,
      "fetch": 1,
      "primaryScan": 1
    },
    "requestTime": "2021-04-30T18:40:13.239Z",
    "servicingHost": "127.0.0.1:8091",
    "executionTimings": {
      "#operator": "Authorize",
      "#stats": {
        "#phaseSwitches": 4,
        "execTime": "1.084µs",
        "servTime": "17.012µs"
      },
      "privileges": {
        "List": [
          {
            "Target": "default:travel-sample.inventory.airline",
            "Priv": 7,
            "Props": 0
          }
        ]
      },
      "~child": {
        "#operator": "Sequence",
        "#stats": {
          "#phaseSwitches": 1,
          "execTime": "2.474µs"
        },
        "~children": [
          {
            "#operator": "PrimaryScan3",
            "#stats": {
              "#itemsOut": 1,
              "#phaseSwitches": 7,
              "execTime": "18.584µs",
              "kernTime": "8.869µs",
              "servTime": "1.384334ms"
            },
            "bucket": "travel-sample",
            "index": "def_inventory_airline_primary",
            "index_projection": {
              "primary_key": true
            },
            "keyspace": "airline",
            "limit": "1",
            "namespace": "default",
            "scope": "inventory",
            "using": "gsi"
          },
          {
            "#operator": "Fetch",
            "#stats": {
              "#itemsIn": 1,
              "#itemsOut": 1,
              "#phaseSwitches": 10,
              "execTime": "25.64µs",
              "kernTime": "1.427752ms",
              "servTime": "362.482µs"
            },
            "bucket": "travel-sample",
            "keyspace": "airline",
            "namespace": "default",
            "scope": "inventory"
          },
          {
            "#operator": "InitialProject",
            "#stats": {
              "#itemsIn": 1,
              "#itemsOut": 1,
              "#phaseSwitches": 9,
              "execTime": "6.006µs",
              "kernTime": "1.825917ms"
            },
            "result_terms": [
              {
                "expr": "self",
                "star": true
              }
            ]
          },
          {
            "#operator": "Limit",
            "#stats": {
              "#itemsIn": 1,
              "#itemsOut": 1,
              "#phaseSwitches": 4,
              "execTime": "2.409µs",
              "kernTime": "2.094µs"
            },
            "expr": "1"
          },
          {
            "#operator": "Stream",
            "#stats": {
              "#itemsIn": 1,
              "#itemsOut": 1,
              "#phaseSwitches": 6,
              "execTime": "46.964µs",
              "kernTime": "1.844828ms"
            }
          }
        ]
      },
      "~versions": [
        "7.0.0-N1QL",
        "7.0.0-4960-enterprise"
      ]
    }
  }
}
```

For field names and meanings, see [Profile](n1ql-rest-query:index.adoc#ResponseProfile).

### Profiling Details in System Catalogs

The [system:active_requests](#monitor-and-manage-active-requests) and [system:completed_requests](#monitor-and-manage-completed-requests) system catalogs always return profiling information regarding query phases: namely, phase times, phase counts, and phase operators.

The [system:active_requests](#monitor-and-manage-active-requests), [system:completed_requests](#monitor-and-manage-completed-requests), and [system:prepareds](#monitor-and-manage-prepared-statements) system catalogs also support the `meta().plan` virtual attribute.
This captures the whole query plan, and includes profiling information regarding execution timings.

To get execution timing information from these system catalogs, you must explicitly specify `meta().plan` in the projection list for the SELECT query.

Within these system catalogs, not all statements have a `meta().plan` attribute.

* With [system:active_requests](#monitor-and-manage-active-requests) and [system:completed_requests](#monitor-and-manage-completed-requests), the `meta().plan` attribute is only available for statements that you run when profile is set to `timings`.
* With [system:prepareds](#monitor-and-manage-prepared-statements), the `meta().plan` attribute is available for all statements.

<dl><dt><strong>📌 NOTE</strong></dt><dd>

When request profiling is set to `timings`, profiling information is likely to use 100KB+ per entry in the `system:completed_requests` keyspace.

* Due to the added overhead of running both profiling and [logging](manage:manage-logging/manage-logging.adoc), turn on both of them only when needed.
Running only one of them continuously has no noticeable affect on performance.
* Profiling does not carry any extra cost beyond memory for completed requests, so it’s fine to run it continuously.
</dd></dl>

<a name="example-2"></a>**Plan Details**

Getting the plan for a statement that you ran when the profile was set to `timings` returns results similar to the following.

```json
[
  {
  // ...
    "plan": {
      "#operator": "Authorize",
      "#stats": {
        "#phaseSwitches": 4,
        "execTime": "1.725µs",
        "servTime": "21.312µs"
      },
      "privileges": {
        "List": [
          {
            "Priv": 7,
            "Props": 0,
            "Target": "default:travel-sample.inventory.route"
          }
        ]
      },
      "~child": {
        "#operator": "Sequence",
        "#stats": {
          "#phaseSwitches": 2,
          "execTime": "1.499µs"
        },
        "~children": [
          {
            "#operator": "PrimaryScan3",
            "#stats": {
              "#heartbeatYields": 6,
              "#itemsOut": 24024,
              "#phaseSwitches": 96099,
              "execTime": "84.366121ms",
              "kernTime": "3.021901421s",
              "servTime": "69.320752ms"
            },
            "bucket": "travel-sample",
            "index": "def_inventory_route_primary",
            "index_projection": {
              "primary_key": true
            },
            "keyspace": "route",
            "namespace": "default",
            "scope": "inventory",
            "using": "gsi"
          },
          {
            "#operator": "Fetch",
            "#stats": {
              "#heartbeatYields": 7258,
              "#itemsIn": 24024,
              "#itemsOut": 24024,
              "#phaseSwitches": 99104,
              "execTime": "70.34694ms",
              "kernTime": "142.630196ms",
              "servTime": "3.021959695s"
            },
            "bucket": "travel-sample",
            "keyspace": "route",
            "namespace": "default",
            "scope": "inventory"
          },
          {
            "#operator": "InitialProject",
            "#stats": {
              "#itemsIn": 24024,
              "#itemsOut": 24024,
              "#phaseSwitches": 96100,
              "execTime": "15.331951ms",
              "kernTime": "3.219612458s"
            },
            "result_terms": [
              {
                "expr": "self",
                "star": true
              }
            ]
          },
          {
            "#operator": "Order",
            "#stats": {
              "#itemsIn": 24024,
              "#itemsOut": 24024,
              "#phaseSwitches": 72078,
              "execTime": "147.889352ms",
              "kernTime": "3.229055752s"
            },
            "sort_terms": [
              {
                "expr": "(`route`.`sourceairport`)"
              }
            ]
          },
          {
            "#operator": "Stream",
            "#stats": {
              "#itemsIn": 24024,
              "#itemsOut": 24024,
              "#phaseSwitches": 24025,
              "execTime": "11.851634134s"
            }
          }
        ]
      },
      "~versions": [
        "7.0.0-N1QL",
        "7.0.0-4960-enterprise"
      ]
    }
  }
]
```

For field names and meanings, see [Execution Timings](n1ql-rest-query:index.adoc#ResponseProfileTiming).

## Query Profiling Summary

The following table summarizes Query profiling behavior.

| Profile is ... 3+s |
| --- | --- | --- | --- | --- | --- | --- |
| Query returns ... 3+s | Catalog includes ... | {blank} | cbq | REST API | Query<br> workbench | Active<br> Requests |
| Completed<br> Requests | Prepared<br> Statements | `off` | {blank} | {blank} | {blank} | icon:check[fw] phases |
| icon:check[fw] phases | icon:check[fw] timings | `phases` | icon:check[fw] phases | icon:check[fw] phases | {blank} | icon:check[fw] phases |
| icon:check[fw] phases | icon:check[fw] timings | `timings` | [%hardbreaks] icon:check[fw] phases icon:check[fw] timings | [%hardbreaks] icon:check[fw] phases icon:check[fw] timings | {blank} | [%hardbreaks] icon:check[fw] phases icon:check[fw] timings |

## Related Links

* For more information on the system namespace, see [Getting System Information](n1ql:n1ql-intro/sysinfo.adoc).
