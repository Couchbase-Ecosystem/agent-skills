# SET TRANSACTION

The SET TRANSACTION statement enables you to specify settings for a transaction.

## Purpose

The `SET TRANSACTION` statement enables you to specify settings for an ACID transaction.
For more information, see [n1ql:n1ql-language-reference/transactions.adoc](n1ql:n1ql-language-reference/transactions.adoc).

You may only use this statement within a transaction.

If you are using the Query REST API, you must set the [txid](n1ql:n1ql-manage/query-settings.adoc#txid) query parameter to specify the transaction ID.

If you are using the Query Workbench, you don’t need to specify the transaction ID, as long as the statement is part of a multi-statement request.
When you start a transaction within a multi-statement request, all statements within the request are assumed to be part of the same transaction until you rollback or commit the transaction.

Similarly, if you are using the cbq shell, you don’t need to specify the transaction ID.
Once you have started a transaction, all statements within the cbq shell session are assumed to be part of the same transaction until you rollback or commit the transaction.
footnote:[You must be using cbq shell version 2.0 or above to use the automatic transaction ID functionality.]

You may also optionally specify settings when you start the transaction using the `BEGIN TRANSACTION` command.

**📌 NOTE**\
Currently, the only available transaction setting is `ISOLATION LEVEL READ COMMITTED`.
This setting is enabled by default.
The `SET TRANSACTION` statement is therefore optional and may be omitted.

## Syntax

```ebnf
set-transaction ::= 'SET' 'TRANSACTION' 'ISOLATION' 'LEVEL' 'READ' 'COMMITTED'
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/set-transaction.png)

## Example

If you want to try this example, first see [Preparation](n1ql:n1ql-language-reference/transactions.adoc#preparation) to set up your environment.

**Specify transaction settings**

**Transaction**

```sqlpp
-- Start the transaction
BEGIN TRANSACTION;

-- pass:[<mark>Specify transaction settings</mark>]
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

## Related Links

* For an overview of Couchbase transactions, see [learn:data/transactions.adoc](learn:data/transactions.adoc).
* To begin a transaction, see [n1ql-language-reference/begin-transaction.adoc](n1ql-language-reference/begin-transaction.adoc).
* To set a savepoint, see [n1ql-language-reference/savepoint.adoc](n1ql-language-reference/savepoint.adoc).
* To rollback a transaction, see [n1ql-language-reference/rollback-transaction.adoc](n1ql-language-reference/rollback-transaction.adoc).
* To commit a transaction, see [n1ql-language-reference/commit-transaction.adoc](n1ql-language-reference/commit-transaction.adoc).
* Blog post: [Couchbase Transactions: Elastic, Scalable, and Distributed](https://blog.couchbase.com/transactions-n1ql-couchbase-distributed-nosql/).
