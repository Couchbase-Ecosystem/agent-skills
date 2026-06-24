# CREATE SEQUENCE

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

The CREATE SEQUENCE statement enables you to create a sequence in a given scope.

## Purpose

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

### Cache

Sequences operate most efficiently with an in-memory cache of values.
You can specify the size of this cache when you create the sequence.
A block of values is reserved by a node, and requests for values are satisfied from this cache.
When exhausted, a new block of values is reserved.
Reserving a cached block offers a performance boost, as it enables the Query service to return values directly from memory.

Note however that if a Query node shuts down, or if you alter the sequence, the unused values in the cached block are lost: a new block is reserved when you restart the node, or request the next value.
You should choose a cache size with this in mind, along with the expected usage patterns for the sequence.

### Storage

Sequences are stored in the bucket’s hidden `_system` scope.
When you back up a bucket, sequences are included automatically, in accordance with the backup filters.
Similarly, when you restore a bucket, sequences are restored in accordance with the restore command -- if you select to restore specific scopes, the sequences associated with those scopes are restored, and no others.

## Prerequisites

**RBAC Privileges**

To execute the CREATE SEQUENCE statement, you must have the _Query Manage Sequences_ privilege granted on the scope.
For more details about user roles, see [Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
create-sequence ::= 'CREATE' 'SEQUENCE' ( sequence ( 'IF' 'NOT' 'EXISTS' )? |
                    ( 'IF' 'NOT' 'EXISTS' )? sequence )
                    ( create-sequence-options | sequence-with )?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/create-sequence.png)

The CREATE SCOPE statement provides two possible syntaxes for specifying options for a sequence.

* **sequence**\
(Required) A name that identifies the sequence within a namespace, bucket, and scope.
See [Sequence Name](#sequence-name) below.
* **create-sequence-options**\
(Optional) One possible syntax for specifying options for the sequence.
See [Sequence Options](#sequence-options) below.
* **sequence-with**\
(Optional) The other possible syntax for specifying options for the sequence.
See [WITH Clause](#with-clause) below.

### Sequence Name

```ebnf
sequence ::= ( ( namespace ':' )? bucket '.' scope '.' )? identifier
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/sequence.png)

The sequence name specifies the name of the sequence to create.

Each sequence is associated with a given namespace, bucket, and scope.
You must specify the namespace, bucket, and scope to name the sequence correctly.

* **namespace**\
(Optional) The [namespace](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the bucket in which you want to create the sequence.
* **bucket**\
(Optional) The bucket in which you want to create the sequence.
* **scope**\
(Optional) The scope in which you want to create the sequence.
* **identifier**\
(Required) The name of the sequence.
The sequence name must be unique within the scope.

Currently, only the `default` namespace is available.
If you omit the namespace, the default namespace in the current session is used.

If the [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context) is set, you can omit the bucket and scope from the statement.
In this case, the bucket and scope for the sequence are taken from the query context.

The namespace, bucket, scope, and sequence name must follow the rules for [identifiers](n1ql-language-reference/identifiers.adoc).
If the namespace, bucket, scope, or sequence name contain any special characters such as hyphens (-), you must wrap that part of the expression in backticks ({backtick} {backtick}).

### IF NOT EXISTS Clause

The optional `IF NOT EXISTS` clause enables the statement to complete successfully when the specified sequence already exists.
If a sequence with the same name already exists within the specified scope, then:

* If this clause is not present, an error is generated.
* If this clause is present, the statement does nothing and completes without error.

### Sequence Options

```ebnf
create-sequence-options ::= ( start-with
                            | increment-by
                            | maxvalue
                            | minvalue
                            | cycle
                            | cache )*
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/create-sequence-options.png)

You can use the following optional clauses to specify individual attributes for the sequence.
These clauses can occur in any order, but none of them can occur more than once in the statement.

* **start-with**\
[START WITH Clause](#start-with-clause) icon:caret-down[]
* **increment-by**\
[INCREMENT BY Clause](#increment-by-clause) icon:caret-down[]
* **maxvalue**\
[MAXVALUE Clause](#maxvalue-clause) icon:caret-down[]
* **minvalue**\
[MINVALUE Clause](#minvalue-clause) icon:caret-down[]
* **cycle**\
[CYCLE Clause](#cycle-clause) icon:caret-down[]
* **cache**\
[CACHE Clause](#cache-clause) icon:caret-down[]

#### START WITH Clause

```ebnf
start-with ::= 'START' 'WITH' integer
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/start-with.png)

Use the START WITH clause to specify the starting value for the sequence.

If this clause is omitted, the default start value is `0`.

* **integer**\
(Required) The starting value for the sequence.

#### INCREMENT BY Clause

```ebnf
increment-by ::= 'INCREMENT' 'BY' integer
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/increment-by.png)

Use the INCREMENT BY clause to specify the increment value of each step in the sequence.

If this clause is omitted, the increment value is `1` -- that is, at each step in the sequence, the value goes up by `1`.

* **integer**\
(Required) The step size for the sequence.
Use a negative value for a descending sequence.

#### MAXVALUE Clause

```ebnf
maxvalue ::= 'MAXVALUE' integer | 'NO' 'MAXVALUE'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/maxvalue.png)

Use the MAXVALUE clause to specify the maximum value for the sequence.

Use NO MAXVALUE to specify that the maximum value is the highest signed 64-bit integer, `2^63^-1`.

If this clause is omitted, the default is NO MAXVALUE.

* **integer**\
(Optional) The maximum value for the sequence.

#### MINVALUE Clause

```ebnf
minvalue ::= 'MINVALUE' integer | 'NO' 'MINVALUE'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/minvalue.png)

Use the MINVALUE clause to specify the minimum value for the sequence.

Use NO MINVALUE to specify that the minimum value is the lowest signed 64-bit integer, `-2^63^`.

If this clause is omitted, the default is NO MINVALUE.

* **integer**\
(Optional) The minimum value for the sequence.

#### CYCLE Clause

```ebnf
cycle ::= 'CYCLE' | 'NO' 'CYCLE'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/cycle.png)

Use the CYCLE clause to specify the whether the sequence should begin again when it reaches the maximum or minimum value.

Use NO CYCLE to specify that the sequence should stop when it reaches the maximum or minimum value.

If this clause is omitted, the default is NO CYCLE.

#### CACHE Clause

```ebnf
cache ::= 'CACHE' integer | 'NO' 'CACHE'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/cache.png)

Use the CACHE clause to specify the cache size for the sequence.

Use NO CACHE to specify a cache size of `1`.

If this clause is omitted, the default is NO CACHE.

* **integer**\
(Optional) The cache size for the sequence.
The value must be greater than `0`.

### WITH Clause

```ebnf
sequence-with ::= 'WITH' expr
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/sequence-with.png)

You can use the WITH clause to specify options for the sequence using a JSON object.

* **expr**\
(Required) An object with the following properties.

| Name | Description | Schema |
| --- | --- | --- |
| ***start***<br> __optional__ | The starting value for the sequence. ***Default:*** `0` | Integer |
| ***increment***<br> __optional__ | The step size for the sequence. Use a negative value for a descending sequence. ***Default:*** `1` | Integer |
| ***max***<br> __optional__ | The maximum value for the sequence. If unspecified, the maximum is the highest signed 64-bit integer. ***Default:*** `2^63^-1` | Integer (int64) |
| ***min***<br> __optional__ | The minimum value for the sequence. If unspecified, the minimum is the lowest signed 64-bit integer. ***Default:*** `-2^63^` | Integer (int64) |
| ***cycle***<br> __optional__ | Whether the sequence should begin again when it reaches the maximum or minimum value. ***Default:*** `false` | Boolean |
| ***cache***<br> __optional__ | The cache size for the sequence. The value must be greater than `0`. ***Default:*** `50` ***Minimum:*** `1` | Integer |

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-create-seq1"></a>**Create a sequence in a specified scope**

This statement creates a sequence with default attributes in the specified scope.

```sqlpp
CREATE SEQUENCE `travel-sample`.inventory.seq1;
```

<a name="ex-create-seq2"></a>**Create a sequence in the current query context**

This statement creates a sequence with default attributes in the current query context, as long as a sequence of the same name does not already exist.

```sqlpp
CREATE SEQUENCE seq2 IF NOT EXISTS;
```

<a name="ex-create-seq3"></a>**Create a sequence which cycles**

This statement creates a sequence starting at 5 and incrementing by 5 each time.
When the sequence reaches the maximum value of 1000, it starts again at 0.

```sqlpp
CREATE SEQUENCE seq3 IF NOT EXISTS START WITH 5 INCREMENT BY 5 MAXVALUE 1000 MINVALUE 0 CYCLE;
```

The following query tests the sequence.

```sqlpp
SELECT NEXT VALUE FOR seq3;
```

The query returns the specified starting value, 5.

```json
[
  {
    "$1": 5
  }
]
```

<a name="ex-create-seq4"></a>**Create a descending sequence**

This statement creates a sequence that starts at 10 and counts down to 0.
When it reaches the minimum value, the sequence stops.

```sqlpp
CREATE SEQUENCE seq4 IF NOT EXISTS WITH {"start": 10, "increment": -1, "min": 0};
```

The following query tests the sequence.

```sqlpp
SELECT NEXT VALUE FOR seq4;
```

The query returns the specified starting value, 10.

```json
[
  {
    "$1": 10
  }
]
```

See [n1ql-language-reference/sequenceops.adoc](n1ql-language-reference/sequenceops.adoc) for detailed examples using sequences.

## Related Links

* To alter a sequence, see [n1ql-language-reference/altersequence.adoc](n1ql-language-reference/altersequence.adoc).
* To drop a sequence, see [n1ql-language-reference/dropsequence.adoc](n1ql-language-reference/dropsequence.adoc).
* To use a sequence in an expression, see [n1ql-language-reference/sequenceops.adoc](n1ql-language-reference/sequenceops.adoc).
* To monitor sequences, see [Monitor Sequences](n1ql:n1ql-intro/sysinfo.adoc#sys-sequences).
