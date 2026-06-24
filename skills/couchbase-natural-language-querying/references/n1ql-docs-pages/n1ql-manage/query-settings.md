# Configure Queries

<style type="text/css">
  /* No maximum width for table cells */
  .doc table.spread > tbody > tr > *,
  .doc table.stretch > tbody > tr > * {
    max-width: none !important;
  }

  /* Wrap code listings in table cells */
  td .listingblock .content pre code {
    white-space: pre-wrap !important;
  }

  /* Ignore fixed column widths */
  table:not(.fixed-width) col{
    width: auto !important;
  }

  /* Wrap inline code in tables */
  td.tableblock p code,
  p.tableblock code{
    overflow-wrap: anywhere;
  }

  /* Do not hyphenate words in the table */
  td.tableblock p,
  p.tableblock{
    hyphens: manual;
  }

  /* Vertical alignment */
  td.tableblock{
    vertical-align: top !important;
  }
  /* Spacing for markdown blocks */
  .doc .openblock > .content > p {
    margin-top: 1rem;
  }

  .doc .openblock > .content > ul,
  .doc .openblock > .content > ol {
    margin-top: 1.5rem;
    margin-left: 1rem;
  }

  .doc .openblock > .content > ul li + li,
  .doc .openblock > .content > ol li + li {
    margin-top: 0.5rem;
  }
</style>

You can configure the Query Service using cluster-level query settings, node-level query settings, and request-level query parameters.

## Overview

You can configure the Query Service in the following ways:

* Specify cluster-level settings for all nodes running the Query Service in the cluster.
* Specify node-level settings for a single node running the Query Service.
* Specify parameters for individual requests.

You must set and use cluster-level query settings, node-level query settings, and request-level parameters in different ways.

**Comparison of Query Settings and Parameters**

|  | Set Per | Set By | Set On | Set Via |
| --- | --- | --- | --- | --- |
| Cluster-level query settings ^[[note](#service-level)]^ | Cluster | System administrator | Server side | The CLI, curl statements, or the UI |
| Node-level query settings ^[[note](#service-level)]^ | Service Node | System administrator | Server side | curl statements |
| Request-level parameters | Request (statement) | Each user | Client side | `cbq` shell, curl statements, client programming, or the UI |

**📌 NOTE**\
Cluster-level settings and node-level settings are collectively referred to as service-level settings.

## How Setting Levels Interact

Some query settings are cluster-level, node-level, or request-level only.
Other query settings apply to more than one level with slightly different names.

### How Cluster-Level Settings Affect Node-Level Settings

If a cluster-level setting has an equivalent node-level setting, then changing the cluster-level setting overwrites the node-level setting for all Query nodes in the cluster.

You can change a node-level setting for a single node to be different to the equivalent cluster-level setting.
Changing the node-level setting does not affect the equivalent cluster-level setting.
However, be aware that subsequent changes at the cluster-level may overwrite the node-level setting.
In particular, specifying query settings via the CLI or the UI makes changes at the cluster-level.

### How Node-Level Settings Affect Request-Level Parameters

If a request-level parameter has an equivalent node-level setting, the node-level setting usually acts as the default for the request-level parameter, as described in the tables below.
Setting a request-level parameter overrides the equivalent node-level setting.

Furthermore, for numeric values, if a request-level parameter has an equivalent node-level setting, the node-level setting dictates the upper-bound value of the request-level parameter.
For example, if the node-level `timeout` is set to 500, then the request-level parameter cannot be set to 501 or any value higher.

## All Query Settings

**Single-Level Settings -- Not Equivalent**

| Cluster-Level Only Settings | Node-Level Only Settings | Request-Level Only Parameters |
| --- | --- | --- |
| [%hardbreaks] [queryTmpSpaceDir](#queryTmpSpaceDir) [queryTmpSpaceSize](#queryTmpSpaceSize) [queryCurlWhitelist](#queryCurlWhitelist) | [%hardbreaks] [auto-prepare](#auto-prepare) [completed](#completed) [completed-stream-size](#completed-stream-size) [cpuprofile](#cpuprofile) [debug](#debug) [distribute](#distribute) [functions-limit](#functions-limit) [keep-alive-length](#keep-alive-length) [max-index-api](#max-index-api) [memprofile](#memprofile) [mutexprofile](#mutexprofile) [plus-servicers](#plus-servicers) [request-size-cap](#request-size-cap) [servicers](#servicers) | [%hardbreaks] [args](#args) [auto_execute](#auto_execute) [client_context_id](#client_context_id) [compression](#compression) [creds](#creds) [durability_level](#durability_level) [encoded_plan](#encoded_plan) (deprecated) [encoding](#encoding) [format](#format) [kvtimeout](#kvtimeout) [metrics](#metrics) [namespace](#namespace) [natural](#natural) [natural_cred](#natural_cred) [natural_orgid](#natural_orgid) [natural_context](#natural_context) [natural_output](#natural_output) [prepared](#prepared) [preserve_expiry](#preserve_expiry) [query_context](#query_context) [readonly](#readonly) [scan_consistency](#scan_consistency) [scan_vector](#scan_vector) [scan_vectors](#scan_vectors) [scan_wait](#scan_wait) [signature](#signature) [sort_projection](#sort_projection) [statement](#statement) [txid](#txid) [txstmtnum](#txstmtnum) [tximplicit](#tximplicit) [txdata](#txdata) [use_fts](#use_fts) [$identifier](#identifier) |

**Equivalent Settings for Cluster-Level and Node-Level**

| Cluster-Level Name | Node-Level Name | Request-Level Name |
| --- | --- | --- |
| [%hardbreaks] [queryCleanupClientAttempts](#queryCleanupClientAttempts) [queryCleanupLostAttempts](#queryCleanupLostAttempts) [queryCleanupWindow](#queryCleanupWindow) [queryCompletedLimit](#queryCompletedLimit) [queryCompletedMaxPlanSize](#queryCompletedMaxPlanSize) [queryCompletedThreshold](#queryCompletedThreshold) [queryLogLevel](#queryLogLevel) [queryN1QLFeatCtrl](#queryN1QLFeatCtrl) [queryNodeQuota](#queryNodeQuota) [queryNodeQuotaValPercent](#queryNodeQuotaValPercent) [queryNumCpus](#queryNumCpus) [queryPreparedLimit](#queryPreparedLimit) | [%hardbreaks] [cleanupclientattempts](#cleanupclientattempts) [cleanuplostattempts](#cleanuplostattempts) [cleanupwindow](#cleanupwindow) [completed-limit](#completed-limit) [completed-max-plan-size](#completed-max-plan-size) [completed-threshold](#completed-threshold) [loglevel](#loglevel) [n1ql-feat-ctrl](#n1ql-feat-ctrl) [node-quota](#node-quota) [node-quota-val-percent](#node-quota-val-percent) [num-cpus](#num-cpus) [prepared-limit](#prepared-limit) | N/A |

**Equivalent Settings for Node-Level and Request-Level**

| Cluster-Level Name | Node-Level Name | Request-Level Name |
| --- | --- | --- |
| N/A | [%hardbreaks] [atrcollection](#atrcollection-srv) [controls](#controls-srv) [pretty](#pretty-srv) [profile](#profile-srv) | [%hardbreaks] [atrcollection](#atrcollection_req) [controls](#controls_req) [pretty](#pretty_req) [profile](#profile_req) |

**Equivalent Settings for Cluster-Level, Node-Level, and Request-Level**

| Cluster-Level Name | Node-Level Name | Request-Level Name |
| --- | --- | --- |
| [%hardbreaks] [queryMaxParallelism](#queryMaxParallelism) [queryMemoryQuota](#queryMemoryQuota) [queryNumAtrs](#queryNumAtrs) [queryPipelineBatch](#queryPipelineBatch) [queryPipelineCap](#queryPipelineCap) [queryScanCap](#queryScanCap) [queryTimeout](#queryTimeout) [queryTxTimeout](#queryTxTimeout) [queryUseCBO](#queryUseCBO) [queryUseReplica](#queryUseReplica) | [%hardbreaks] [max-parallelism](#max-parallelism-srv) [memory-quota](#memory-quota-srv) [numatrs](#numatrs-srv) [pipeline-batch](#pipeline-batch-srv) [pipeline-cap](#pipeline-cap-srv) [scan-cap](#scan-cap-srv) [timeout](#timeout-srv) [txtimeout](#txtimeout-srv) [use-cbo](#use-cbo-srv) [use-replica](#use-replica-srv) | [%hardbreaks] [max_parallelism](#max_parallelism_req) [memory_quota](#memory_quota_req) [numatrs](#numatrs_req) (for future use) [pipeline_batch](#pipeline_batch_req) [pipeline_cap](#pipeline_cap_req) [scan_cap](#scan_cap_req) [timeout](#timeout_req) [txtimeout](#txtimeout_req) [use_cbo](#use_cbo_req) [use_replica](#use_replica_req) |

## Cluster-Level Query Settings

To set a cluster-level query setting, do one of the following:

* Use the [Advanced Query Settings](manage:manage-settings/general-settings.adoc#query-settings) in the Couchbase Web Console.
* Use the [setting-query](cli:cbcli/couchbase-cli-setting-query.adoc) command at the command line.
* Make a REST API call to the [Query Settings REST API](n1ql-rest-settings:index.adoc) (`/settings/querySettings` endpoint).

* **Web Console**

  To set cluster-level settings in the Web Console:

  1. Go to menu:Settings[General] and click **Advanced Query Settings** to display the settings.
  2. Specify the settings and click btn:[Save].

  !["The top of the Advanced Query Settings"](manage:manage-settings/query-settings-top.png)
* **Command Line**

  To set cluster-level settings at the command line, use the `couchbase-cli setting-query` command.

  In the following examples:

  * `$BASE_URL` is the protocol, host, and port -- for example, `http://localhost:8091`.
  * `$USER` is the user name.
  * `$PASSWORD` is the password.

  ---

  This example retrieves the current cluster-level settings:

  ```sh
  couchbase-cli setting-query -c $BASE_URL -u $USER \
   -p $PASSWORD --get
  ```

  This example sets the cluster-level maximum parallelism and log level settings:

  ```sh
  couchbase-cli setting-query -c $BASE_URL -u $USER \
   -p $PASSWORD --set --log-level debug --max-parallelism 4
  ```
* **REST API**

  To set cluster-level settings with the REST API, specify the parameters in the request body.

  In the following examples:

  * `$BASE_URL` is the protocol, host, and port -- for example, `http://localhost:8091`.
  * `$USER` is the user name.
  * `$PASSWORD` is the password.

  ---

  This example retrieves the current cluster-level settings:

  ```sh
  curl -v -u $USER:$PASSWORD \
  $BASE_URL/settings/querySettings
  ```

  This example sets the cluster-level maximum parallelism and log level settings:

  ```sh
  curl -v -X POST -u $USER:$PASSWORD \
  $BASE_URL/settings/querySettings \
  -d 'queryLogLevel=debug' \
  -d 'queryMaxParallelism=4'
  ```

The table below contains details of all cluster-level query settings.

**Cluster-Level Query Settings**

[role=include](n1ql-rest-settings:index.adoc)

### Access

[role=include](n1ql-rest-settings:index.adoc)

## Node-Level Query Settings

To set a node-level query setting:

* Make a REST API call to the [Admin REST API](n1ql-rest-admin:index.adoc) (`/admin/settings` endpoint).

You cannot set a query setting for an individual node using the Couchbase Web Console or the command line.

* **REST API**

  To set node-level settings with the REST API, specify the parameters in the request body.

  ---

  In the following examples:

  * `$BASE_URL` is the protocol, host, and port -- for example, `http://localhost:8093`.
  * `$USER` is the user name.
  * `$PASSWORD` is the password.

  This example retrieves the current node-level settings:

  ```sh
  curl $BASE_URL/admin/settings -u $USER:$PASSWORD
  ```

  This example sets the node-level profile parameter:

  ```sh
  curl $BASE_URL/admin/settings -u $USER:$PASSWORD \
    -H 'Content-Type: application/json' \
    -d '{"profile": "phases"}'
  ```

  For more examples, see [n1ql:n1ql-manage/monitoring-n1ql-query.adoc](n1ql:n1ql-manage/monitoring-n1ql-query.adoc).

The table below contains details of all node-level query settings.

<a name="Settings"></a>**Node-Level Query Settings**

[role=include](n1ql-rest-admin:index.adoc)

### Logging Parameters

[role=include](n1ql-rest-admin:index.adoc)

### Plan Qualifier

[role=include](n1ql-rest-admin:index.adoc)

### Field:Value Pairs

[role=include](n1ql-rest-admin:index.adoc)

## Request-Level Parameters

To set a request-level parameter, do one of the following:

* Use the [Run-Time Preferences](tools:query-workbench.adoc#query-preferences) window in the Query Workbench.
* Use the [cbq](n1ql:n1ql-intro/cbq.adoc) shell at the command line.
* Make a REST API call to the [n1ql-rest-query:index.adoc](n1ql-rest-query:index.adoc) (`/query/service` endpoint).
* Use an SDK client program.

Generally, use the `cbq` shell or the Query Workbench as a sandbox to test queries on your local machine.
Use a REST API call or an SDK client program for your production queries.

* **Web Console**

  To set request-level preferences in the Query Workbench:

  1. Go to menu:Query[Workbench] and click the cog icon icon:cog[] to display the Run-Time Preferences window.
  2. Specify the preferences -- if a preference is not explicitly listed, click btn:[+] next to **Named Parameters** and add its name and value.
  3. Click btn:[Save Preferences].

  !["The Run-Time Preferences window"](tools:query-workbench-preferences.png)

  For more information, see [Query Preferences](tools:query-workbench.adoc#query-preferences).
* **Command Line**

  To set request-level parameters in `cbq`, use the `\SET` command.
  The parameter name must be prefixed by a hyphen.

  ---

  This example sets the request-level timeout, pretty-print, and max parallelism parameters, and runs a query:

  ```sqlpp
  \SET -timeout "30m";
  \SET -pretty true;
  \SET -max_parallelism 3;
  SELECT * FROM "world" AS hello;
  ```

  For more information, see [Parameter Manipulation](n1ql:n1ql-intro/cbq.adoc#cbq-parameter-manipulation) in the cbq documentation.
* **REST API**

  To set request-level parameters with the REST API, specify the parameters in the request body or the query URI.

  In the following examples:

  * `$BASE_URL` is the protocol, host, and port -- for example, `http://localhost:8093`.
  * `$USER` is the user name.
  * `$PASSWORD` is the password.

  ---

  This example sets the request-level timeout, pretty-print, and max parallelism parameters, and runs a query:

  ```sh
  curl $BASE_URL/query/service -u $USER:$PASSWORD \
    -d 'statement=SELECT * FROM "world" AS hello;
      & timeout=30m
      & pretty=true
      & max_parallelism=3'
  ```

  For more examples, see the [Query Service REST API examples](n1ql:n1ql-rest-api/examplesrest.adoc).

The table below contains details of all request-level parameters, along with examples.

**Request-Level Parameters**

[role=include](n1ql-rest-query:index.adoc)

### Credentials
[role=include](n1ql-rest-query:index.adoc)

### Scan Vector
[role=include](n1ql-rest-query:index.adoc)

### Full Scan Vector
[role=include](n1ql-rest-query:index.adoc)

### Sparse Scan Vector
[role=include](n1ql-rest-query:index.adoc)

### Value-Guard Entry
[role=include](n1ql-rest-query:index.adoc)

### Scan Vectors
[role=include](n1ql-rest-query:index.adoc)

### Transactional Scan Consistency

If the request contains a `BEGIN TRANSACTION` statement, or a DML statement with the [tximplicit](#tximplicit) parameter set to `true`, then the [scan_consistency](#scan_consistency) parameter sets the transactional scan consistency.
If you specify a transactional scan consistency of `request_plus`, `statement_plus`, or `at_plus`, or if you specify no transactional scan consistency, the transactional scan consistency is set to `request_plus`; otherwise, the transactional scan consistency is set as specified.

**Transactional scan consistency**

| Scan consistency at start of transaction |
| --- |
| Transactional scan consistency |
| Not set |
| `request_plus` |
| `not_bounded` |
| `not_bounded` |
| `request_plus`<br>   `statement_plus`<br>   `at_plus` |
| `request_plus` |

Any DML statements within the transaction that have no scan consistency set will inherit from the transactional scan consistency.
Individual DML statements within the transaction may override the transactional scan consistency.
If you specify a scan consistency of `not_bounded` for a statement within the transaction, the scan consistency for the statement is set as specified.
When you specify a scan consistency of `request_plus`, `statement_plus`, or `at_plus` for a statement within the transaction, the scan consistency for the statement is set to `request_plus`.

However, `request_plus` consistency is not supported for statements using a full-text index.
If any statement within the transaction uses a full-text index, by means of the SEARCH function or the Flex Index feature, the scan consistency is set to `not_bounded` for the duration of the Full-Text Search.

**Overriding the transactional scan consistency**

| Scan consistency for statement within transaction |
| --- |
| Inherited scan consistency |
| Not set |
| Transactional scan consistency<br>  (`not_bounded` for Full-Text Search) |
| `not_bounded` |
| `not_bounded` |
| `request_plus`<br>   `statement_plus`<br>   `at_plus` |
| `request_plus`<br>  (`not_bounded` for Full-Text Search) |

## Named Parameters and Positional Parameters

You can add placeholder parameters to a statement, so that you can safely supply variable values when you run the statement.
A placeholder parameter may be a named parameter or a positional parameter.

* To add a named parameter to a query, enter a dollar sign `$` or an at sign `@` followed by the parameter name.
* To add a positional parameter to a query, enter a dollar sign `$` or an at sign `@` followed by the number of the parameter, or enter a question mark `?`.

To run a query containing placeholder parameters, you must supply values for the parameters.

* You can use [additional](#identifier) request-level parameters to supply the values for named parameters.
The name of this property is a dollar sign `$` or an at sign `@` followed by the parameter name.
* The [args](#args) request-level parameter enables you to supply a list of values for positional parameters.

You can supply the values for placeholder parameters using any of the methods used to specify [request-level parameters](#request-level-parameters).

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

In the REST API examples:

* `$BASE_URL` is the protocol, host, and port -- for example, `http://localhost:8093`.
* `$USER` is the user name.
* `$PASSWORD` is the password.

**{example-caption} {counter:example}. Named Parameters**

{blank}

* **Web Console**

  The following query uses named parameter placeholders.
  The parameter values are supplied using the Run-Time Preferences window.

  **Named Parameters**

  |     |     |     |     |
  | --- | --- | --- | --- |
  | name | `$country` | value | `"France"` |
  | name | `$altitude` | value | `500` |

  ```sqlpp
  SELECT COUNT(*) FROM airport
  WHERE country = $country AND geo.alt > @altitude;
  ```

  The named parameters and named parameter placeholders in this example use a mixture of `@` and `$` symbol prefixes.
  You can use either of these symbols as preferred.
* **Command Line**

  The following query uses named parameter placeholders.
  The parameter values are supplied using the cbq shell.

  ```sqlpp
  \SET -@country "France";
  \SET -$altitude 500;

  SELECT COUNT(*) FROM airport
  WHERE country = $country AND geo.alt > @altitude;
  ```

  The named parameters and named parameter placeholders in this example use a mixture of `@` and `$` symbol prefixes.
  You can use either of these symbols as preferred.
* **REST API**

  The following query uses named parameter placeholders.
  The parameter values are supplied using the Query Service REST API.

  ```sh
  curl -v $BASE_URL/query/service \
       -d 'statement=SELECT COUNT(*) FROM airport
                     WHERE country = $country AND geo.alt > @altitude
         & query_context=travel-sample.inventory
         & $country="France" & $altitude=500' \
       -u $USER:$PASSWORD
  ```

  The named parameters and named parameter placeholders in this example use a mixture of `@` and `$` symbol prefixes.
  You can use either of these symbols as preferred.

**{example-caption} {counter:example}. Numbered Positional Parameters**

{blank}

* **Web Console**

  The following query uses numbered positional parameter placeholders.
  The parameter values are supplied using the Run-Time Preferences window.

  **Positional Parameters**

  |     |     |
  | --- | --- |
  | $1 | `"France"` |
  | $2 | `500` |

  ```sqlpp
  SELECT COUNT(*) FROM airport
  WHERE country = $1 AND geo.alt > @2;
  ```

  In this case, the first positional parameter value is used for the placeholder numbered `$1`, the second positional parameter value is used for the placeholder numbered `@2`, and so on.

  The numbered positional parameter placeholders in this example use a mixture of `@` and `$` symbol prefixes.
  You can use either of these symbols as preferred.
* **Command Line**

  The following query uses numbered positional parameter placeholders.
  The parameter values are supplied using the cbq shell.

  ```sqlpp
  \SET -args ["France", 500];

  SELECT COUNT(*) FROM airport
  WHERE country = $1 AND geo.alt > @2;
  ```

  In this case, the first positional parameter value is used for the placeholder numbered `$1`, the second positional parameter value is used for the placeholder numbered `@2`, and so on.

  The numbered positional parameter placeholders in this example use a mixture of `@` and `$` symbol prefixes.
  You can use either of these symbols as preferred.
* **REST API**

  The following query uses numbered positional parameter placeholders.
  The parameter values are supplied using the Query Service REST API.

  ```sh
  curl -v $BASE_URL/query/service \
       -d 'statement=SELECT COUNT(*) FROM airport
                     WHERE country = $1 AND geo.alt > @2
         & query_context=travel-sample.inventory
         & args=["France", 500]' \
       -u $USER:$PASSWORD
  ```

  In this case, the first positional parameter value is used for the placeholder numbered `$1`, the second positional parameter value is used for the placeholder numbered `@2`, and so on.

  The numbered positional parameter placeholders in this example use a mixture of `@` and `$` symbol prefixes.
  You can use either of these symbols as preferred.

**{example-caption} {counter:example}. Unnumbered Positional Parameters**

{blank}

* **Web Console**

  The following query uses unnumbered positional parameter placeholders.
  The parameter values are supplied using the Run-Time Preferences window.

  **Positional Parameters**

  |     |     |
  | --- | --- |
  | $1 | `"France"` |
  | $2 | `500` |

  ```sqlpp
  SELECT COUNT(*) FROM airport
  WHERE country = ? AND geo.alt > ?;
  ```

  In this case, the first positional parameter value is used for the first `?` placeholder, the second positional parameter value is used for the second `?` placeholder, and so on.
* **Command Line**

  The following query uses unnumbered positional parameter placeholders.
  The parameter values are supplied using the cbq shell.

  ```sqlpp
  \SET -args ["France", 500];

  SELECT COUNT(*) FROM airport
  WHERE country = ? AND geo.alt > ?;
  ```

  In this case, the first positional parameter value is used for the first `?` placeholder, the second positional parameter value is used for the second `?` placeholder, and so on.
* **REST API**

  The following query uses unnumbered positional parameter placeholders.
  The parameter values are supplied using the Query Service REST API.

  ```sh
  curl -v $BASE_URL/query/service \
       -d 'statement=SELECT COUNT(*) FROM airport
                     WHERE country = ? AND geo.alt > ?
         & query_context=travel-sample.inventory
         & args=["France", 500]' \
       -u $USER:$PASSWORD
  ```

  In this case, the first positional parameter value is used for the first `?` placeholder, the second positional parameter value is used for the second `?` placeholder, and so on.

For more information and examples, including examples using SDKs, see the [guides:prep-statements.adoc](guides:prep-statements.adoc) guide.

## Related Links

* For more information about the {sqlpp} REST API, see [n1ql-rest-query:index.adoc](n1ql-rest-query:index.adoc).
* For more information about the Admin REST API, see [n1ql-rest-admin:index.adoc](n1ql-rest-admin:index.adoc).
* For more information about the Query Settings API, see [n1ql-rest-settings:index.adoc](n1ql-rest-settings:index.adoc).
* For more information about API content and settings, see [rest-api:rest-intro.adoc](rest-api:rest-intro.adoc).
