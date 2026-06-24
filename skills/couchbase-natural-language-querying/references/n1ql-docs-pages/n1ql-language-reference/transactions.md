# {sqlpp} Support for Couchbase Transactions

{sqlpp} offers full support for Couchbase ACID transactions based on optimistic concurrency.

A transaction is a group of operations that are either committed to the database together, or are all undone from the database if there’s a failure.
For an overview of Couchbase transactions, see [learn:data/transactions.adoc](learn:data/transactions.adoc).

* Only DML statements are permitted within a transaction: [INSERT](n1ql:n1ql-language-reference/insert.adoc), [UPSERT](n1ql:n1ql-language-reference/upsert.adoc), [DELETE](n1ql:n1ql-language-reference/delete.adoc), [UPDATE](n1ql:n1ql-language-reference/update.adoc), [MERGE](n1ql:n1ql-language-reference/merge.adoc), [SELECT](n1ql:n1ql-language-reference/selectintro.adoc), [EXECUTE FUNCTION](n1ql:n1ql-language-reference/execfunction.adoc), [PREPARE](n1ql:n1ql-language-reference/prepare.adoc), or [EXECUTE](n1ql:n1ql-language-reference/execute.adoc).
* The `EXECUTE FUNCTION` statement is only permitted in a transaction if the user-defined function does not contain any subqueries other than `SELECT` subqueries.
* The `PREPARE` and `EXECUTE` statements are only permitted in a transaction for the DML statements listed above.

All statements within a transaction are sent to the same Query node.

## Statements

{sqlpp} provides the following statements in support of Couchbase transactions.
See the documentation for each statement for more information and examples.

* To begin a transaction, see [n1ql-language-reference/begin-transaction.adoc](n1ql-language-reference/begin-transaction.adoc).
* To specify transaction settings, see [n1ql-language-reference/set-transaction.adoc](n1ql-language-reference/set-transaction.adoc).
* To set a savepoint, see [n1ql-language-reference/savepoint.adoc](n1ql-language-reference/savepoint.adoc).
* To rollback a transaction, see [n1ql-language-reference/rollback-transaction.adoc](n1ql-language-reference/rollback-transaction.adoc).
* To commit a transaction, see [n1ql-language-reference/commit-transaction.adoc](n1ql-language-reference/commit-transaction.adoc).

## Settings and Parameters

The Query Service provides settings and parameters in support of Couchbase transactions.
For more information and examples, see the documentation for each parameter.

| Setting&#160;/ Parameter | Description |
| --- | --- |
| [txid](n1ql:n1ql-manage/query-settings.adoc#txid) request-level parameter | Specifies the transaction to which a statement belongs. |
| [tximplicit](n1ql:n1ql-manage/query-settings.adoc#tximplicit) request-level parameter | Specifies that a statement is a single transaction. |
| [txstmtnum](n1ql:n1ql-manage/query-settings.adoc#txstmtnum) request-level parameter | Specifies the transaction statement number. |
| [kvtimeout](n1ql:n1ql-manage/query-settings.adoc#kvtimeout) request-level parameter | Specifies the maximum time to spend on a KV operation within a transaction before timing out. |
| [durability_level](n1ql:n1ql-manage/query-settings.adoc#durability_level) request-level parameter | Specifies the transactional durability level. |
| [txtimeout](n1ql:n1ql-manage/query-settings.adoc#txtimeout_req) request-level parameter<br> [txtimeout](n1ql:n1ql-manage/query-settings.adoc#txtimeout-srv) node-level setting<br> {queryTxTimeout}[queryTxTimeout] cluster-level setting | Specify the maximum time to spend on a transaction before timing out. |
| [atrcollection](n1ql:n1ql-manage/query-settings.adoc#atrcollection_req) request-level parameter<br> [atrcollection](n1ql:n1ql-manage/query-settings.adoc#atrcollection-srv) node-level setting | Specify where the active transaction record is stored. |
| [cleanupclientattempts](n1ql:n1ql-manage/query-settings.adoc#cleanupclientattempts) node-level setting<br> {queryCleanupClientAttempts}[queryCleanupClientAttempts] cluster-level setting [cleanuplostattempts](n1ql:n1ql-manage/query-settings.adoc#cleanuplostattempts) node-level setting<br> {queryCleanupLostAttempts}[queryCleanupLostAttempts] cluster-level setting | Specify how expired transactions are cleaned up. |
| [cleanupwindow](n1ql:n1ql-manage/query-settings.adoc#cleanupwindow) node-level setting<br> {queryCleanupWindow}[queryCleanupWindow] cluster-level setting | Specify how frequently active transaction records are checked for cleanup. |
| [numatrs](n1ql:n1ql-manage/query-settings.adoc#numatrs-srv) node-level setting<br> {queryNumAtrs}[queryNumAtrs] cluster-level setting | Specify the total number of active transaction records. |

In addition, use the [scan-consistency](n1ql:n1ql-manage/query-settings.adoc#scan_consistency) request-level parameter to specify the transactional scan consistency.
For more information, see [Transactional Scan Consistency](n1ql:n1ql-manage/query-settings.adoc#transactional-scan-consistency).

## Query Tools

To create a Couchbase transaction using {sqlpp}, you can use any of the tools that you use to run a {sqlpp} query: the [Query Workbench](tools:query-workbench.adoc), the [cbq shell](n1ql:n1ql-intro/cbq.adoc), or the [Query REST API](n1ql-rest-query:index.adoc).
These tools operate in slightly different ways when creating Couchbase transactions.
The differences are explained in the sections below.

Some Couchbase SDKs provide APIs to support Couchbase transactions.
For more information, see [learn:data/transactions.adoc](learn:data/transactions.adoc).

### Couchbase Transactions with the Query Workbench

* To execute a transaction containing multiple statements, compose the sequence of statements in the query editor.
Terminate each statement with a semicolon.
After each statement, press kbd:[Shift+Enter] to start a new line without executing the query.
You can then click btn:[Execute] to execute the transaction.
* To execute a single statement as a transaction, enter the statement in the query editor and click btn:[Run as TX].
* In either case, you do not need to specify the `txid` parameter or the `tximplicit` parameter.
If you need to specify any other parameters for the Couchbase transaction, you can use the query run-time preferences window.

### Couchbase Transactions with the cbq shell

* To execute a transaction containing multiple statements, you can create the transaction one statement at a time.
Once you have started a transaction, all statements within the cbq shell session are assumed to be part of the same transaction until you rollback or commit the transaction.
In this case, you do not need to set the `txid` parameter.
footnote:[You must be using cbq shell version 2.0 or above to use the automatic transaction ID functionality.]
* Alternatively, you can use the `tximplicit` parameter to run a single statement as a transaction.
In this case, you do not need to specify the `txid` parameter either.
* You can specify parameters for the Couchbase transaction using the `\SET` command.

### Couchbase Transactions with the Query REST API

* To execute a transaction containing multiple statements, you can create the transaction one statement at a time.
Once you have started the transaction, you must set the `txid` parameter to specify the transaction to which each subsequent statement belongs.
* Alternatively, you can use the `tximplicit` parameter to run a single statement as a transaction.
In this case, you do not need to specify the `txid` parameter.
* You can specify parameters for the Couchbase transaction as body parameters or query parameters alongside the query statement.

## Monitoring

You can monitor active Couchbase transactions using the `system:transactions` catalog.
For more information, see [system:transactions](n1ql:n1ql-intro/sysinfo.adoc#sys-transactions).

## Permissions

When developing a transaction with an SDK, the transaction may contain a mixture of key-value operations and query statements.

> **[EXTERNAL INCLUDE NOT RESOLVED]** `learn/partials/transaction-privileges.adoc` (lives in another Antora component outside this repo)

## Worked Example

This worked example guides you through a complete Couchbase transaction session using {sqlpp}.

### Preparation

The worked example assumes that the supplied `travel-sample` bucket is installed.
For more information, see [manage:manage-settings/install-sample-buckets.adoc](manage:manage-settings/install-sample-buckets.adoc).

**Context**

For this worked example, set the query context to the `tenant_agent_00` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

* **Query Workbench**

  !["The query context drop-down menu](../../assets/images/guides:transactions-context.png)
* **CBQ Shell**

  ```sqlpp
  \SET -query_context travel-sample.tenant_agent_00;
  ```

**Parameters**

If necessary, set the transaction parameters for this worked example.
In particular, turn off durability for the purposes of this example, to make sure that there are no problems meeting the transaction durability requirements.

* **Query Workbench**

  1. Click the cog icon icon:cog[] to display the Run-Time Preferences window.
  2. Open the **Scan Consistency** drop-down list and select **not_bounded**.
  3. In the **Transaction Timeout** box, enter `120`.
  4. In the **Named Parameters** section, click the btn:[+] button to add a named parameter.
  5. For the new named parameter, enter `durability_level` in the **name** box and `"none"` (with double quotes) in the **value** box.
  6. Choose btn:[Save Preferences] to save the preferences and return to the Query Workbench.
* **CBQ Shell**

  Enter the following parameters.

  ```sqlpp
  \SET -txtimeout "2m"; -- ①
  \SET -scan_consistency "not_bounded"; -- ②
  \SET -durability_level "none"; -- ③
  ```

  1. The transaction timeout.
  2. The transaction scan consistency.
  No scan consistency is set for individual statements within the transaction; they inherit from the transaction scan consistency.
  3. Durability level of all the mutations within the transaction.

### Transaction

<a name="ex-1"></a>**Transaction using the Query Workbench or cbq shell**

Copy the entire sequence below and paste it into either the [Query Workbench](tools:query-workbench.adoc) or the [cbq shell](n1ql:n1ql-intro/cbq.adoc).
You must be using cbq shell version 2.0 or above.

**Transaction**

```sqlpp
-- Start the transaction
BEGIN TRANSACTION;

-- Specify transaction settings
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Create a booking document
UPSERT INTO bookings
VALUES("bf7ad6fa-bdb9-4099-a840-196e47179f03", {
  "date": "07/24/2021",
  "flight": "WN533",
  "flighttime": 7713,
  "price": 964.13,
  "route": "63986"
});

-- Set a savepoint
SAVEPOINT s1;

-- Update the booking document to include a user
UPDATE bookings AS b
USE KEYS "bf7ad6fa-bdb9-4099-a840-196e47179f03"
SET b.`user` = "0";

-- Check the content of the booking and user
SELECT b.*, u.name
FROM bookings b
USE KEYS "bf7ad6fa-bdb9-4099-a840-196e47179f03"
JOIN users u
ON KEYS b.`user`;

-- Set a second savepoint
SAVEPOINT s2;

-- Update the booking documents to change the user
UPDATE bookings AS b
USE KEYS "bf7ad6fa-bdb9-4099-a840-196e47179f03"
SET b.`user` = "1";

-- Check the content of the booking and user
SELECT b.*, u.name
FROM bookings b
USE KEYS "bf7ad6fa-bdb9-4099-a840-196e47179f03"
JOIN users u
ON KEYS b.`user`;

-- Roll back the transaction to the second savepoint
ROLLBACK TRANSACTION TO SAVEPOINT s2;

-- Check the content of the booking and user again
SELECT b.*, u.name
FROM bookings b
USE KEYS "bf7ad6fa-bdb9-4099-a840-196e47179f03"
JOIN users u
ON KEYS b.`user`;

-- Commit the transaction
COMMIT TRANSACTION;
```

The results of running the transaction in the Query Workbench are shown below.
If you’re using the cbq shell, the results are formatted differently, but contain the same information.

**Results**

```json
[
  {
    "_sequence_num": 1,
    "_sequence_query": "-- Start the transaction\nBEGIN TRANSACTION;",
    "_sequence_query_status": "success",
    "_sequence_result": [
      {
        "nodeUUID": "b30cc79a9d942784c8a6b8968fe086ec",
        "txid": "d81d9b4a-b758-4f98-b007-87ba262d3a51" // ①
      }
    ]
  },
// ...
```
Beginning a transaction returns a unique transaction ID `txid`.

```json
// ...
  {
    "_sequence_num": 2,
    "_sequence_query": "\n\n-- Specify transaction settings\nSET TRANSACTION ISOLATION LEVEL READ COMMITTED;",
    "_sequence_query_status": "success",
    "_sequence_result": {
      "results": []
    }
  },
  {
    "_sequence_num": 3,
    "_sequence_query": "\n\n-- Create a booking document\nUPSERT INTO bookings\nVALUES(\"bf7ad6fa-bdb9-4099-a840-196e47179f03\", {\n  \"date\": \"07/24/2021\",\n  \"flight\": \"WN533\",\n  \"flighttime\": 7713,\n  \"price\": 964.13,\n  \"route\": \"63986\"\n});",
    "_sequence_query_status": "success",
    "_sequence_result": {
      "results": []
    }
  },
  {
    "_sequence_num": 4,
    "_sequence_query": "\n\n-- Set a savepoint\nSAVEPOINT s1;",
    "_sequence_query_status": "success",
    "_sequence_result": {
      "results": []
    }
  },
  {
    "_sequence_num": 5,
    "_sequence_query": "\n\n-- Update the booking document to include a user\nUPDATE bookings AS b\nUSE KEYS \"bf7ad6fa-bdb9-4099-a840-196e47179f03\"\nSET b.`user` = \"0\";",
    "_sequence_query_status": "success",
    "_sequence_result": {
      "results": []
    }
  },
  {
    "_sequence_num": 6,
    "_sequence_query": "\n\n-- Check the content of the booking and user\nSELECT b.*, u.name\nFROM bookings b\nUSE KEYS \"bf7ad6fa-bdb9-4099-a840-196e47179f03\"\nJOIN users u\nON KEYS b.`user`;",
    "_sequence_query_status": "success",
    "_sequence_result": [
      {
        "date": "07/24/2021",
        "flight": "WN533",
        "flighttime": 7713,
        "price": 964.13,
        "route": "63986",
        "user": "0", // ①
        "name": "Keon Hoppe"
      }
    ]
  },
// ...
```
Before setting the second savepoint, the booking document has user `"0"`, name `"Keon Hoppe"`.

```json
// ...
  {
    "_sequence_num": 7,
    "_sequence_query": "\n\n-- Set a second savepoint\nSAVEPOINT s2;",
    "_sequence_query_status": "success",
    "_sequence_result": {
      "results": []
    }
  },
  {
    "_sequence_num": 8,
    "_sequence_query": "\n\n-- Update the booking documents to change the user\nUPDATE bookings AS b\nUSE KEYS \"bf7ad6fa-bdb9-4099-a840-196e47179f03\"\nSET b.`user` = \"1\";",
    "_sequence_query_status": "success",
    "_sequence_result": {
      "results": []
    }
  },
  {
    "_sequence_num": 9,
    "_sequence_query": "\n\n-- Check the content of the booking and user\nSELECT b.*, u.name\nFROM bookings b\nUSE KEYS \"bf7ad6fa-bdb9-4099-a840-196e47179f03\"\nJOIN users u\nON KEYS b.`user`;",
    "_sequence_query_status": "success",
    "_sequence_result": [
      {
        "date": "07/24/2021",
        "flight": "WN533",
        "flighttime": 7713,
        "price": 964.13,
        "route": "63986",
        "user": "1", // ①
        "name": "Rigoberto Bernier"
      }
    ]
  },
// ...
```
After setting the second savepoint and performing an update, the booking document has user `"1"`, name `"Rigoberto Bernier"`.

```json
// ...
  {
    "_sequence_num": 10,
    "_sequence_query": "\n\n-- Roll back the transaction to the second savepoint\nROLLBACK TRANSACTION TO SAVEPOINT s2;",
    "_sequence_query_status": "success",
    "_sequence_result": {
      "results": []
    }
  },
  {
    "_sequence_num": 11,
    "_sequence_query": "\n\n-- Check the content of the booking and user again\nSELECT b.*, u.name\nFROM bookings b\nUSE KEYS \"bf7ad6fa-bdb9-4099-a840-196e47179f03\"\nJOIN users u\nON KEYS b.`user`;",
    "_sequence_query_status": "success",
    "_sequence_result": [
      {
        "date": "07/24/2021",
        "flight": "WN533",
        "flighttime": 7713,
        "price": 964.13,
        "route": "63986",
        "user": "0", // ①
        "name": "Keon Hoppe"
      }
    ]
  },
  {
    "_sequence_num": 12,
    "_sequence_query": "\n\n-- Commit the transaction\nCOMMIT TRANSACTION;",
    "_sequence_query_status": "success",
    "_sequence_result": {
      "results": []
    }
  }
]
```
After rolling back to the second savepoint, the booking document again has user `"0"`, name `"Keon Hoppe"`.

<a name="ex-2"></a>**Check the results of [Transaction using the Query Workbench or cbq shell](#ex-1)**

Check the result of committing the transaction.

**Query**

```sqlpp
SELECT b.*, u.name
FROM bookings b
USE KEYS "bf7ad6fa-bdb9-4099-a840-196e47179f03"
JOIN users u
ON KEYS b.`user`;
```

**Results**

n
{
  "date": "07/24/2021",
  "flight": "WN533",
  "flighttime": 7713,
  "price": 964.13,
  "route": "63986",
  "user": "0", // ①
  "name": "Keon Hoppe"
}
```

The booking document has been added with the attributes that were present when the transaction was committed.

**Transaction using the Query REST API**

For reference, this example shows the equivalent of [Transaction using the Query Workbench or cbq shell](#ex-1) using the Query REST API.

**Begin transaction and set parameters**

```sh
curl http://localhost:8093/query/service \
-u Administrator:password \
-H 'Content-Type: application/json' \
-d '{
  "statement": "BEGIN TRANSACTION",
  "query_context": "`travel-sample`.tenant_agent_00",
  "txtimeout": "2m",
  "scan_consistency": "request_plus",
  "durability_level": "none"
}' | jq '.results[0].txid'
```

This statement uses [jq](https://jqlang.org) to get the transaction ID from the query results.
After beginning the transaction, each subsequent statement in the transaction must specify the transaction ID that was generated when the transaction began.

**Specify transaction settings**

```sh
curl http://localhost:8093/query/service \
-u Administrator:password \
-H 'Content-Type: application/json' \
-d '{
  "statement": "SET TRANSACTION ISOLATION LEVEL READ COMMITTED;",
  "query_context": "`travel-sample`.tenant_agent_00",
  "txid": '${TXID}'
}'
```

In this and the following statements, replace ’${TXID}'` with the transaction ID, wrapped in double quotes `""`.

**Create a booking document**

```sh
curl http://localhost:8093/query/service \
-u Administrator:password \
-H 'Content-Type: application/json' \
-d '{
  "statement": "UPSERT INTO bookings VALUES(\"bf7ad6fa-bdb9-4099-a840-196e47179f03\", {\"date\": \"07/24/2021\", \"flight\": \"WN533\", \"flighttime\": 7713, \"price\": 964.13, \"route\": \"63986\"});",
  "query_context": "`travel-sample`.tenant_agent_00",
  "txid": '${TXID}'
}'
```

**Set a savepoint**

```sh
curl http://localhost:8093/query/service \
-u Administrator:password \
-H 'Content-Type: application/json' \
-d '{
  "statement": "SAVEPOINT s1;",
  "query_context": "`travel-sample`.tenant_agent_00",
  "txid": '${TXID}'
}'
```

**Update the booking document to include a user**

```sh
curl http://localhost:8093/query/service \
-u Administrator:password \
-H 'Content-Type: application/json' \
-d '{
  "statement": "UPDATE bookings AS b USE KEYS \"bf7ad6fa-bdb9-4099-a840-196e47179f03\" SET b.`user` = \"0\";",
  "query_context": "`travel-sample`.tenant_agent_00",
  "txid": '${TXID}'
}'
```

**Check the content of the booking and user**

```sh
curl http://localhost:8093/query/service \
-u Administrator:password \
-H 'Content-Type: application/json' \
-d '{
  "statement": "SELECT b.*, u.name FROM bookings b USE KEYS \"bf7ad6fa-bdb9-4099-a840-196e47179f03\" JOIN users u ON KEYS b.`user`;",
  "query_context": "`travel-sample`.tenant_agent_00",
  "txid": '${TXID}'
}'
```

**Set a second savepoint**

```sh
curl http://localhost:8093/query/service \
-u Administrator:password \
-H 'Content-Type: application/json' \
-d '{
  "statement": "SAVEPOINT s2;",
  "query_context": "`travel-sample`.tenant_agent_00",
  "txid": '${TXID}'
}'
```

**Update the booking documents to change the user**

```sh
curl http://localhost:8093/query/service \
-u Administrator:password \
-H 'Content-Type: application/json' \
-d '{
  "statement": "UPDATE bookings AS b USE KEYS \"bf7ad6fa-bdb9-4099-a840-196e47179f03\" SET b.`user` = \"1\";",
  "query_context": "`travel-sample`.tenant_agent_00",
  "txid": '${TXID}'
}'
```

**Check the content of the booking and user**

```sh
curl http://localhost:8093/query/service \
-u Administrator:password \
-H 'Content-Type: application/json' \
-d '{
  "statement": "SELECT b.*, u.name FROM bookings b USE KEYS \"bf7ad6fa-bdb9-4099-a840-196e47179f03\" JOIN users u ON KEYS b.`user`;",
  "query_context": "`travel-sample`.tenant_agent_00",
  "txid": '${TXID}'
}'
```

**Roll back the transaction to the second savepoint**

```sh
curl http://localhost:8093/query/service \
-u Administrator:password \
-H 'Content-Type: application/json' \
-d '{
  "statement": "ROLLBACK TRANSACTION TO SAVEPOINT s2;",
  "query_context": "`travel-sample`.tenant_agent_00",
  "txid": '${TXID}'
}'
```

**Check the content of the booking and user again**

```sh
curl http://localhost:8093/query/service \
-u Administrator:password \
-H 'Content-Type: application/json' \
-d '{
  "statement": "SELECT b.*, u.name FROM bookings b USE KEYS \"bf7ad6fa-bdb9-4099-a840-196e47179f03\" JOIN users u ON KEYS b.`user`;",
  "query_context": "`travel-sample`.tenant_agent_00",
  "txid": '${TXID}'
}'
```

**Commit the transaction**

```sh
curl http://localhost:8093/query/service \
-u Administrator:password \
-H 'Content-Type: application/json' \
-d '{
  "statement": "COMMIT TRANSACTION",
  "query_context": "`travel-sample`.tenant_agent_00",
  "txid": '${TXID}'
}'
```

## Related Links

* Blog post: [Couchbase Transactions: Elastic, Scalable, and Distributed](https://blog.couchbase.com/transactions-n1ql-couchbase-distributed-nosql/).
