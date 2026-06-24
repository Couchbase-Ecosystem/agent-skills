# DROP SEQUENCE

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

The DROP SEQUENCE statement enables you to drop a sequence in a given scope.

## Purpose

A sequence is a construct that returns a sequence of integer values, one at a time, rather like a counter.
Each time you request the next value for a sequence, an increment is added to the previous value, and the resulting value is returned.
This is useful for generating values such as sequential ID numbers, where you need the Query service to keep track of the current value from one query to the next.

## Prerequisites

**RBAC Privileges**

To execute the DROP SEQUENCE statement, you must have the _Query Manage Sequences_ privilege granted on the scope.
For more details about user roles, see [Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
drop-sequence ::= 'DROP' 'SEQUENCE' ( sequence ( 'IF' 'EXISTS' )? |
                  ( 'IF' 'EXISTS' )? sequence )
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/drop-sequence.png)

* **sequence**\
(Required) A name that identifies the sequence within a namespace, bucket, and scope.
See [Sequence Name](#sequence-name) below.

### Sequence Name

```ebnf
sequence ::= ( ( namespace ':' )? bucket '.' scope '.' )? identifier
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/sequence.png)

The sequence name specifies the name of the sequence to drop.

Each sequence is associated with a given namespace, bucket, and scope.
You must specify the namespace, bucket, and scope to refer to the sequence correctly.

* **namespace**\
(Optional) The [namespace](n1ql-intro/queriesandresults.adoc#logical-hierarchy) of the bucket which contains the sequence you want to drop.
* **bucket**\
(Optional) The bucket which contains the sequence you want to drop.
* **scope**\
(Optional) The scope which contains the sequence you want to drop.
* **identifier**\
(Required) The name of the sequence.
The sequence name is case-sensitive.

Currently, only the `default` namespace is available.
If you omit the namespace, the default namespace in the current session is used.

If the [query context](n1ql:n1ql-intro/queriesandresults.adoc#query-context) is set, you can omit the bucket and scope from the statement.
In this case, the bucket and scope for the sequence are taken from the query context.

The namespace, bucket, scope, and sequence name must follow the rules for [identifiers](n1ql-language-reference/identifiers.adoc).
If the namespace, bucket, scope, or sequence name contain any special characters such as hyphens (-), you must wrap that part of the expression in backticks ({backtick} {backtick}).

### IF EXISTS Clause

The optional `IF EXISTS` clause enables the statement to complete successfully when the specified sequence doesn’t exist.

When the sequence does not exist within the specified context:

* If this clause is not present, an error is generated.
* If this clause is present, the statement does nothing and completes without error.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-drop-seq1"></a>**Drop a sequence in a specified scope**

This statement drops a sequence in the specified scope.

```sqlpp
DROP SEQUENCE `travel-sample`.inventory.seq1;
```

<a name="ex-drop-seq2"></a>**Drop a sequence in the current query context**

This statement drops a sequence in the current query context, if a sequence of that name exists.

```sqlpp
DROP SEQUENCE seq2 IF EXISTS;
```

## Related Links

* To create a sequence, see [n1ql-language-reference/createsequence.adoc](n1ql-language-reference/createsequence.adoc).
* To alter a sequence, see [n1ql-language-reference/altersequence.adoc](n1ql-language-reference/altersequence.adoc).
* To use a sequence in an expression, see [n1ql-language-reference/sequenceops.adoc](n1ql-language-reference/sequenceops.adoc).
* To monitor sequences, see [Monitor Sequences](n1ql:n1ql-intro/sysinfo.adoc#sys-sequences).
