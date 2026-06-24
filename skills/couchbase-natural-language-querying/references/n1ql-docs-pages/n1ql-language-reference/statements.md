# Statements

<style type="text/css">
  .two-columns {
    column-count: 2;
    column-fill: balance;
  }
</style>

Statements are the commands that make up a {sqlpp} query. \

## Data Definition Language

Data definition language (DDL) statements enable you to create and modify database objects, such as users, buckets, and indexes.

[n1ql:n1ql-language-reference/alterbucket.adoc](n1ql:n1ql-language-reference/alterbucket.adoc)\
[n1ql:n1ql-language-reference/altergroup.adoc](n1ql:n1ql-language-reference/altergroup.adoc)\
[n1ql:n1ql-language-reference/alterindex.adoc](n1ql:n1ql-language-reference/alterindex.adoc)\
[n1ql:n1ql-language-reference/altersequence.adoc](n1ql:n1ql-language-reference/altersequence.adoc)\
[n1ql:n1ql-language-reference/alteruser.adoc](n1ql:n1ql-language-reference/alteruser.adoc)\
[n1ql:n1ql-language-reference/altervectorindex.adoc](n1ql:n1ql-language-reference/altervectorindex.adoc)\
[n1ql:n1ql-language-reference/build-index.adoc](n1ql:n1ql-language-reference/build-index.adoc)\
[n1ql:n1ql-language-reference/createbucket.adoc](n1ql:n1ql-language-reference/createbucket.adoc)\
[n1ql:n1ql-language-reference/createcollection.adoc](n1ql:n1ql-language-reference/createcollection.adoc)\
[n1ql:n1ql-language-reference/createfunction.adoc](n1ql:n1ql-language-reference/createfunction.adoc)\
[n1ql:n1ql-language-reference/creategroup.adoc](n1ql:n1ql-language-reference/creategroup.adoc)\
[n1ql:n1ql-language-reference/createindex.adoc](n1ql:n1ql-language-reference/createindex.adoc)\
[n1ql:n1ql-language-reference/createprimaryindex.adoc](n1ql:n1ql-language-reference/createprimaryindex.adoc)\
[n1ql:n1ql-language-reference/createsequence.adoc](n1ql:n1ql-language-reference/createsequence.adoc)\
[n1ql:n1ql-language-reference/createscope.adoc](n1ql:n1ql-language-reference/createscope.adoc)\
[n1ql:n1ql-language-reference/createuser.adoc](n1ql:n1ql-language-reference/createuser.adoc)\
[n1ql:n1ql-language-reference/createvectorindex.adoc](n1ql:n1ql-language-reference/createvectorindex.adoc)\
[n1ql:n1ql-language-reference/dropbucket.adoc](n1ql:n1ql-language-reference/dropbucket.adoc)\
[n1ql:n1ql-language-reference/dropcollection.adoc](n1ql:n1ql-language-reference/dropcollection.adoc)\
[n1ql:n1ql-language-reference/dropfunction.adoc](n1ql:n1ql-language-reference/dropfunction.adoc)\
[n1ql:n1ql-language-reference/dropgroup.adoc](n1ql:n1ql-language-reference/dropgroup.adoc)\
[n1ql:n1ql-language-reference/dropindex.adoc](n1ql:n1ql-language-reference/dropindex.adoc)\
[n1ql:n1ql-language-reference/dropprimaryindex.adoc](n1ql:n1ql-language-reference/dropprimaryindex.adoc)\
[n1ql:n1ql-language-reference/dropsequence.adoc](n1ql:n1ql-language-reference/dropsequence.adoc)\
[n1ql:n1ql-language-reference/dropscope.adoc](n1ql:n1ql-language-reference/dropscope.adoc)\
[n1ql:n1ql-language-reference/dropuser.adoc](n1ql:n1ql-language-reference/dropuser.adoc)\
[n1ql:n1ql-language-reference/dropvectorindex.adoc](n1ql:n1ql-language-reference/dropvectorindex.adoc)

## Data Control Language

Data control language (DCL) statements enable you to control which users or groups have access to data, and what they’re permitted to do with that data.

[n1ql:n1ql-language-reference/grant.adoc](n1ql:n1ql-language-reference/grant.adoc)\
[n1ql:n1ql-language-reference/revoke.adoc](n1ql:n1ql-language-reference/revoke.adoc)

## Data Manipulation Language

Data manipulation language (DML) statements enable you to create, read, update, and delete data.
Some DML statements may be further categorized as data query language, transaction control language, or utility statements.

[n1ql:n1ql-language-reference/delete.adoc](n1ql:n1ql-language-reference/delete.adoc)\
[n1ql:n1ql-language-reference/insert.adoc](n1ql:n1ql-language-reference/insert.adoc)\
[n1ql:n1ql-language-reference/merge.adoc](n1ql:n1ql-language-reference/merge.adoc)\
[n1ql:n1ql-language-reference/update.adoc](n1ql:n1ql-language-reference/update.adoc)\
[n1ql:n1ql-language-reference/upsert.adoc](n1ql:n1ql-language-reference/upsert.adoc)

### Data Query Language

Data query language (DQL) statements enable you to read and filter data and manipulate the results.

[SELECT](n1ql:n1ql-language-reference/selectintro.adoc)

### Transaction Control Language

Transaction control language (TCL) statements enable you to work with Couchbase transactions.

[n1ql:n1ql-language-reference/begin-transaction.adoc](n1ql:n1ql-language-reference/begin-transaction.adoc)\
[n1ql:n1ql-language-reference/commit-transaction.adoc](n1ql:n1ql-language-reference/commit-transaction.adoc)\
[n1ql:n1ql-language-reference/rollback-transaction.adoc](n1ql:n1ql-language-reference/rollback-transaction.adoc)\
[n1ql:n1ql-language-reference/savepoint.adoc](n1ql:n1ql-language-reference/savepoint.adoc)\
[n1ql:n1ql-language-reference/set-transaction.adoc](n1ql:n1ql-language-reference/set-transaction.adoc)

### Utility Statements

Utility statements do not manipulate data directly, but support other operations.
For example, you can create and execute prepared statements, see query plans, get advice on query or index creation, and so on.

[n1ql:n1ql-language-reference/advise.adoc](n1ql:n1ql-language-reference/advise.adoc)\
[n1ql:n1ql-language-reference/execute.adoc](n1ql:n1ql-language-reference/execute.adoc)\
[n1ql:n1ql-language-reference/execfunction.adoc](n1ql:n1ql-language-reference/execfunction.adoc)\
[n1ql:n1ql-language-reference/explain.adoc](n1ql:n1ql-language-reference/explain.adoc)\
[n1ql:n1ql-language-reference/explainfunction.adoc](n1ql:n1ql-language-reference/explainfunction.adoc)\
[n1ql:n1ql-language-reference/infer.adoc](n1ql:n1ql-language-reference/infer.adoc)\
[n1ql:n1ql-language-reference/prepare.adoc](n1ql:n1ql-language-reference/prepare.adoc)\
[n1ql:n1ql-language-reference/updatestatistics.adoc](n1ql:n1ql-language-reference/updatestatistics.adoc)\
[n1ql:n1ql-language-reference/using-ai.adoc](n1ql:n1ql-language-reference/using-ai.adoc)
