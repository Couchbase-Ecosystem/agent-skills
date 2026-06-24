# Indexing Metadata Information

Couchbase Server allows indexing on selected metadata fields, for example the expiration and CAS properties.
This improves performance of queries involving predicates on the metadata fields, such as expired documents or recently modified documents.

## Overview

The [META()](n1ql:n1ql-language-reference/metafun.adoc#meta) function enables you to return the metadata for a keyspace or document.
To index a selected metadata field, you must use a [nested expression](n1ql-language-reference/nestedops.adoc#field-selection) containing the `META()` function and the required property, for example `META().id`.

The property name must be separated from the `META()` function by a dot (`.`) and only the following metadata properties can be indexed.
If you attempt to build an index on a metadata field that is not indexable, an error is returned.

* **cas**\
Value representing the current state of an item which changes every time the item is modified.
For details, refer to [Concurrent Document Mutations](java-sdk:howtos:concurrent-document-mutations.adoc).
* **expiration**\
Value representing a document’s expiration date.
A value of 0 (zero) means no expiration date.
For details, refer to [KV Operations](java-sdk:howtos:kv-operations.adoc#document-expiration).

  Note that this property gives correct results only when used in a [Covered Index](n1ql-language-reference/covering-indexes.adoc).
* **id**\
Value representing a document’s unique ID number.
* **xattrs**\
Value representing extended attributes (XATTRs) of a document.

  To access XATTRs, use the syntax `META().xattrs.<attribute>[.<path>]`, where:

  * `<attribute>` is a top-level attribute name or key of the XATTR object.
  * `<path>` is an optional subpath within that attribute.

  While you can create an index on a specific extended attribute like `META().xattrs.attr1`, you cannot create an index on the entire `META().xattrs` object itself.

  **📌 NOTE**\
  Starting with Couchbase Server 8.0, you can index any number of XATTR fields using the [CREATE INDEX](n1ql:n1ql-language-reference/createindex.adoc) statement.

The `META()` function does not require a keyspace parameter when creating an index, since it implicitly uses the keyspace being indexed.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Find two documents that have no expiration date**

**Index**

```sqlpp
CREATE INDEX idx_airline_expire ON airline (META().expiration);
```

**Query**

```sqlpp
SELECT META().id, META().expiration
FROM airline
WHERE META().expiration = 0
ORDER BY META().id
LIMIT 2;
```

**Results**

```json
[
  {
    "expiration": 0,
    "id": "airline_10"
  },
  {
    "expiration": 0,
    "id": "airline_10123"
  }
]
```

**Find all documents whose meta ID tag starts with a letter higher than "g"**

**Index**

```sqlpp
CREATE INDEX idx_hotel_id ON hotel (META().id);
```

**Query**

```sqlpp
SELECT name, META().id
FROM hotel
WHERE META().id > "g"
LIMIT 2;
```

**Results**

```json
[
  {
    "id": "hotel_10025",
    "name": "Medway Youth Hostel"
  },
  {
    "id": "hotel_10026",
    "name": "The Balmoral Guesthouse"
  }
]
```

**Find the two most recently modified hotel documents**

**Index**

```sqlpp
CREATE INDEX idx_hotel_cas ON hotel (META().cas);
```

**Query**

```sqlpp
SELECT name, META().cas
FROM hotel
ORDER BY META().cas DESC
LIMIT 2;
```

**Results**

```json
[
  {
    "cas": 1612962459766947800,
    "name": "The George Hotel"
  },
  {
    "cas": 1612962459645378600,
    "name": "Texas Spring"
  }
]
```
