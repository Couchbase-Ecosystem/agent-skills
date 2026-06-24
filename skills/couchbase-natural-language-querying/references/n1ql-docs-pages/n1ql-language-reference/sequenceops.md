# Sequence Operators

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

Sequence operators enable you to return a value from a sequence.

## Sequences

A sequence is a construct that returns a sequence of integer values, one at a time, rather like a counter.
Each time you request the next value for a sequence, an increment is added to the previous value, and the resulting value is returned.
This is useful for generating values such as sequential ID numbers, where you need the Query service to keep track of the current value from one query to the next.

You can define any of the following attributes when you create a sequence.
You can alter an existing sequence in order to restart it, or to change any of the sequence attributes.

### Start Value, Increment, and Direction

By default, a sequence starts at `0` and goes up by `1` at each step.
You can specify the start value of the sequence, the incremental value for the sequence, and the direction of the sequence: ascending or descending.

### Maximum and Minimum Value

The highest possible value for a sequence is the highest signed 64-bit integer, `2^63^-1`.
This is the default maximum value.

The lowest possible value for a sequence is the lowest signed 64-bit integer, `-2^63^`.
This is the default minimum value.

You can specify a different maximum or minimum value for a sequence.

### Cycling

A sequence may permit cycling.
In this case, the sequence behaves as follows:

* If the sequence is ascending, then when it reaches the maximum value, it continues from the minimum value -- which may be different to the sequence’s specified starting value.
* If the sequence is descending, then when it reaches the minimum value, it continues from the maximum value -- which may be different to the sequence’s specified starting value.

If a sequence does not permit cycling, then when it reaches the maximum or minimum value, it generates an error.

## Next Value Operator

The next value operator increments a given sequence and returns the next value.

### Prerequisites

**RBAC Privileges**

To use this operator, you must have the _Query Use Sequences_ privilege granted on the scope.
For more details about user roles, see [Authorization](learn:security/authorization-overview.adoc).

### Syntax

```ebnf
next-val-expr ::= 'NEXT' 'VALUE' 'FOR' sequence |
                  'NEXTVAL' 'FOR' sequence
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/next-val-expr.png)

Synonym: `NEXT VALUE FOR` and `NEXTVAL FOR` are synonyms.

* **sequence**\
(Required) A name that identifies the sequence within a namespace, bucket, and scope.
See [Sequence Name](#sequence-name) below.

#### Sequence Name

```ebnf
sequence ::= ( ( namespace ':' )? bucket '.' scope '.' )? identifier
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/sequence.png)

Each sequence is associated with a given namespace, bucket, and scope.
You must specify the namespace, bucket, and scope to refer to the sequence correctly.

* **namespace**\
(Optional) The [namespace](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the bucket which contains the sequence.
* **bucket**\
(Optional) The bucket which contains the sequence.
* **scope**\
(Optional) The scope which contains the sequence.
* **identifier**\
(Required) The name of the sequence.
The sequence name is case-sensitive.

Currently, only the `default` namespace is available.
If you omit the namespace, the default namespace in the current session is used.

If the [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context) is set, you can omit the bucket and scope from the statement.
In this case, the bucket and scope for the sequence are taken from the query context.

The namespace, bucket, scope, and sequence name must follow the rules for [identifiers](n1ql-language-reference/identifiers.adoc).
If the namespace, bucket, scope, or sequence name contain any special characters such as hyphens (-), you must wrap that part of the expression in backticks ({backtick} {backtick}).

### Return Value

For a new sequence, the next value operator returns the starting value in the sequence.

For a sequence that has been referenced already, the next value operator increments the sequence and returns the new value.
However, the sequence is only incremented once per document.

Subqueries operate on independent documents from their containing queries, so subqueries increment the sequence independently.

<dl><dt><strong>📌 NOTE</strong></dt><dd>

A sequence is not guaranteed to generate unique values.
For example, in the following circumstances, it may generate a value that it has generated before:

* If the sequence cycles.
* If the sequence is restarted with a value that overlaps with previously-generated values.
* If the sequence is restarted to change the direction of the increment: for example, descending instead of ascending.
</dd></dl>

### Restrictions

You cannot use this operator in a WHERE or ON clause.
This generates a semantic error 3100.

### Examples

To try the examples in this section, set the query context to the `tenant_agent_00` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-nextval-start"></a>**Start a sequence**

This statement starts a sequence called `ordNum` for use in the following examples.

**Query**

```sqlpp
CREATE SEQUENCE ordNum START WITH 1000;
```

<a name="ex-nextval-doc"></a>**Insert a sequential value in a document body**

The following statement uses the `ordNum` sequence to generate a booking number within the body of the document.

**Query**

```sqlpp
INSERT INTO bookings
  VALUES (UUID(),
    {"num": NEXT VALUE FOR ordNum, "user": 0})
  RETURNING *;
```

**Results**

```json
[
  {
    "bookings": {
      "num": 1000,
      "user": 0
    }
  }
]
```

<a name="ex-nextval-key"></a>**Insert a sequential value in a document key and body**

The following statement uses the `ordNum` sequence to generate the document key and a booking number within the body of the document.

**Query**

```sqlpp
INSERT INTO bookings
  VALUES (TO_STRING(NEXTVAL FOR ordNum),
    {"num": NEXTVAL FOR ordNum, "user": 1})
  RETURNING META().id, *;
```

This query gives different results, depending on the version of Couchbase Server.

---

#Couchbase Server 7.6–7.6.3#

**Results**

```json
[
  {
    "id": "1001",
    "bookings": {
      "num": 1002,
      "user": 1
    }
  }
]
```

In versions of Couchbase Server prior to 7.6.4, the key is not regarded as part of the document, so this query increments the sequence twice.
This gives a different sequence number for the document key and the document value.

---

Couchbase Server 7.6.4

**Results**

```json
[
  {
    "id": "1001",
    "bookings": {
      "num": 1001,
      "user": 1
    }
  }
]
```

In Couchbase Server 7.6.4 and later, the entire VALUES clause (key, value, and options) is regarded as a single document, so the query only increments the sequence once.
This gives the same sequence number in the document key and the document value.

<a name="ex-nextval-same"></a>**Insert a sequential value with INSERT SELECT**

The following statement uses an INSERT SELECT statement.
With this query, the document key and document value are both generated within the same document.

**Query**

```sqlpp
INSERT INTO bookings (KEY k, VALUE v)
  SELECT TO_STRING(NEXTVAL FOR ordNum) k,
         {"num": NEXTVAL FOR ordNum, "user": 1} v
  RETURNING META().id, *;
```

**Result**

```json
[
  {
    "id": "1003",
    "bookings": {
      "num": 1003,
      "user": 1
    }
  }
]
```

The next value operator only increments a sequence once within the context of a document.
This gives the same sequence number in the document key and the document value.

## Previous Value Operator

The previous value operator returns the current value in a sequence, without incrementing or decrementing the sequence.
This is useful when you need to refer to the same value again without generating a new value.

### Prerequisites

**RBAC Privileges**

To use this operator, you must have the _Query Use Sequences_ privilege granted on the scope.
For more details about user roles, see [Authorization](learn:security/authorization-overview.adoc).

### Syntax

```ebnf
prev-val-expr ::= 'PREVIOUS' 'VALUE' 'FOR' sequence |
                  'PREV' 'VALUE' 'FOR' sequence |
                  'PREVVAL' 'FOR' sequence
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/prev-val-expr.png)

Synonym: `PREVIOUS VALUE FOR`, `PREV VALUE FOR`, and `PREVVAL FOR` are synonyms.

* **sequence**\
(Required) A name that identifies the sequence within a namespace, bucket, and scope.
See [Sequence Name](#sequence-name) below.

#### Sequence Name

```ebnf
sequence ::= ( ( namespace ':' )? bucket '.' scope '.' )? identifier
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/sequence.png)

Each sequence is associated with a given namespace, bucket, and scope.
You must specify the namespace, bucket, and scope to refer to the sequence correctly.

* **namespace**\
(Optional) The [namespace](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the bucket which contains the sequence.
* **bucket**\
(Optional) The bucket which contains the sequence.
* **scope**\
(Optional) The scope which contains the sequence.
* **identifier**\
(Required) The name of the sequence.
The sequence name is case-sensitive.

Currently, only the `default` namespace is available.
If you omit the namespace, the default namespace in the current session is used.

If the [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context) is set, you can omit the bucket and scope from the statement.
In this case, the bucket and scope for the sequence are taken from the query context.

The namespace, bucket, scope, and sequence name must follow the rules for [identifiers](n1ql-language-reference/identifiers.adoc).
If the namespace, bucket, scope, or sequence name contain any special characters such as hyphens (-), you must wrap that part of the expression in backticks ({backtick} {backtick}).

### Return Value

The previous value operator returns one of the following, in order of precedence:

1. If a value has been generated for the current document, the operator returns the current value generated for the document.
2. If in a transaction, and a value has been generated for the transaction, the operator returns the current value generated in the transaction.
3. Otherwise, the operator returns the current value generated for the sequence on the node.

The previous value operator does not increment or decrement the sequence.

If no value has been generated for the sequence, the previous value operator returns an error.

### Restrictions

You cannot use this operator in a WHERE or ON clause.
This generates a semantic error 3100.

### Examples

To try the examples in this section, set the query context to the `tenant_agent_00` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-prevval-multi"></a>**Insert the same sequential value in multiple statements**

This example assumes that you have created a sequence called `ordNum` as described in [Start a sequence](#ex-nextval-start).

**Query**

```sqlpp
BEGIN TRANSACTION;
INSERT INTO bookings VALUES(UUID(),
  {"num": NEXT VALUE FOR ordNum,
   "user": 0,
   "type": "order"});
INSERT INTO bookings VALUES(UUID(),
  {"order_num": PREVVAL FOR ordNum,
   "hotel": "hotel_17413",
   "type": "item"});
INSERT INTO bookings VALUES(UUID(),
  {"order_num": PREVVAL FOR ordNum,
   "hotel": "hotel_15912",
   "type": "item"});
COMMIT;
```

<a name="ex-prevval-test"></a>**Check the result of [Insert the same sequential value in multiple statements](#ex-prevval-multi)**

**Query**

```sqlpp
SELECT o.num, o.user, ARRAY_AGG(i.hotel) items
FROM bookings o,
     bookings i
WHERE o.type = "order"
  AND i.type = "item"
  AND o.num = i.order_num
GROUP BY o.num, o.user;
```

**Result**

```json
[
  {
    "num": 1004,
    "user": 0,
    "items": [
      "hotel_15912",
      "hotel_17413"
    ]
  }
]
```

## Related Links

* To create a sequence, see [n1ql-language-reference/createsequence.adoc](n1ql-language-reference/createsequence.adoc).
* To alter a sequence, see [n1ql-language-reference/altersequence.adoc](n1ql-language-reference/altersequence.adoc).
* To drop a sequence, see [n1ql-language-reference/dropsequence.adoc](n1ql-language-reference/dropsequence.adoc).
* To monitor sequences, see [Monitor Sequences](n1ql:n1ql-intro/sysinfo.adoc#sys-sequences).
