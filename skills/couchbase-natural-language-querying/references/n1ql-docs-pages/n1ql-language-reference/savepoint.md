# SAVEPOINT

The SAVEPOINT statement enables you to set a savepoint within a transaction.

## Purpose

The `SAVEPOINT` statement enables you to set a savepoint within an ACID transaction.
For more information, see [n1ql:n1ql-language-reference/transactions.adoc](n1ql:n1ql-language-reference/transactions.adoc).

You may only use this statement within a transaction.

If you are using the Query REST API, you must set the [txid](n1ql:n1ql-manage/query-settings.adoc#txid) query parameter to specify the transaction ID.

If you are using the Query Workbench, you don’t need to specify the transaction ID, as long as the statement is part of a multi-statement request.
When you start a transaction within a multi-statement request, all statements within the request are assumed to be part of the same transaction until you rollback or commit the transaction.

Similarly, if you are using the cbq shell, you don’t need to specify the transaction ID.
Once you have started a transaction, all statements within the cbq shell session are assumed to be part of the same transaction until you rollback or commit the transaction.
footnote:[You must be using cbq shell version 2.0 or above to use the automatic transaction ID functionality.]

## Syntax

```ebnf
savepoint ::= 'SAVEPOINT' savepointname
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/savepoint.png)

* **savepointname**\
An identifier specifying a name for the savepoint.

If a savepoint with the same name already exists, the existing savepoint is replaced.

## Example

If you want to try this example, first see [Preparation](n1ql:n1ql-language-reference/transactions.adoc#preparation) to set up your environment.

**Set savepoints**

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

-- pass:[<mark>Set a savepoint</mark>]
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

-- pass:[<mark>Set a second savepoint</mark>]
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
        "user": "0", // ②
        "name": "Keon Hoppe"
      }
    ]
  },
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
        "user": "1", // ③
        "name": "Rigoberto Bernier"
      }
    ]
  },
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
        "user": "0", // ④
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

1. Beginning a transaction returns a transaction ID.
2. Before setting the second savepoint, the booking document has user `"0"`, name `"Keon Hoppe"`.
3. After setting the second savepoint and performing an update, the booking document has user `"1"`, name `"Rigoberto Bernier"`.
4. After rolling back to the second savepoint, the booking document again has user `"0"`, name `"Keon Hoppe"`.

## Related Links

* For an overview of Couchbase transactions, see [learn:data/transactions.adoc](learn:data/transactions.adoc).
* To begin a transaction, see [n1ql-language-reference/begin-transaction.adoc](n1ql-language-reference/begin-transaction.adoc).
* To specify transaction settings, see [n1ql-language-reference/set-transaction.adoc](n1ql-language-reference/set-transaction.adoc).
* To rollback a transaction, see [n1ql-language-reference/rollback-transaction.adoc](n1ql-language-reference/rollback-transaction.adoc).
* To commit a transaction, see [n1ql-language-reference/commit-transaction.adoc](n1ql-language-reference/commit-transaction.adoc).
* Blog post: [Couchbase Transactions: Elastic, Scalable, and Distributed](https://blog.couchbase.com/transactions-n1ql-couchbase-distributed-nosql/).
