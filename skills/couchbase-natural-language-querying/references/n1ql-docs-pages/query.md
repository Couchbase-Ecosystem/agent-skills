# Query Data with {sqlpp}

<style type="text/css">
  /* Extend heading across page width */
  div.page-heading-title{
    flex-basis: 100%;
  }
</style>

The Query Service supports the querying of data by means of the {sqlpp} query language.

As its primary function, the Query Service enables you to issue queries to extract data from Couchbase Server.
You can also issue queries for data definition (defining indexes) and data manipulation (adding or deleting data).
The Query Service needs both the Index Service and the Data Service to be running on Couchbase Server.

You can run queries from the Query Workbench, the cbq shell, the REST API, or the Couchbase SDKs.

## When to Use Queries

Use the Query Service for query analysis and execution to help you build applications.

Use the Analytics Service for online analytical processing (OLAP) -- large datasets with complex analytical or ad hoc queries.

Use the Search Service for Full-Text Search with natural language processing across multiple data types and languages -- custom text analysis, Geospatial search, and more.

## {sqlpp} for Query

To create queries, you must use a query language that’s structured so that the Query Service understands what it needs to retrieve.
Couchbase Server uses a query language called {sqlpp}.
The Couchbase implementation of {sqlpp} was formerly known as [N1QL](https://www.couchbase.com/products/n1ql) (pronounced "nickel").

{sqlpp} is an expressive, powerful, and complete SQL dialect for querying, updating, and manipulating JSON data.
Based on SQL, it’s immediately familiar to developers who can quickly start developing rich applications.

## How-To Guides

* [n1ql:n1ql-intro/index.adoc](n1ql:n1ql-intro/index.adoc)
* [guides:query.adoc](guides:query.adoc)
* [guides:indexes.adoc](guides:indexes.adoc)
* [guides:manipulate.adoc](guides:manipulate.adoc)
* [guides:javascript-udfs.adoc](guides:javascript-udfs.adoc)
* [guides:optimize.adoc](guides:optimize.adoc)

## Query Administration

* [n1ql:n1ql-manage/index.adoc](n1ql:n1ql-manage/index.adoc)

## Query References

* [n1ql:n1ql-language-reference/index.adoc](n1ql:n1ql-language-reference/index.adoc)
* [indexes:indexing-overview.adoc](indexes:indexing-overview.adoc)
* [javascript-udfs:javascript-functions-with-couchbase.adoc](javascript-udfs:javascript-functions-with-couchbase.adoc)

## Related Links

* [Query Service architecture](learn:services-and-indexes/services/query-service.adoc)
* [learn:data/data.adoc](learn:data/data.adoc)
