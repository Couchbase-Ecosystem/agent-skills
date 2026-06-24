# {sqlpp} for Query Reference

<style type="text/css">
  .two-columns {
    column-count: 2;
    column-fill: balance;
  }
</style>

This reference guide describes the syntax and structure of {sqlpp} for Query.
It provides information about the basic elements which can be combined to build {sqlpp} statements.
The Couchbase implementation of {sqlpp} was formerly known as [N1QL](https://www.couchbase.com/products/n1ql).

<a name="n1ql-language-structure"></a>The {sqlpp} language is composed of [statements](#statements), [expressions](#expressions), and [comments](#comments).

## Statements

{sqlpp} statements are categorized into the following groups:

* **Data Definition Language** (DDL) statements enable you to create and modify database objects, such as users, keyspaces, and indexes.
* **Data Control Language** (DCL) statements enable you to control which users or groups have access to data, and what they are permitted to do with that data.
* **Data Manipulation Language** (DML) statements enable you to create, read, update, and delete data.
Some DML statements may be further subcategorized as data query language, transaction control language, or utility statements.

For more details, see [n1ql:n1ql-language-reference/statements.adoc](n1ql:n1ql-language-reference/statements.adoc).

## Expressions

The following are the different types of {sqlpp} expressions:

* [Literal values](n1ql-language-reference/literals.adoc)
* [Identifiers](n1ql-language-reference/identifiers.adoc)
* [Arithmetic terms](n1ql-language-reference/arithmetic.adoc)
* [Comparison terms](n1ql-language-reference/comparisonops.adoc)
* [Concatenation terms](n1ql-language-reference/stringops.adoc)
* [Logical terms](n1ql-language-reference/logicalops.adoc)
* [Conditional expressions](n1ql-language-reference/conditionalops.adoc)
* [Collection expressions](n1ql-language-reference/collectionops.adoc)
* [Construction expressions](n1ql-language-reference/constructionops.adoc)
* [Nested expressions](#nested-path-expressions)
* [Sequence expressions](n1ql-language-reference/sequenceops.adoc)
* [Function calls](n1ql-language-reference/functions.adoc)
* [Subqueries](n1ql-language-reference/subqueries.adoc)

### Nested Path Expressions

In {sqlpp}, _nested paths_ indicate an expression to access nested sub-documents within a JSON document or expression.

For example, in the document below, the latitude of an airport is stored within the `geo` sub-document, and can be addressed using the nested path `geo.lat`:

```json
[
  {
    "airportname": "Calais Dunkerque",
    "city": "Calais",
    "geo": {
      "alt": 12,
      "lat": 50.962097,
      "lon": 1.954764
    },
    "latitude": 51,
    // ...
  }
]
```

You can use [nested operators](n1ql-language-reference/nestedops.adoc) to access sub-document fields within a document.

## Comments

{sqlpp} supports _block comments_ and _line comments_.

### Block Comments

```ebnf
block-comment ::= '/*' ( text | newline )* '*/'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/block-comment.png)

A block comment starts with `/{asterisk}` and ends with `{asterisk}/`.
The query engine ignores the start and end markers `/{asterisk} {asterisk}/`, and any text between them.

A block comment may start on a new line, or in the middle of a line after other {sqlpp} statements.
A block comment may contain line breaks.

There may also be further {sqlpp} statements on the same line after the end of a block comment -- the query engine does _not_ ignore these.

### Line Comments

```ebnf
line-comment ::=  '--' text?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/line-comment.png)

You can use line comments in Couchbase Server 6.5 and later.
A line comment starts with two hyphens `--`.
The query engine ignores the two hyphens, and any text following them up to the end of the line.

A line comment may start on a new line, or in the middle of a line after other {sqlpp} statements.
A line comment may not contain line breaks.

### Optimizer Hints

You can supply hints to the optimizer within a specially-formatted _hint comment_.
For further details, refer to [n1ql-language-reference/optimizer-hints.adoc](n1ql-language-reference/optimizer-hints.adoc).
