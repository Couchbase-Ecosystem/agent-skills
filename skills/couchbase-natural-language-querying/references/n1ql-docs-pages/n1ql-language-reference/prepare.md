# PREPARE

<style type="text/css">

/* details like other paragraph divs */
  .doc details {
    margin-top: 1rem;
  }
  .doc .paragraph + .details {
    margin-top: 1.5rem;
  }

/* summary like other titles */
  .doc details > summary.title {
    font-size: 1rem;
    font-weight: 600;
    line-height: 1.2;
    margin-bottom: 1rem;
    color: #52566c;
  }

</style>

The PREPARE statement prepares a query for repeated execution.

## Purpose

Building plans for {sqlpp} requests may be expensive, in particular where a cluster has many indexes.
Sometimes planning may take more time than actually executing a request.

If you know that a statement text will be executed repeatedly, you can request the {sqlpp} service to prepare the execution plan beforehand, and then request to execute the prepared plan as many times as needed, thereby avoiding the cost of repeated planning.

## Prerequisites

### RBAC Privileges

The user executing the PREPARE statement must have the RBAC privileges of the statement being prepared.
For more details about user roles, refer to [Authorization](learn:security/authorization-overview.adoc).

<details>
<summary>RBAC Examples</summary>

======
For this example, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

To execute the following statement, user must have the _Query Select_ privilege on both keyspaces `pass:c[airport]` and `pass:c[landmark]`.

```sqlpp
PREPARE SELECT * FROM airport
WHERE city = (SELECT RAW city FROM landmark)
```

To execute the following statement, user must have the _Query Update_ and _Query Select_ privileges on `pass:c[hotel]`.

```sqlpp
PREPARE UPDATE hotel
SET city = "San Francisco" WHERE lower(city) = "sanfrancisco"
RETURNING *
```
======
</details>

### Query Context

A prepared statement is created and stored relative to the current _query context_.
You can create multiple prepared statements with the same name, each stored relative to a different query context.
This enables you to run multiple instances of the same application against different datasets.

To execute a prepared statement, the query context must be the same as it was when the prepared statement was created; otherwise the prepared statement will not be found.

You must therefore set the required query context, or unset the query context if necessary, before creating the prepared statement.
If you do not set the query context, it defaults to the empty string.

For further information, refer to [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

## Syntax

```ebnf
prepare ::= 'PREPARE' 'FORCE'? ( name ( 'FROM' | 'AS' ) )? statement
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/prepare.png)

* **statement**\
The full text of the {sqlpp} statement to prepare.
The {sqlpp} statement may contain parameters.
For more details, refer to [Parameters](#parameters) below.

### FORCE

[Optional] The FORCE keyword forces the query engine to create the prepared statement again, even if a matching prepared statement already exists in the cache.
For more details, refer to [Statement Cache](#statement-cache) below.

The FORCE keyword does _not_ enable you to assign a new prepared statement to an existing name.

### FROM / AS Clause

[Optional] The FROM or AS clause enables you to specify a name for the prepared statement.

* **name**\
A local name for the prepared statement.
If you do not specify a local name for the prepared statement, the query engine generates a UUID from the statement text.
For more details, refer to [Result](#result) below.

## Parameters

A prepared statement may contain parameters.
These are replaced by a supplied value when the statement is executed.
Parameters may be _named parameters_ or _positional parameters_.

Named parameters are specified by name when the prepared statement is executed.
To refer to a named parameter in a statement, use `$` followed by the name of the parameter, e.g. `$city`.
See [Prepared statement with named parameters](#ex-prepare-names).

Positional parameters are specified by the position of each supplied parameter when the statement is executed.
To refer to a positional parameter in a statement, use `$` followed by the position of the supplied parameter.
So `$1` refers to the first supplied parameter, `$2` refers to the second supplied parameter, etc.
See [Prepared statement with numbered parameters](#ex-prepare-numbers).

You may also use `?` to refer to a positional parameter in a statement.
In this case, the order of parameters in the statement must exactly match the order of parameters when the statement is executed.
So the first `?` refers to the first supplied parameter, the second `?` refers to the second supplied parameter, etc.
See [Prepared statement with positional parameters](#ex-prepare-positions).

## Result

A JSON object that contains the following properties:

* **name**\
The full name of the prepared statement.
This has the format `[host:port]local-name-or-UUID`, and consists of:

  * The host and port of the node where you created the prepared statement, enclosed in square brackets.
  * The local name you specified for the prepared statement, or a UUID that was generated from the statement text.

  You can use this name to execute a prepared statement without resending the entire statement text.
  When executing a prepared statement by its name:

  * The Query Service first checks whether the executing node contains the prepared statement.
  * If not found, the service uses the host information in the name to retrieve the prepared statement from the node where you originally created it.
  * If the service cannot find the prepared statement on the original node either, it returns an error.
* **operator**\
The execution plan of the statement being prepared.
* **signature**\
The signature of the statement being prepared.
* **text**\
The full PREPARE statement text.
* **encoded_plan**\
The full prepared statement in encoded format.
This is included for backward compatibility.
In versions of Couchbase Server prior to Couchbase Server 6.5, you can use the encoded plan in a request to execute a prepared statement.

## Statement Cache

Prepared statements are stored in the prepared statement cache until you restart the Couchbase Server.

In Couchbase Server 6.5 and later, the query engine uses the prepared statement cache to speed up the creation of prepared statements.

When you create a prepared statement with a local name:

* The query engine checks whether a prepared statement with that name already exists.
  * If it does not, the prepared statement is created.
  * If it does, the query engine checks whether the text of your {sqlpp} statement matches the {sqlpp} statement associated with the existing prepared statement.
    * If it does not match, a duplicate name error is generated.
    * If it matches, the existing prepared statement is returned.
    However, if the FORCE keyword is present, the prepared statement is created again.

When you create an anonymous prepared statement, i.e. a prepared statement without a local name:

* The query engine generates a UUID from the statement text.
* The query engine then searches the prepared cache to see if the UUID is already listed.
  * If not found, the statement is created and added to the prepared cache.
  * If found, the existing prepared statement is returned.
  However, if the FORCE keyword is present, the prepared statement is created again.

When you create an anonymous prepared statement, if there is a named prepared statement in the cache with identical statement text, the named prepared statement is not returned.
The anonymous prepared statement is added to the cache in addition to the named prepared statement.

## Auto-Prepare

When the _auto-prepare_ feature is active, a prepared statement is created every time you submit a {sqlpp} request, whether you use the PREPARE statement or not.

The process is similar to creating a prepared statement without a local name:

* The query engine generates a UUID from the statement text.
* The query engine then searches the prepared cache to see if the UUID is already listed.
  * If found, the existing prepared statement is returned.
  * If not found, the statement is created and added to the prepared cache.

The auto-prepare feature is inactive by default.
You can turn the auto-prepare feature on or off using the `auto-prepare` service-level query setting.
For more details, refer to [Query Settings](n1ql:n1ql-manage/query-settings.adoc#auto-prepare).

Auto-prepare is disabled for {sqlpp} requests which contain parameters, if they do not use the PREPARE statement.

## Automatic Reprepare on Index Changes

Before executing a statement, the Query Service validates its prepared plan.
If the plan is invalid—for example, if any indexes or keyspaces become unavailable—the service automatically reprepares the statement.
This is the [default behavior](n1ql-language-reference/execute.adoc#auto-reprepare).

The Query Service also provides an opt-in feature that extends this behavior.
When enabled, the service monitors GSI metadata version changes (such as when you create or drop indexes) and flags affected statements for repreparation.
The next time a flagged statement runs, the service generates a new plan to match the updated index set.
This ensures statements automatically use newer, more efficient indexes as they become available.

The following example shows how the feature works when it’s active:

1. You prepare a statement and no suitable indexes exist to support it;
the Query Service creates a plan that uses a sequential scan.
2. You then create a primary index that better supports the statement;
the service flags the statement, and on the next run generates a new plan that uses the primary index.
3. You later create a secondary index that is an even better choice for the statement;
the service flags the statement again, and on the next run generates a new plan that uses the secondary index.

If the feature is inactive, the statement continues to use the original plan (such as a sequential scan) even after you create new indexes.

To enable the feature, set bit 23 (0×800000 or 8388608) of the `n1ql-feat-ctrl` setting.
For information about how to set this value, see the table in the [Manage Sequential Scans](learn:services-and-indexes/indexes/query-without-index.adoc#manage-sequential-scans) section.

<dl><dt><strong>❗ IMPORTANT</strong></dt><dd>

This feature can increase the load on the Query Service.
Any index change, even one unrelated to a given statement, can trigger a repreparation.
For example, creating or dropping an index that a statement does not use can still flag it for repreparation.
In such cases, the statement reprepares only to select the same plan again, resulting in redundant work.

To reduce this overhead, enable the feature temporarily when you create or drop indexes, and disable it after all statements are reprepared.
If index changes are infrequent, the effect is minimal.
</dd></dl>

## Manual Reprepare

You can also can manually reprepare a specific statement.
To do this, update [system:prepareds](n1ql:n1ql-manage/monitoring-n1ql-query.adoc#sys-prepared) and unset the `planPreparedTime` field for the statement.

For example, to reprepare a prepared statement named `NumParam` on a node with the IP address `127.0.0.1` and port `8091`, use the following query:

```sqlpp
UPDATE system:prepareds USE KEYS ["[127.0.0.1:8091]NumParam"] UNSET planPreparedTime;
```
You can repeat this operation after creating each relevant index and refresh the prepared statement’s plan.

## Auto-Execute

When the _auto-execute_ feature is active, a prepared statement is executed automatically as soon as it is created.
This saves you from having to make two separate {sqlpp} requests in cases where you want to prepare a statement and execute it immediately.

When this feature is active, a {sqlpp} request to prepare a statement returns the [result of the execution step](n1ql:n1ql-intro/queriesandresults.adoc#results).
It does not return the full [result of the preparation step](#result), such as the execution plan.
However, the output of the {sqlpp} request does include a `prepared` field, which contains the full name of the prepared statement.
You can use this when you need to execute the prepared statement again.

The auto-execute feature is inactive by default.
You can turn the auto-execute feature on or off using the `auto_execute` request-level query setting.
For more details, refer to [Query Settings](n1ql:n1ql-manage/query-settings.adoc#auto_execute).

The auto-execute feature only works for {sqlpp} requests which actually contain the PREPARE statement.
Prepared statements created by the [auto-prepare](#auto-prepare) feature are not executed by the auto-execute feature.

## Statement Propagation

When prepared, new statements are distributed to all query nodes.

In Couchbase Server 6.5 and later, when a query node is started or restarted, the prepared statement cache is primed from another node.

If it is not possible to prime the statement cache from another node, you must prepare the statements again before you can execute them.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-prepare"></a>**Prepared statement**

**Query**

```sqlpp
PREPARE SELECT * FROM route
WHERE airline = "FL";
```

**Result**

```JSON
[
  {
    "encoded_plan": "H4sIAAAAAAAA/wEAAP//AAAAAAAAAAA=",
    "featureControls": 12,
    "indexApiVersion": 4,
    "indexScanKeyspaces": {
      "default:travel-sample.inventory.route": false
    },
    "name": "[127.0.0.1:8091]26898aa0-04b2-518c-aa11-2fd13cd377b1",
    "namespace": "default",
    "operator": {
      "#operator": "Authorize",
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
        "~children": [
          {
            "#operator": "Sequence",
            "~children": [
              {
                "#operator": "PrimaryScan3",
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
                "bucket": "travel-sample",
                "keyspace": "route",
                "namespace": "default",
                "scope": "inventory"
              },
              {
                "#operator": "Parallel",
                "~child": {
                  "#operator": "Sequence",
                  "~children": [
                    {
                      "#operator": "Filter",
                      "condition": "((`route`.`airline`) = \"FL\")"
                    },
                    {
                      "#operator": "InitialProject",
                      "result_terms": [
                        {
                          "expr": "self",
                          "star": true
                        }
                      ]
                    }
                  ]
                }
              }
            ]
          },
          {
            "#operator": "Stream"
          }
        ]
      }
    },
    "queryContext": "",
    "signature": {
      "*": "*"
    },
    "text": "PREPARE SELECT * FROM route\nWHERE airline = \"FL\";",
    "useCBO": true
  }
]
```

<a name="ex-prepare-names"></a>**Prepared statement with named parameters**

```sqlpp
PREPARE NameParam AS
SELECT * FROM hotel
WHERE city=$city AND country=$country;
```

<a name="ex-prepare-numbers"></a>**Prepared statement with numbered parameters**

```sqlpp
PREPARE NumParam AS
SELECT * FROM hotel
WHERE city=$1 AND country=$2;
```

<a name="ex-prepare-positions"></a>**Prepared statement with positional parameters**

```sqlpp
PREPARE NumParam AS
SELECT * FROM hotel
WHERE city=? AND country=?;
```

## Related

* For information on executing the prepared statement, refer to [EXECUTE](n1ql-language-reference/execute.adoc).
* For information on using prepared statements with the `cbq` command line shell, refer to [n1ql:n1ql-intro/cbq.adoc](n1ql:n1ql-intro/cbq.adoc).
* For information on using prepared statements with the Query REST API (`/query/service` endpoint), refer to [n1ql-rest-query:index.adoc](n1ql-rest-query:index.adoc).
* For information on using prepared statements with an SDK, refer to [Prepared Statements for Query Optimization](java-sdk:concept-docs:n1ql-query.adoc#prepared-statements-for-query-optimization) and [Parameterized Queries](java-sdk:howtos:n1ql-queries-with-sdk.adoc#parameterized-queries).
