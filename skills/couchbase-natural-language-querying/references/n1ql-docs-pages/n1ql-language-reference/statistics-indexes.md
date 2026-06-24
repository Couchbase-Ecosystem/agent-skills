# Update Statistics for Multiple Indexes

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

You can use the UPDATE STATISTICS statement to gather statistics for multiple indexes at once.

## Purpose

The `UPDATE STATISTICS` statement provides a syntax which enables you to analyze multiple indexes at once.
With this syntax, the statement gathers statistics for all the index key expressions from all specified indexes.
This provides a shorthand so that you do not need to list all the index key expressions explicitly.

If the same index expression is included in multiple indexes, duplicate index expressions are removed, so each index expression is only analyzed once.

## Syntax

```ebnf
update-statistics-indexes ::= ( 'UPDATE' 'STATISTICS' 'FOR'? |
                                'ANALYZE' ( 'KEYSPACE' | 'COLLECTION')? )
                                keyspace-ref indexes-clause index-using? index-with?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/update-statistics-indexes.png)

For this syntax, `UPDATE STATISTICS` and `ANALYZE` are synonyms.
The statement must begin with one of these alternatives.

When using the `UPDATE STATISTICS` keywords, the `FOR` keyword is optional.
Including this keyword makes no difference to the operation of the statement.

When using the `ANALYZE` keyword, the `COLLECTION` or `KEYSPACE` keywords are optional.
Including either of these keywords makes no difference to the operation of the statement.

* **keyspace-ref**\
[Keyspace Reference](#keyspace-reference) icon:caret-down[]
* **indexes-clause**\
[INDEX Clause](#index-clause) icon:caret-down[]
* **index-using**\
[USING Clause](#using-clause) icon:caret-down[]
* **index-with**\
[WITH Clause](#with-clause) icon:caret-down[]

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

The simple name or fully-qualified name of the keyspace on which the indexes are built.
Refer to the [CREATE INDEX](n1ql-language-reference/createindex.adoc#keyspace-ref) statement for details of the syntax.

### INDEX Clause

```ebnf
indexes-clause ::= 'INDEX' ( '(' ( index-name ( ',' index-name )* | subquery-expr ) ')' |
                             'ALL' )
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/indexes-clause.png)

For this syntax, the `INDEX` clause enables you to specify a comma-separated list of index names, a subquery which returns an array of index names, or all the indexes in the specified keyspace.

* **index-name**\
A unique name that identifies an index.
* **subquery-expr**\
[Subquery Expression](#subquery-expression) icon:caret-down[]

#### Subquery Expression

```ebnf
subquery-expr ::= '(' select ')'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/subquery-expr.png)

Use parentheses to specify a subquery.

The subquery must return an array of strings, each string representing the name of an index.
The subquery should look for GSI indexes that are in the online state.
Refer to [UPDATE STATISTICS with subquery](#ex-3) and [ANALYZE with subquery](#ex-4) for details.

#### INDEX ALL

The `INDEX ALL` keywords enable you to analyze all the indexes in the specified keyspace, without having to use a subquery.
Refer to [UPDATE STATISTICS with all indexes](#ex-5) and [ANALYZE with all indexes](#ex-6) for details.

### USING Clause

```ebnf
index-using ::= 'USING' 'GSI'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/index-using.png)

In Couchbase Server 6.5 and later, the index type for a secondary index must be Global Secondary Index (GSI).
The `USING GSI` keywords are optional and may be omitted.

### WITH Clause

```ebnf
index-with ::= 'WITH' expr
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/index-with.png)

Use the `WITH` clause to specify additional options.

* **expr**\
An object with the following properties:

sample_size;;
[Optional] An integer specifying the sample size to use for distribution statistics.
A minimum sample size is also calculated.
If the specified sample size is smaller than the minimum sample size, the minimum sample size is used instead.

resolution;;
[Optional] A float representing the percentage of documents to store in each distribution bin.
If omitted, the default value is `1.0`, meaning each distribution bin contains 1% of the documents, and therefore 100 bins are required.
The minimum resolution is `0.02` (5000 distribution bins) and the maximum is `5.0` (20 distribution bins).

update_statistics_timeout;;
[Optional] A number representing a duration in seconds.
The command times out when this timeout period is reached.
If omitted, a default timeout value is calculated based on the number of samples used.

batch_size;;
[Optional] Only applies when processing multiple index expressions at once.
If there is a large number of index expressions to process, the cost-based optimizer deals with them in batches.
This option is an integer specifying the maximum number of index expressions in each batch.
If omitted, the default value is `10`.
You can specify a different value based on the memory availability of the system.
Note that when index expressions are processed in batches, the `update_statistics_timeout` value (above) applies to each batch.

Refer to [Distribution Statistics](n1ql-language-reference/cost-based-optimizer.adoc#distribution-stats) for more information on sample size and resolution.

## Result

The statement returns an empty array.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-1"></a>**UPDATE STATISTICS with indexes**

```sqlpp
UPDATE STATISTICS FOR airport
INDEX (def_inventory_airport_faa, def_inventory_airport_city);
```

<a name="ex-2"></a>**ANALYZE with indexes**

```sqlpp
ANALYZE KEYSPACE airport
INDEX (def_inventory_airport_faa, def_inventory_airport_city);
```

This query is equivalent to the query in [UPDATE STATISTICS with indexes](#ex-1).

<a name="ex-3"></a>**UPDATE STATISTICS with subquery**

```sqlpp
UPDATE STATISTICS FOR airport INDEX (( -- ①
  SELECT RAW name -- ②
  FROM system:indexes
  WHERE state = "online"
    AND `using` = "gsi" -- ③
    AND bucket_id = "travel-sample" 
    AND scope_id = "inventory"
    AND keyspace_id = "airport" ));
```

1. One set of parentheses delimits the whole group of index terms, and the other set of parentheses delimits the subquery, leading to a double set of parentheses.
2. The `RAW` keyword forces the subquery to return a flattened array of strings, each of which refers to an index name.
3. Since `USING` is a reserved keyword, you need to surround it in backticks in the query.

<a name="ex-4"></a>**ANALYZE with subquery**

```sqlpp
ANALYZE KEYSPACE airport INDEX ((
  SELECT RAW name
  FROM system:indexes
  WHERE state = "online"
    AND `using` = "gsi"
    AND bucket_id = "travel-sample" 
    AND scope_id = "inventory"
    AND keyspace_id = "airport" ));
```

This query is equivalent to the query in [UPDATE STATISTICS with subquery](#ex-3).

<a name="ex-5"></a>**UPDATE STATISTICS with all indexes**

```sqlpp
UPDATE STATISTICS FOR airport INDEX ALL;
```

<a name="ex-6"></a>**ANALYZE with all indexes**

```sqlpp
ANALYZE KEYSPACE airport INDEX ALL;
```

This query is equivalent to the query in [UPDATE STATISTICS with all indexes](#ex-5).

## Related Links

* [UPDATE STATISTICS](n1ql-language-reference/updatestatistics.adoc) overview
* [Updating Statistics for Index Expressions](n1ql-language-reference/statistics-expressions.adoc)
* [Updating Statistics for a Single Index](n1ql-language-reference/statistics-index.adoc)
* [Deleting Statistics](n1ql-language-reference/statistics-delete.adoc)
* [Cost-Based Optimizer](n1ql-language-reference/cost-based-optimizer.adoc)
