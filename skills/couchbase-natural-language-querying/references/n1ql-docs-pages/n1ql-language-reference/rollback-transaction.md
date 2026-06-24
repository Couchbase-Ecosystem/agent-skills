# ROLLBACK TRANSACTION

The ROLLBACK TRANSACTION statement enables you to rollback a transaction.

## Purpose

The `ROLLBACK TRANSACTION` statement enables you to rollback an ACID transaction.
You can rollback the entire transaction, or rollback to a previous savepoint.
For more information, see [n1ql:n1ql-language-reference/transactions.adoc](n1ql:n1ql-language-reference/transactions.adoc).

This statement may only be used within a transaction.

If you are using the Query REST API, you must set the [txid](n1ql:n1ql-manage/query-settings.adoc#txid) query parameter to specify the transaction ID.

If you are using the Query Workbench, you don’t need to specify the transaction ID, as long as the statement is part of a multi-statement request.
When you start a transaction within a multi-statement request, all statements within the request are assumed to be part of the same transaction until you rollback or commit the transaction.

Similarly, if you are using the cbq shell, you don’t need to specify the transaction ID.
Once you have started a transaction, all statements within the cbq shell session are assumed to be part of the same transaction until you rollback or commit the transaction.
footnote:[You must be using cbq shell version 2.0 or above to use the automatic transaction ID functionality.]

When you rollback the entire transaction, this statement removes all savepoints within the transaction.

**📌 NOTE**\
If you’re using the cbq shell, and a transaction fails for any reason, you must use the `ROLLBACK TRANSACTION` statement to remove the transaction context and reset the transaction ID.

## Syntax

```ebnf
rollback-transaction ::= 'ROLLBACK' ( 'WORK' | 'TRAN' | 'TRANSACTION' )?
                       ( 'TO' 'SAVEPOINT' savepointname )?
```

![Syntax diagram: see source code listing](../../assets/images/n1ql-language-reference/rollback-transaction.png)

The `WORK`, `TRAN`, and `TRANSACTION` keywords are synonyms.
These keywords are optional; you may include one of these keywords, or omit them entirely.

### Rollback to a Savepoint

The `TO SAVEPOINT` clause enables you to rollback to a specified savepoint.
This clause is optional.
If omitted, the entire transaction is rolled back.

* **savepointname**\
An identifier specifying a name for the savepoint.

## Examples

If you want to try these examples, first see [Preparation](n1ql:n1ql-language-reference/transactions.adoc#preparation) to set up your environment.

<a name="ex-1"></a>**Rollback a transaction**

**Transaction**

```sqlpp
-- Start the transaction
BEGIN TRANSACTION;

-- Specify transaction settings
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Create a booking document
UPSERT INTO bookings
VALUES("42641d7a-cde3-4a4d-bfd5-fec321510f70", {
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
USE KEYS "42641d7a-cde3-4a4d-bfd5-fec321510f70"
SET b.`user` = "0";

-- Check the content of the booking and user
SELECT b.*, u.name
FROM bookings b
USE KEYS "42641d7a-cde3-4a4d-bfd5-fec321510f70"
JOIN users u
ON KEYS b.`user`;

-- Set a second savepoint
SAVEPOINT s2;

-- Update the booking documents to change the user
UPDATE bookings AS b
USE KEYS "42641d7a-cde3-4a4d-bfd5-fec321510f70"
SET b.`user` = "1";

-- Check the content of the booking and user
SELECT b.*, u.name
FROM bookings b
USE KEYS "42641d7a-cde3-4a4d-bfd5-fec321510f70"
JOIN users u
ON KEYS b.`user`;

-- pass:[<mark>Roll back the transaction to the second savepoint</mark>]
ROLLBACK TRANSACTION TO SAVEPOINT s2;

-- Check the content of the booking and user again
SELECT b.*, u.name
FROM bookings b
USE KEYS "42641d7a-cde3-4a4d-bfd5-fec321510f70"
JOIN users u
ON KEYS b.`user`;

-- pass:[<mark>Roll back the entire transaction</mark>]
ROLLBACK TRANSACTION;
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
        "txid": "d81d9b4a-b758-4f98-b007-87ba262d3a51"
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
    "_sequence_query": "\n\n-- Create a booking document\nUPSERT INTO bookings\nVALUES(\"42641d7a-cde3-4a4d-bfd5-fec321510f70\", {\n  \"date\": \"07/24/2021\",\n  \"flight\": \"WN533\",\n  \"flighttime\": 7713,\n  \"price\": 964.13,\n  \"route\": \"63986\"\n});",
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
    "_sequence_query": "\n\n-- Update the booking document to include a user\nUPDATE bookings AS b\nUSE KEYS \"42641d7a-cde3-4a4d-bfd5-fec321510f70\"\nSET b.`user` = \"0\";",
    "_sequence_query_status": "success",
    "_sequence_result": {
      "results": []
    }
  },
  {
    "_sequence_num": 6,
    "_sequence_query": "\n\n-- Check the content of the booking and user\nSELECT b.*, u.name\nFROM bookings b\nUSE KEYS \"42641d7a-cde3-4a4d-bfd5-fec321510f70\"\nJOIN users u\nON KEYS b.`user`;",
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
    "_sequence_num": 7,
    "_sequence_query": "\n\n-- Set a second savepoint\nSAVEPOINT s2;",
    "_sequence_query_status": "success",
    "_sequence_result": {
      "results": []
    }
  },
  {
    "_sequence_num": 8,
    "_sequence_query": "\n\n-- Update the booking documents to change the user\nUPDATE bookings AS b\nUSE KEYS \"42641d7a-cde3-4a4d-bfd5-fec321510f70\"\nSET b.`user` = \"1\";",
    "_sequence_query_status": "success",
    "_sequence_result": {
      "results": []
    }
  },
  {
    "_sequence_num": 9,
    "_sequence_query": "\n\n-- Check the content of the booking and user\nSELECT b.*, u.name\nFROM bookings b\nUSE KEYS \"42641d7a-cde3-4a4d-bfd5-fec321510f70\"\nJOIN users u\nON KEYS b.`user`;",
    "_sequence_query_status": "success",
    "_sequence_result": [
      {
        "date": "07/24/2021",
        "flight": "WN533",
        "flighttime": 7713,
        "price": 964.13,
        "route": "63986",
        "user": "1", // ②
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
    "_sequence_query": "\n\n-- Check the content of the booking and user again\nSELECT b.*, u.name\nFROM bookings b\nUSE KEYS \"42641d7a-cde3-4a4d-bfd5-fec321510f70\"\nJOIN users u\nON KEYS b.`user`;",
    "_sequence_query_status": "success",
    "_sequence_result": [
      {
        "date": "07/24/2021",
        "flight": "WN533",
        "flighttime": 7713,
        "price": 964.13,
        "route": "63986",
        "user": "0", // ③
        "name": "Keon Hoppe"
      }
    ]
  },
  {
    "_sequence_num": 12,
    "_sequence_query": "\n\n-- Roll back the entire transaction\nROLLBACK TRANSACTION;",
    "_sequence_query_status": "success",
    "_sequence_result": {
      "results": []
    }
  }
]
```

1. Before setting the second savepoint, the booking document has user `"0"`, name `"Keon Hoppe"`.
2. After setting the second savepoint and performing an update, the booking document has user `"1"`, name `"Rigoberto Bernier"`.
3. After rolling back to the second savepoint, the booking document again has user `"0"`, name `"Keon Hoppe"`.

<a name="ex-2"></a>**Check the result of [Rollback a transaction](#ex-1)**

Check the result of rolling back the transaction.

**Query**

```sqlpp
SELECT b.*, u.name
FROM bookings b
USE KEYS "42641d7a-cde3-4a4d-bfd5-fec321510f70"
JOIN users u
ON KEYS b.`user`;
```

**Results**

```json
{
  "results": []
}
```

Notice the booking document no longer exists.

## Related Links

* For an overview of Couchbase transactions, see [learn:data/transactions.adoc](learn:data/transactions.adoc).
* To begin a transaction, see [n1ql-language-reference/begin-transaction.adoc](n1ql-language-reference/begin-transaction.adoc).
* To specify transaction settings, see [n1ql-language-reference/set-transaction.adoc](n1ql-language-reference/set-transaction.adoc).
* To set a savepoint, see [n1ql-language-reference/savepoint.adoc](n1ql-language-reference/savepoint.adoc).
* To commit a transaction, see [n1ql-language-reference/commit-transaction.adoc](n1ql-language-reference/commit-transaction.adoc).
* Blog post: [Couchbase Transactions: Elastic, Scalable, and Distributed](https://blog.couchbase.com/transactions-n1ql-couchbase-distributed-nosql/).
