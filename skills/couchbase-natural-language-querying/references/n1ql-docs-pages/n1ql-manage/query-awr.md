# Automatic Workload Repository

Monitor and optimize query performance and workload using Automatic Workload Repository (AWR).

## Overview

Automatic Workload Repository (AWR) is a feature that captures and maintains performance statistics for queries executed on your Couchbase cluster.
It acts as a centralized repository for query performance data, enabling you to track query activities, analyze workload trends, and identify performance bottlenecks.

For example, some queries may run efficiently with minimal overhead, while others may consume more resources or take longer to complete.
With AWR, you can understand these differences and optimize your queries accordingly.
It also allows you to generate reports to compare query performances over time.

When enabled, AWR automatically gathers detailed metrics from the Query Service for every query that you run on your cluster.
These metrics include execution time, CPU usage, memory consumption, number of executions, and more.
It then aggregates this data into [snapshots](#snapshots) and stores them in a [workload repository](#workload-repository).

You can access the collected data by directly querying the repository or by using Couchbase’s report generation tool.
For more information, see [View AWR Data and Reports](#view-awr-data-and-reports).

## Use Cases

Here are some use cases of AWR:

* ***Troubleshooting Real-Time Issues***:
You can quickly identify slow running queries or instances of high resource usage.
You can extract the SQL ID of the problematic query from the AWR report and use it to trace the query in [completed_requests](n1ql:n1ql-manage/monitoring-n1ql-query.adoc#sys-completed-req).
* ***Analyzing Performance***:
When rolling out changes, such as introducing new microservices, AWR lets you compare query performance before and after the update.
* ***Analyzing Upgrade Impacts***:
You can assess query performance before and after a cluster upgrade to identify queries impacted by the new version.

## Workload Repository

The workload repository is a centralized storage location where all AWR data is collected and maintained.

Before AWR can start collecting data, you must configure this location in the [system:awr](#systemawr) catalog.
The repository can be a bucket or a collection, but not a scope.

If you specify only the bucket name, AWR uses the default scope (`_default`) and default collection (`_default`) within that bucket to store the data.
If the bucket or collection does not exist, you must create it.

For example, a valid location is `travel-sample._default.awr`, which you can create using the following query:

```sqlpp
CREATE COLLECTION `travel-sample`._default.awr IF NOT EXISTS;
```

AWR checks the availability of repository location at the start of each reporting interval.
Until this specified location is available, AWR remains in a quiescent (inactive) state.
Once the location becomes accessible, AWR transitions to an active state and begins collecting data.
If the location becomes unavailable at any point, AWR returns to the quiescent state and resumes activity only when the location is accessible again.

For more information about setting up the repository location, see [Enable and Configure AWR](#enable-and-configure-awr).

## Snapshots

AWR stores query performance data in the form of snapshots.
For each unique statement executed within a specified reporting interval, AWR generates a snapshot.
This snapshot contains aggregate metrics for all executions of that statement during the interval.
These metrics include execution time, CPU usage, memory consumption, and other performance indicators.

Snapshots are stored as individual documents in the workload repository.
Each document is uniquely identified by its document key (ID), which includes the start time of the reporting interval, making it easier to filter and analyze data.

### Snapshot Retention Management

AWR retains snapshot documents for long-term analysis, but does not enforce retention policies by default.
To manage storage effectively, you need to configure a Time-To-Live (TTL) or expiration for the AWR location.
The TTL specifies how long the documents remain in that location before the system automatically purges them.
For more information about configuring the TTL, see [Expiration](server:learn:data/expiration.adoc).

### Example

**Set TTL on AWR Collection**

If you set a TTL of 7 days on a target AWR collection, say `travel-sample._default.awr`, all snapshot documents older than 7 days are automatically deleted.
To create the collection with this TTL setting, use the following query:

```sqlpp
CREATE COLLECTION `travel-sample`._default.awr IF NOT EXISTS WITH { "maxTTL": (7*24*60*60) };
```

For more information about creating collections, see [CREATE COLLECTION](n1ql:n1ql-language-reference/createcollection.adoc).

## Enable and Configure AWR

AWR is an opt-in feature that you must explicitly enable and configure.
Once enabled, AWR starts collecting data as soon as the repository location is set and is available.

You can manage these settings through the [system:awr](#systemawr) catalog.

### system:awr

This catalog determines how AWR functions including where it stores snapshots, how often it collects statistics, and which queries to include in the report.
You can adjust these settings using an UPDATE query on `system:awr`.

**📌 NOTE**\
Only admins or users with the `query_manage_system_catalog` role can modify settings in `system:awr`.
For more information, see [Authentication and Client Privileges](n1ql:n1ql-intro/sysinfo.adoc#authentication-and-client-privileges).

The catalog consists of the following attributes:

| Name | Description | Schema |
| --- | --- | --- |
| ***enabled*** + | Indicates whether AWR is enabled or disabled. **Default**: `FALSE` | Boolean |
| ***location*** + | The target keyspace (repository) where the snapshots are stored. This can only be a path to a bucket or collection; it cannot be a scope. For more information, see [Workload Repository](#workload-repository). **Example**: `"travel-sample._default.awr"` or `"travel-sample"`, in which case it uses the default scope and default collection. | String |
| ***interval*** + | The duration of the reporting interval. That is, the time between each snapshot collection. If the interval is set to 10 minutes, AWR captures snapshots every 10 minutes. The interval must be at least 1 minute. **Default**: `"10m0s"` ***Example***: `"1m30s"` | String (duration) |
| ***threshold*** + | The minimum time a statement must take to complete for it be captured and included in the snapshot. The threshold must be at least 0 seconds. **Default**: `"0s"`, so that by default, all statements are captured by AWR regardless of their execution time. ***Example***: `"1m30s"` | String (duration) |
| ***num_statements*** + | The maximum number of unique statements for which aggregate data is collected during each interval. Once the specified limit is reached during a reporting interval, AWR does not generate snapshots for any additional unique statements within that same interval. **Default**: `10000` **Max**: `100000` | Positive integer |
| ***queue_len*** + | Length of the processing queue. It’s recommended not to change this value. The default value and maximum allowable value for `queue_len` are internally calculated based on system resources. | Positive integer |

### Examples

**Enable AWR and configure settings**

The following query enables AWR, sets the repository location to `travel-sample._default.awr`, and configures the reporting interval and threshold.

```sqlpp
UPDATE system:awr SET enabled = true, location = "`travel-sample`._default.awr",
interval = "1m", threshold = "0s";
```
If you execute this query in the Query Workbench, you’ll get a warning about running an UPDATE query without specifying a WHERE clause or USE KEYS.
You can ignore this warning and proceed.

**Retrieve current AWR settings**

The following query retrieves the current AWR configuration settings.

**Query**

```sqlpp
SELECT * FROM system:awr;
```

**Result**

```json
[
  {
    "awr": {
      "enabled": true,
      "interval": "1m0s",
      "location": "`default`:`travel-sample`.`_default`.`awr`",
      "num_statements": 10000,
      "queue_len": 160,
      "threshold": "0s"
    }
  }
]
```

## Monitor AWR

The current status of AWR is recorded in the `query.log` and you can view this information in the [system:vitals](n1ql:n1ql-manage/monitoring-n1ql-query.adoc#vitals) output.

**Query AWR status in system:vitals**

**Query**

```sqlpp
SELECT awr FROM system:vitals;
```

**Result**

```json
[
  {
    "awr": {
      "requests": 11,
      "snapshots": 6,
      "start": "2025-09-26T05:10:44.789Z",
      "state": "active"
    }
  }
]
```

## View AWR Data and Reports

You can access the AWR data by:

* [Using the report generation tool](#report-generation-tool)
* [Querying AWR data directly](#querying-awr-data-directly)

### Report Generation Tool

You can generate AWR reports using the [cbqueryreportgen](cli:cbqueryreportgen.adoc) command line tool.
It provides comprehensive and user-friendly reports by executing SQL++ queries against the collected AWR data.

For optimal query performance with this tool, it is recommended to create an index on the document key (`META().id`) in your configured AWR location.
If this index is not present, the tool will use sequential scans, which can impact performance.

For example, if the target location is `travel-sample._default.awr`, you can create an index as follows:

```sqlpp
CREATE INDEX idx_awr ON `travel-sample`._default.awr(META().id);
```

### Querying AWR Data Directly

You can query AWR data directly from the workload repository using SQL++ queries.

The document keys (IDs) of the snapshot documents include the timestamp of the reporting interval’s start time.
This allows you to filter documents based on time ranges without requiring additional indexes (as sequential scans support range-based key patterns).
However, you can add indexes to further optimize your queries, if needed.

Each document contains the following fields:

| Name | Description | Schema |
| --- | --- | --- |
| ***cnt*** + | The number of times the statement was executed. | Number |
| ***from*** + | The start time of the interval, represented as an Epoch timestamp in milliseconds. | Number |
| ***to*** + | The end time of the interval, represented as an Epoch timestamp in milliseconds. | Number |
| ***pln*** + | An array containing the encoded, compressed outlines of the execution plan for both the minimum and maximum execution times of the statement. This is just the outline of the plan listing operators and significant objects used. For full execution details, configure the [completed_requests](n1ql:n1ql-manage/monitoring-n1ql-query.adoc#sys-completed-config) system keyspace to capture the executions of the statement. You can use [UNCOMPRESS()](n1ql:n1ql-language-reference/stringfun.adoc#fn-str-uncompress) to decompress the execution plan strings, and then pass them to [DECODE_JSON()](n1ql:n1ql-language-reference/jsonfun.adoc) for formatting, if needed. | Array of strings |
| ***qc*** + | The query context value. | String |
| ***sqlID*** + | The unique hash identifier of the statement. This can be used to aggregate information across different reporting periods for the same statement. It’s also included in the [completed_requests](n1ql:n1ql-manage/monitoring-n1ql-query.adoc#sys-completed-req) entries (collected independently of AWR). | String |
|[Statistics](#statistics) array

|***txt***\
| The statement text, possibly in a compressed format.

Typically, this field is accessed using the [UNCOMPRESS()](n1ql:n1ql-language-reference/stringfun.adoc#fn-str-uncompress) function, and the function returns the raw text if it is not compressed.

| String

|***ver***\
| The version of the data record.

For this release, the value is always 1.

| Number

#### Statistics
| Name | Description | Schema |
| --- | --- | --- |
| ***total time*** + | The total time taken for the request, that is the time from when the request was received until the results were returned. This includes time spent in the queue and is analogous to `elapsedTime` in the [Query REST API](n1ql-rest-query:index.adoc#Metrics) response. | Number |
| ***cpu time*** + | The amount of time the operators in the execution plan spent executing operator code. This is analogous to `cpuTime` in the [Query Service API](n1ql-rest-query:index.adoc#Metrics) response when [profiling](n1ql-rest-query:index.adoc#Profile) is enabled. | Number |
| ***memory usage (quota)*** + | The amount of document memory used to execute the request. A request will return its document memory usage only if `memory-quota` is set for the query, or if both `node-quota` and `node-quota-val-percent` are set. For more information about these settings, see [n1ql:n1ql-manage/query-settings.adoc](n1ql:n1ql-manage/query-settings.adoc). This is analogous to `usedMemory` in the [Query Service API](n1ql-rest-query:index.adoc#Metrics) response. | Number |
| ***result count*** + | The total number of objects in the results. This is analogous to `resultCount` in the [Query Service API](n1ql-rest-query:index.adoc#Metrics) response. | Number |
| ***result size*** + | The total number of bytes in the results. This is analogous to `resultSize` in the [Query Service API](n1ql-rest-query:index.adoc#Metrics) response. | Number |
| ***error count*** + | The number of errors that occurred during the request. This is analogous to `errorCount` in the [Query Service API](n1ql-rest-query:index.adoc#Metrics) response. | Number |
| ***run time*** + | The total amount of time taken to execute the query. It does not include time spent in the queue. | Number |
| ***fetch time*** + | The total amount of time spent fetching data from the Data service. This includes the time spent executing `Fetch` operator code and waiting for data from the Data service. | Number |
| ***primary scan time*** + | The total amount of time spent by primary scan operations. This includes the time spent executing the `PrimaryScan` operator code and waiting for data from the Index service. | Number |
| ***sequential scan time*** + | The amount of time spent by sequential scan operations. This includes the time spent executing the `PrimaryScan` operator code and waiting for data from the Data service. | Number |
| ***primary scan count*** + | The total number of index keys returned by primary index scans and processed by the Query engine. | Number |
| ***sequential scan count*** + | The total number of document keys returned by sequential scans and processed by the Query engine. | Number |
| ***index scan count*** + | The total number of items returned by index scans and processed by the Query engine. | Number |
| ***fetch count*** + | The total number of documents fetched from the Data service and processed by the Query engine. | Number |
| ***order count*** + | The number of items that were sorted. | Number |
| ***primary scan ops*** + | The number of primary scan operators in the execution plan. | Number |
| ***sequential scan ops*** + | The number of sequential scan operators in the execution plan. | Number |

### Example
The following example fetches AWR data for a specific SQL ID, including the statement text, max execution plan, number of executions, total time, and max CPU usage.

**Query**

```sqlpp
SELECT
    text,
    max_plan,
    the_count,
    avg_total_time,
    max_cpu
FROM
    default.s1.awr
LET
    text = uncompress(txt)
WHERE
    sqlID = 'fcff011269f93c3b7903d746c2914dab'
GROUP BY
    sqlID, text
LETTING
    the_count = SUM(cnt),
    max_plan = json_decode(uncompress(MAX(pln[1]))),
    avg_total_time = duration_to_str(SUM(sts[0])/SUM(cnt)),
    max_cpu = duration_to_str(MAX(sts[5]));
```

**Result**

```json
[
    {
        "text": "select awr from system:vitals;",
        "max_plan": {
            "#operator": "Sequence",
            "~children": [
                {
                    "#operator": "PrimaryScan",
                    "index_id": "#primary",
                    "keyspace": "vitals"
                },
                {
                    "#operator": "Fetch",
                    "keyspace": "vitals"
                },
                {
                    "#operator": "InitialProject"
                },
                {
                    "#operator": "Stream"
                }
            ]
        },
        "the_count": 2,
        "avg_total_time": "38.844257ms",
        "max_cpu": "193.409µs"
    }
]
```

## Limitations

* In AWR reports, COMMIT statements may often show the highest elapsed time.
However, the report alone does not provide insights into why the statement took so long to execute.
* AWR does not capture SQL++ statements that contain sensitive information, such as CREATE USER and ALTER USER.
* In some cases, SQL++ statements may appear truncated in AWR reports or snapshot documents.
To find the complete statement, use its `sqlID` to look for entries in [completed_requests](n1ql:n1ql-manage/monitoring-n1ql-query.adoc#sys-completed-req) that have the same `sqlID`.
Then use one of those entries to get the full statement text.

## See Also

* [Report Generation CLI Tool](cli:cbqueryreportgen.adoc)
* [CREATE COLLECTION Statement](n1ql:n1ql-language-reference/createcollection.adoc)
* [Monitor Completed Requests](n1ql:n1ql-manage/monitoring-n1ql-query.adoc#sys-completed-req)
* [Monitor System Vitals](n1ql:n1ql-manage/monitoring-n1ql-query.adoc#vitals)
* [Data Expiration and TTL](server:learn:data/expiration.adoc)
