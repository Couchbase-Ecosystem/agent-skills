# BEGIN TRANSACTION

The BEGIN TRANSACTION statement enables you to begin a transaction.

## Purpose

The `BEGIN TRANSACTION` statement enables you to begin a sequence of statements as an ACID transaction.
For more information, see [n1ql:n1ql-language-reference/transactions.adoc](n1ql:n1ql-language-reference/transactions.adoc).

* Only DML statements are permitted within a transaction: [INSERT](n1ql:n1ql-language-reference/insert.adoc), [UPSERT](n1ql:n1ql-language-reference/upsert.adoc), [DELETE](n1ql:n1ql-language-reference/delete.adoc), [UPDATE](n1ql:n1ql-language-reference/update.adoc), [MERGE](n1ql:n1ql-language-reference/merge.adoc), [SELECT](n1ql:n1ql-language-reference/selectintro.adoc), [EXECUTE FUNCTION](n1ql:n1ql-language-reference/execfunction.adoc), [PREPARE](n1ql:n1ql-language-reference/prepare.adoc), or [EXECUTE](n1ql:n1ql-language-reference/execute.adoc).
* The `EXECUTE FUNCTION` statement is only permitted in a transaction if the user-defined function does not contain any subqueries other than `SELECT` subqueries.
* The `PREPARE` and `EXECUTE` statements are only permitted in a transaction for the DML statements listed above.

All statements within a transaction are sent to the same Query node.

**📌 NOTE**\
You can also specify a single DML statement as an ACID transaction by setting the [tximplicit](n1ql:n1ql-manage/query-settings.adoc#tximplicit) query parameter.

## Syntax

```ebnf
begin-transaction ::= ( 'BEGIN' | 'START' ) ( 'WORK' | 'TRAN' | 'TRANSACTION' )
                      ( 'ISOLATION' 'LEVEL' 'READ' 'COMMITTED' )?
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/begin-transaction.png)

The `BEGIN` and `START` keywords are synonyms.
The statement must begin with one of these keywords.

The `WORK`, `TRAN`, and `TRANSACTION` keywords are synonyms.
The statement must contain one of these keywords.

### Transaction Settings

Currently, the only available transaction setting is `ISOLATION LEVEL READ COMMITTED`.
This setting is enabled by default.
The `ISOLATION LEVEL READ COMMITTED` keywords are therefore optional and may be omitted.

## Return Value

The statement returns an object containing the following properties.

| Name | Description | Schema |
| --- | --- | --- |
| ***nodeUUID***<br> __required__ | The UUID of the Query node performing the transaction. | String |
| ***txid***<br> __required__ | The transaction ID. | String |

If you’re using the Query REST API, you must set the [txid](n1ql:n1ql-manage/query-settings.adoc#txid) query parameter to specify the transaction ID for any subsequent statements that form part of the same transaction.

If you’re using the Query Workbench, you do not need to specify the transaction ID for any statements that form a part of the same transaction within a multi-statement request.
If you start a transaction within a multi-statement request, all statements within the request are assumed to be part of the same transaction until you rollback or commit the transaction.

Similarly, if you’re using the cbq shell, you do not need to specify the transaction ID for any statements that form a part of the same transaction.
Once you have started a transaction, all statements within the cbq shell session are assumed to be part of the same transaction until you rollback or commit the transaction.
footnote:[You must be using cbq shell version 2.0 or above to use the automatic transaction ID functionality.]

## Example

If you want to try this example, first see [Preparation](n1ql:n1ql-language-reference/transactions.adoc#preparation) to set up your environment.

**Begin a transaction**

**Transaction**

```sqlpp
-- pass:[<mark>Start the transaction</mark>]
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

1. Beginning a transaction returns a transaction ID.

## Related Links

* For an overview of Couchbase transactions, see [learn:data/transactions.adoc](learn:data/transactions.adoc).
* To specify transaction settings, see [n1ql-language-reference/set-transaction.adoc](n1ql-language-reference/set-transaction.adoc).
* To set a savepoint, see [n1ql-language-reference/savepoint.adoc](n1ql-language-reference/savepoint.adoc).
* To rollback a transaction, see [n1ql-language-reference/rollback-transaction.adoc](n1ql-language-reference/rollback-transaction.adoc).
* To commit a transaction, see [n1ql-language-reference/commit-transaction.adoc](n1ql-language-reference/commit-transaction.adoc).
* Blog post: [Couchbase Transactions: Elastic, Scalable, and Distributed](https://blog.couchbase.com/transactions-n1ql-couchbase-distributed-nosql/).
