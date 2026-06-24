---
# frontmatter
path: '/tutorial-identifying-top-slow-queries'
title: Identifying the Top Slow Queries
short_title: Identify Slow Queries
description: 
  - The first step of speeding up your queries is figuring out which ones are slow
  - In this tutorial, we'll explore how to determine which queries run the slowest
  - Learn about querying the system catalog and discover all the properties available from it
content_type: tutorial
filter: n1ql
technology:
  - query
  - server
tags:
  - SQL++ (N1QL)
  - Optimization
sdk_language:
  - any
length: 15 Mins
---

The top slow queries can be identified by querying the system catalog using the following select statement (available on version Couchbase 4.5 and above)

```sql
select * from system:completed_requests
```

The `system:completed_requests` catalog maintains a list of the most recent (4000 by default) completed requests that have run longer than a predefined threshold of time (>=1000ms by default). This information provides a general insight into the health and performance of the query engine and the cluster.

You can configure the `system:completed_requests` catalog by specifying the parameters as command-line options for the cbq-engine.

- `completed-threshold`: Sets the minimum request duration after which requests are added to the `system:completed_requests` catalog. The default value is 1000ms. Specify 0 to log all requests and -1 to not log any requests to the catalog.
  - To specify a different value, use: `cbq-engine -completed-threshold=500`
- `completed-limit`: Sets the number of most recent requests to be tracked in the `system:completed_requests` catalog. The default value is 4000. Specify 0 to not track any requests and -1 to set no limit.
  - To specify a different value, use: `cbq-engine -completed-limit=1000`

You can also set these parameters through the [Admin API settings endpoint](https://docs.couchbase.com/server/current/settings/query-settings.html):

```bash
curl -X POST \
  -u Administrator:password \
  -d '{ "completed-threshold": 500, "completed-limit": 2000 }' \
  http://localhost:8093/admin/settings
```

## system:completed_requests Properties

```json
[
  {
    "clientContextID": "MYAPP-23fce132-050b-4ca3-9369-745b579cfad4",
    "elapsedTime": "1.149392493s",
    "errorCount": 0,
    "node": "127.0.0.1:8091",
    "phaseCounts": {
      "fetch": 35,
      "primaryScan": 35,
      "sort": 2
    },
    "phaseOperators": {
      "authorize": 1,
      "fetch": 4,
      "primaryScan": 4,
      "sort": 1
    },
    "remoteAddr": "127.0.0.1:37149",
    "requestId": "1fd6b7e9-8021-4872-98a8-a07908107674",
    "requestTime": "2019-02-08 00:41:12.722504817 +0000 UTC",
    "resultCount": 2,
    "resultSize": 381,
    "scanConsistency": "unbounded",
    "serviceTime": "1.149185373s",
    "state": "completed",
    "statement": "SELECT type, rendition, score, segment FROM `api` WHERE type = 'linearSegment' AND rendition = 'master:c32ae827:162800' ORDER BY score DESC LIMIT 1",
    "userAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_2)",
    "users": "Administrator"
  }
]
```

| Property        | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| :-------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| clientContextID | The opaque ID or context provided by the client.                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| elapsedTime     | The time taken from when the request was acknowledged by the service to when the request was completed. It includes the time taken by the service to schedule the request.                                                                                                                                                                                                                                                                                                                          |
| errorCount      | Total number of errors encountered while executing the query.                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| executionTime   | The duration of the query from when it started executing to when it completed.                                                                                                                                                                                                                                                                                                                                                                                                                      |
| node            | IP address and port of the query engine node in the Couchbase Cluster.                                                                                                                                                                                                                                                                                                                                                                                                                              |
| phaseCounts     | Count of documents processed at selective phases involved in the query execution, such as authorize, indexscan, fetch, parse, plan, run etc.                                                                                                                                                                                                                                                                                                                                                        |
| phaseOperators  | Indicates the number of each kind of query operators involved in different phases of the query processing. For instance, this example, one non covering index path was taken, which involves 1 indexScan and 1 fetch operators. <br><br>A join would have probably involved 2 fetches (1 per keyspace) <br><br>A union select would have twice as many operator counts (1 per each branch of the union). <br><br>This is in essence the count of all the operators in the `executionTimings` field. |
| remoteAddr      | IP address and port number of the client application, from where the query is received.                                                                                                                                                                                                                                                                                                                                                                                                             |
| requestId       | Unique request ID internally generated for the query.                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| requestTime     | Timestamp when the query is received.                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| resultCount     | Total number of documents returned in the query result.                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| resultSize      | Total number of bytes returned in the query result.                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| scanConsistency | The value of the query setting Scan Consistency used for the query.                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| serviceTime     | Total amount of calendar time taken to complete the query.                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| state           | The state of the query execution, such as completed, in progress, cancelled.                                                                                                                                                                                                                                                                                                                                                                                                                        |
| statement       | The N1QL query statement being executed.                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| userAgent       | Name of the client application or program that issued the query.                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| users           | Username with whose privileges the query is run.                                                                                                                                                                                                                                                                                                                                                                                                                                                    |

The `system:completed_requests` catalog can be queried against just like any other keyspace (bucket) in Couchbase.

### Longest Running Queries

First target and tune the queries that take the most amount of time.

```sql
SELECT statement,
    DURATION_TO_STR(avgServiceTime) AS avgServiceTime,
    COUNT(1) AS queries
FROM system:completed_requests
WHERE UPPER(statement) NOT LIKE 'INFER %'
    AND UPPER(statement) NOT LIKE 'CREATE INDEX%'
    AND UPPER(statement) NOT LIKE '% SYSTEM:%'
GROUP BY statement
LETTING avgServiceTime = AVG(STR_TO_DURATION(serviceTime))
ORDER BY avgServiceTime DESC
```

### Most Frequent Queries

Secondly, target the queries which occur most frequently.

```sql
SELECT statement,
    COUNT(1) AS queries
FROM system:completed_requests
WHERE UPPER(statement) NOT LIKE 'INFER %'
    AND UPPER(statement) NOT LIKE 'CREATE INDEX%'
    AND UPPER(statement) NOT LIKE '% SYSTEM:%'
GROUP BY statement
LETTING queries = COUNT(1)
ORDER BY queries DESC
```

### Largest Result Size Queries

```sql
SELECT statement,
    (avgResultSize) AS avgResultSizeBytes,
    (avgResultSize / 1000) AS avgResultSizeKB,
    (avgResultSize / 1000 / 1000) AS avgResultSizeMB,
    COUNT(1) AS queries
FROM system:completed_requests
WHERE UPPER(statement) NOT LIKE 'INFER %'
    AND UPPER(statement) NOT LIKE 'CREATE INDEX%'
    AND UPPER(statement) NOT LIKE '% SYSTEM:%'
GROUP BY statement
LETTING avgResultSize = AVG(resultSize)
ORDER BY avgResultSize DESC
```

### Largest Result Count Queries

```sql
SELECT statement,
    avgResultCount,
    COUNT(1) AS queries
FROM system:completed_requests
WHERE UPPER(statement) NOT LIKE 'INFER %'
    AND UPPER(statement) NOT LIKE 'CREATE INDEX%'
    AND UPPER(statement) NOT LIKE '% SYSTEM:%'
GROUP BY statement
LETTING avgResultCount = AVG(resultCount)
ORDER BY avgResultCount DESC
```

### Queries using a Primary Index

```sql
SELECT *
FROM system:completed_requests
WHERE phaseCounts.`primaryScan` IS NOT MISSING
    AND UPPER(statement) NOT LIKE '% SYSTEM:%'
ORDER BY resultCount DESC
```

### Queries that are Not very Selective

```sql
SELECT statement,
    diff
FROM system:completed_requests
WHERE phaseCounts.`indexScan` > resultCount
LETTING diff = AVG(phaseCounts.`indexScan` - resultCount)
ORDER BY diff DESC

```

### Queries Not Using a Covering Index

```sql
SELECT *
FROM system:completed_requests
WHERE phaseCounts.`indexScan` IS NOT MISSING
    AND phaseCounts.`fetch` IS NOT MISSING
ORDER BY resultCount DESC
```
