# Update Statistics for a Single Index

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

You can use the UPDATE STATISTICS statement to gather statistics on a single index.

## Purpose

The `UPDATE STATISTICS` statement provides a syntax which enables you to analyze a single index.
With this syntax, the statement gathers statistics for all the index key expressions in the specified index.
This provides a shorthand so that you do not need to list all the index key expressions explicitly.

## Syntax

```ebnf
update-statistics-index ::= ( 'UPDATE' 'STATISTICS' 'FOR' | 'ANALYZE' )
                              index-clause index-using?  index-with?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/update-statistics-index.png)

For this syntax, `UPDATE STATISTICS FOR` and `ANALYZE` are synonyms.
The statement must begin with one of these alternatives.

* **index-clause**\
[INDEX Clause](#index-clause) icon:caret-down[]
* **index-using**\
[USING Clause](#using-clause) icon:caret-down[]
* **index-with**\
[WITH Clause](#with-clause) icon:caret-down[]

### INDEX Clause

```ebnf
index-clause ::= 'INDEX' ( index-path '.' index-name | index-name 'ON' keyspace-ref )
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/index-clause.png)

For this syntax, the `INDEX` clause enables you to specify the index name and a keyspace.

* **index-name**\
A unique name that identifies the index.
* **index-path**\
[Index Path](#index-path) icon:caret-down[]
* **keyspace-ref**\
[Keyspace Reference](#keyspace-reference) icon:caret-down[]

#### Index Path

```ebnf
index-path ::= keyspace-full | keyspace-prefix | keyspace-partial
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/index-path.png)

```ebnf
keyspace-full ::= namespace ':' bucket '.' scope '.' collection
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-full.png)

```ebnf
keyspace-prefix ::= ( namespace ':' )? bucket
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-prefix.png)

```ebnf
keyspace-partial ::= collection
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-partial.png)

You can use a dotted notation to specify the index and the keyspace on which the index is built.
Refer to the [ALTER INDEX](n1ql-language-reference/alterindex.adoc#index-path) or [DROP INDEX](n1ql-language-reference/dropindex.adoc#index-path) statements for details of the syntax.

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

Alternatively, you can use the index name with the `ON` keyword and a keyspace reference to specify the keyspace on which the index is built.
Refer to the [ALTER INDEX](n1ql-language-reference/alterindex.adoc#keyspace-ref) or [DROP INDEX](n1ql-language-reference/dropindex.adoc#keyspace-ref) statements for details of the syntax.

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

<a name="ex-1"></a>**UPDATE STATISTICS with index identifier**

```sqlpp
UPDATE STATISTICS FOR
INDEX airport.def_inventory_airport_city;
```

<a name="ex-2"></a>**UPDATE STATISTICS with ON clause**

```sqlpp
UPDATE STATISTICS FOR
INDEX def_inventory_airport_city ON airport;
```

This query is equivalent to the query in [UPDATE STATISTICS with index identifier](#ex-1).

<a name="ex-3"></a>**ANALYZE with index identifier**

```sqlpp
ANALYZE INDEX airport.def_inventory_airport_city;
```

This query is equivalent to the query in [UPDATE STATISTICS with index identifier](#ex-1).

<a name="ex-4"></a>**ANALYZE with ON clause**

```sqlpp
ANALYZE INDEX def_inventory_airport_city ON airport;
```

This query is equivalent to the query in [UPDATE STATISTICS with index identifier](#ex-1).

## Related Links

* [UPDATE STATISTICS](n1ql-language-reference/updatestatistics.adoc) overview
* [Updating Statistics for Index Expressions](n1ql-language-reference/statistics-expressions.adoc)
* [Updating Statistics for Multiple Indexes](n1ql-language-reference/statistics-indexes.adoc)
* [Deleting Statistics](n1ql-language-reference/statistics-delete.adoc)
* [Cost-Based Optimizer](n1ql-language-reference/cost-based-optimizer.adoc)
