# DELETE

<style type="text/css">
  /* DOC-10177 */
  .hdlist table tr td.hdlist1,
  .hdlist table tr td.hdlist2 {
    padding: 1.5rem 0 0;
  }

  /* Compact horizontal definition lists */
  .hdlist.compact,
  .hdlist.compact {
    padding-top: 1rem;
  }
  .hdlist.compact table tr td.hdlist1,
  .hdlist.compact table tr td.hdlist2 {
    padding: 0.5rem 0 0;
  }

  /* Descriptions in horizontal description lists should have left padding */
  .hdlist table tr td.hdlist2,
  .hdlist.compact table tr td.hdlist2 {
    padding-left: 1rem;
  }

  /* Paragraphs in horizontal description lists should not have left margin */
  .hdlist table .hdlist1 + .hdlist2 p {
    margin-left: 0; !important
  }

  /* Horizontal definitions should match style of vertical definitions */
  td.hdlist1 {
    font-weight: 600;
  }
</style>

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

DELETE immediately removes the specified document from your keyspace.

## Prerequisites

### RBAC Privileges

To execute the DELETE statement, you must have the _Query Delete_ privilege granted on the target keyspace.
If the statement has any RETURNING clauses that need data read, then the _Query Select_ privilege is also required on the keyspaces referred in the respective clauses.
For more details about user roles, see
[Authorization](learn:security/authorization-overview.adoc).

<details>
<summary>RBAC Examples</summary>

| Delete Query Contains | Query Delete Permissions Needed | Query Select Permissions Needed | Example |
| :-: | :-: | :-: | :-: |
| WHERE clause | Yes | No | [Delete query containing a WHERE clause](#Q1) |
| Subquery | Yes | Yes | [Delete queries containing a subquery](#Q2) |
| RETURNING clause | Yes | Yes | [Delete queries containing a RETURNING clause](#Q3) |
</details>

## Syntax

```ebnf
delete ::= 'DELETE' hint-comment? 'FROM' target-keyspace use-clause? where-clause?
            limit-clause? offset-clause? returning-clause?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/delete.png)

* **hint-comment**\
[Optimizer Hints](#optimizer-hints) icon:caret-down[]
* **target-keyspace**\
[Delete Target](#delete-target) icon:caret-down[]
* **use-clause**\
[USE Clause](#use-clause) icon:caret-down[]
* **where-clause**\
[WHERE Clause](#where-clause) icon:caret-down[]
* **limit-clause**\
[LIMIT Clause](#limit-clause) icon:caret-down[]
* **offset-clause**\
[OFFSET Clause](#offset-clause) icon:caret-down[]
* **returning-clause**\
[RETURNING Clause](#returning-clause) icon:caret-down[]

### Optimizer Hints

Couchbase Server 8.0

You can supply hints to the optimizer within a specially formatted hint comment.
For more information, see [n1ql-language-reference/optimizer-hints.adoc](n1ql-language-reference/optimizer-hints.adoc).

**📌 NOTE**\
DELETE statements support only index hints.
Other hints, such as join hints and ORDERED hints, are not supported.
For an example of using an optimizer hint, see [Delete query with an optimizer hint](#ex-delete-opt-hint).

### Delete Target

```ebnf
target-keyspace ::= keyspace-ref ( 'AS'? alias )?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/target-keyspace.png)

Specifies the data source from which to delete the document.

* **keyspace-ref**\
[Keyspace Reference](#keyspace-reference) icon:caret-down[]
* **alias**\
[AS Alias](#as-alias) icon:caret-down[]

#### Keyspace Reference

```ebnf
keyspace-ref ::= keyspace-path | keyspace-partial
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-ref.png)

```ebnf
keyspace-path ::= ( namespace ':' )? bucket ( '.' scope '.' collection )?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-path.png)

```ebnf
keyspace-partial ::= collection
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-partial.png)

Keyspace reference for the delete target.
For more details, refer to [Keyspace Reference](n1ql-language-reference/from.adoc#from-keyspace-ref).

#### AS Alias

Assigns another name to the keyspace reference.
For details, refer to [AS Clause](n1ql-language-reference/from.adoc#section_ax5_2nx_1db).

Assigning an alias to the keyspace reference is optional.
If you assign an alias to the keyspace reference, the `AS` keyword may be omitted.

### USE Clause

You can use a `USE` clause to provide hints for the delete target.

The clause supports the following hints:

* `USE KEYS`: Specifies the keys of the data items to delete.
* `USE INDEX`: Specifies the index to use for the delete operation.

For more information, see [USE Clause](n1ql-language-reference/hints.adoc).

**📌 NOTE**\
You cannot specify a hint for the same keyspace using both the `USE` clause and an [optimizer hint](#optimizer-hints).
If you do this, the `USE` clause and the [optimizer hint](#optimizer-hints) are both marked as erroneous and ignored by the optimizer.

### WHERE Clause

```ebnf
where-clause ::= 'WHERE' cond
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/where-clause.png)

Specifies the condition that needs to be met for data to be deleted.
Optional.

### LIMIT Clause

```ebnf
limit-clause ::= 'LIMIT' expr
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/limit-clause.png)

Specifies the greatest number of objects that can be deleted.
This clause must have a non-negative integer as its upper bound.
Optional.

### OFFSET Clause

```ebnf
offset-clause ::= 'OFFSET' expr
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/offset-clause.png)

Like the [OFFSET clause](n1ql-language-reference/offset.adoc) for a SELECT query, you can include an OFFSET clause in a DELETE statement to specify a number of objects to skip before beginning the deletion.
This option can be useful for parallelizing a large delete operation.

You can include the OFFSET clause either before or after the optional LIMIT clause.
The position has no effect on the result.

The expression for this clause must be a non-negative integer.
Optional.

### RETURNING Clause

```ebnf
returning-clause ::= 'RETURNING' (result-expr (',' result-expr)* |
                    ('RAW' | 'ELEMENT' | 'VALUE') expr)
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/returning-clause.png)

Specifies the information to be returned by the operation as a query result.
For more details, refer to [RETURNING Clause](n1ql-language-reference/insert.adoc#returning-clause).

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**⚠️ WARNING**\
Be aware that running the following examples will permanently delete your sample data.
To restore your sample data, remove and reinstall the `travel-sample` bucket.
Refer to [Sample Buckets](manage:manage-settings/install-sample-buckets.adoc) for details.

<a name="Q1"></a>**Delete query containing a WHERE clause**

This example requires the _Query Delete_ privilege on `hotel`.

```sqlpp
DELETE FROM hotel;
```

<a name="Q2"></a>**Delete queries containing a subquery**

This example requires the _Query Delete_ privilege on `airport` and the _Query Select_ privilege on `pass:c[`beer-sample`]`.

```sqlpp
DELETE FROM airport
WHERE city IN (SELECT raw city FROM `beer-sample` WHERE city IS NOT MISSING)
RETURNING airportname;
```

This example requires the _Query Delete_ and _Query Select_ privileges on `airport`.

```sqlpp
DELETE FROM airport
WHERE city IN (SELECT RAW MAX(t.city) FROM airport AS t)
RETURNING airportname;
```

<a name="Q3"></a>**Delete queries containing a RETURNING clause**

These examples require the _Query Delete_ and _Query Select_ privileges on `hotel`.

```sqlpp
DELETE FROM hotel RETURNING *;
```

```sqlpp
DELETE FROM hotel
WHERE city = "San Francisco"
RETURNING meta().id;
```

**Delete by key**

This example deletes the document `airline_4444`.

```sqlpp
DELETE FROM airline k
USE KEYS "airline_4444"
RETURNING k
```

**Results**

```json
[
  {
    "k": {
      "callsign": "MY-AIR",
      "country": "United States",
      "iata": "Z1",
      "icao": "AQZ",
      "name": "80-My Air",
      "id": "4444",
      "type": "airline"
    }
  }
]
```

**Delete by filter**

This example deletes the airline with the callsign "AIR-X".

```sqlpp
DELETE FROM airline f
WHERE f.callsign = "AIR-X"
RETURNING f.id
```

**Results**

```json
[
  {
    "id": "4445"
  }
]
```

**Delete with LIMIT and OFFSET**

This example deletes a subset of the airlines with a country of "France'.
First, you query to get a list of the airlines in France.

```sqlpp
SELECT id FROM airline 
WHERE country="France";
```

There are 21 documents in this collection with `country="France"`.

**Results**

```text
[
    {
      "id": 1191
    },
    {
      "id": 1203
    },
    {
      "id": 137
    },
    {
      "id": 139
    },
    {
      "id": 13947
    },
    {
      "id": 1523
    },
    {
      "id": 16837
    },
    {
      "id": 1908
    },
    {
      "id": 1909
    },
    {
      "id": 21     //<.>
    },
    {
      "id": 225
    },
    {
      "id": 2704
    },
    {
      "id": 2757
    },
    {
      "id": 4299
    },
    {
      "id": 477
    },
    {
      "id": 4965
    },
    {
      "id": 547
    },
    {
      "id": 5479
    },
    {
      "id": 551
    },
    {
      "id": 567    //<.>
    },
    {
      "id": 8745
    }
  ]
```

1. The 10th document’s id.
2. The 20th document’s id.

Next, you specify that you want to delete up to 10 documents, after skipping the first 10.

```sqlpp
DELETE FROM airline 
WHERE country="France"
LIMIT 10 OFFSET 10;

SELECT id FROM airline 
WHERE country="France";
```

Now there are 11 documents in this collection with `country="France"`.

**Results**

```text
[
    {
      "id": 1191
    },
    {
      "id": 1203
    },
    {
      "id": 137
    },
    {
      "id": 139
    },
    {
      "id": 13947
    },
    {
      "id": 1523
    },
    {
      "id": 16837
    },
    {
      "id": 1908
    },
    {
      "id": 1909
    },
    {
      "id": 21   //<.>
    },
    {
      "id": 8745 //<.>
    }
  ]
```

1. Documents with the first 10 ids--the offset--remain in the airline collection.
2. After deleting 10 documents--the limit--1 more document remains in the collection.

<a name="ex-delete-opt-hint"></a>**Delete query with an optimizer hint**

The following query hints the optimizer to use the index, `def_inventory_hotel_city`.

```sqlpp
DELETE /*+ INDEX (hotel def_inventory_hotel_city) */ 
FROM `hotel`
WHERE city = "San Francisco";



```

If you examine the plan for this query, you can see that the query uses the suggested index.

**Results**


"index": "def_inventory_hotel_city",
"index_id": "c31e7f44f9ff274c",
"keyspace": "hotel",
"namespace": "default",
```

<a name="ex-delete-use-clause"></a>**Delete query with a USE INDEX clause**

The following query hints the Query Service to use the index, `def_inventory_hotel_city`.
This is equivalent to [Delete query with an optimizer hint](#ex-delete-opt-hint) but uses a `USE INDEX` clause instead of an optimizer hint.

```sqlpp
DELETE FROM `hotel`
USE INDEX (def_inventory_hotel_city)
WHERE city = "San Francisco";
```

If you examine the plan for this query, you can see that the query uses the suggested index.

**Results**


"index": "def_inventory_hotel_city",
"index_id": "c31e7f44f9ff274c",
"keyspace": "hotel",
"namespace": "default",
```
