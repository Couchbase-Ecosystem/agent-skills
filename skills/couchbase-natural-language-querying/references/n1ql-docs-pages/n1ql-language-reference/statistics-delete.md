# Delete Statistics

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

You can use the UPDATE STATISTICS statement to delete statistics.

## Purpose

The `UPDATE STATISTICS` statement provides a syntax which enables you to delete statistics for a set of index expressions, or for an entire keyspace.

Since the [cost-based optimizer](n1ql-language-reference/cost-based-optimizer.adoc) uses statistics for cost calculations, deleting statistics for a set of index expressions effectively turns off the cost-based optimizer for queries which utilize predicates on those expressions.
Deleting all statistics for a keyspace turns off the cost-based optimizer for all queries referencing that keyspace.

## Syntax

```ebnf
update-statistics-delete ::= ( 'UPDATE' 'STATISTICS' 'FOR'? |
                               'ANALYZE' ( 'KEYSPACE' | 'COLLECTION')? )
                               keyspace-ref delete-clause
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/update-statistics-delete.png)

For this syntax, `UPDATE STATISTICS` and `ANALYZE` are synonyms.
The statement must begin with one of these alternatives.

When using the `UPDATE STATISTICS` keywords, the `FOR` keyword is optional.
Including this keyword makes no difference to the operation of the statement.

When using the `ANALYZE` keyword, the `COLLECTION` or `KEYSPACE` keywords are optional.
Including either of these keywords makes no difference to the operation of the statement.

* **keyspace-ref**\
[Keyspace Reference](#keyspace-reference) icon:caret-down[]
* **delete-clause**\
[DELETE Clause](#delete-clause) icon:caret-down[]

### Keyspace Reference

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

The simple name or fully-qualified name of the keyspace for which you want to delete statistics.
Refer to the [CREATE INDEX](n1ql-language-reference/createindex.adoc#keyspace-ref) statement for details of the syntax.

### DELETE Clause

```ebnf
delete-clause ::= 'DELETE' ( delete-expr | delete-all )
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/delete-clause.png)

The `DELETE` clause enables you to provide a comma-separated list of index expressions for which you want to delete statistics, or to specify that you want to delete all statistics for the keyspace.

* **delete-expr**\
[Delete Expressions](#delete-expressions) icon:caret-down[]
* **delete-all**\
[Delete All Statistics](#delete-all-statistics) icon:caret-down[]

#### Delete Expressions

```ebnf
delete-expr ::= 'STATISTICS'? '(' index-key ( ',' index-key )* ')'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/delete-expr.png)

Constraint: if you used the `UPDATE STATISTICS` keywords at the beginning of the statement, you may not use the `STATISTICS` keyword in this clause.

Conversely, if you used the `ANALYZE` keyword at the beginning of the statement, you must include the `STATISTICS` keyword in this clause.

* **index-key**\
[Required] The expression for which you want to delete statistics.
This may be any expression that is supported as an index key, including, but not limited to:
  * A {sqlpp} [expression](n1ql-language-reference/index.adoc) over any fields in the document, as used in a secondary index.
  * An [array expression](n1ql-language-reference/indexing-arrays.adoc#array-expr), as used when creating an array index.
  * An [expression with the META() function](n1ql-language-reference/indexing-meta-info.adoc#metakeyspace_expr-property), as used in a metadata index.

#### Delete All Statistics

```ebnf
delete-all ::= 'ALL' | 'STATISTICS'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/delete-all.png)

Constraint: If you used the `UPDATE STATISTICS` keywords at the beginning of the statement, you must use the `ALL` keyword in this clause.

Conversely, if you used the `ANALYZE` keyword at the beginning of the statement, you must use the `STATISTICS` keyword in this clause.

## Result

The statement returns an empty array.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-1"></a>**Delete statistics with UPDATE STATISTICS**

```sqlpp
UPDATE STATISTICS FOR hotel
DELETE (city, country, free_breakfast);
```

<a name="ex-2"></a>**Delete statistics with ANALYZE**

```sqlpp
ANALYZE KEYSPACE hotel
DELETE STATISTICS (city, country, free_breakfast);
```

This query is equivalent to the query in [Delete statistics with UPDATE STATISTICS](#ex-1).

<a name="ex-3"></a>**Delete all statistics with UPDATE STATISTICS**

```sqlpp
UPDATE STATISTICS FOR airport DELETE ALL;
```

<a name="ex-4"></a>**Delete all statistics with ANALYZE**

```sqlpp
ANALYZE KEYSPACE airport DELETE STATISTICS;
```

This query is equivalent to the query in [Delete all statistics with UPDATE STATISTICS](#ex-3).

## Related Links

* [UPDATE STATISTICS](n1ql-language-reference/updatestatistics.adoc) overview
* [Updating Statistics for Index Expressions](n1ql-language-reference/statistics-expressions.adoc)
* [Updating Statistics for a Single Index](n1ql-language-reference/statistics-index.adoc)
* [Updating Statistics for Multiple Indexes](n1ql-language-reference/statistics-indexes.adoc)
* [Cost-Based Optimizer](n1ql-language-reference/cost-based-optimizer.adoc)
