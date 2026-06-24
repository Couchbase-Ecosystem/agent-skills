---
# frontmatter
path: '/tutorial-understand-index-scans'
title: Understanding Index Scans
short_title: Index Scans
description:
  - Learn about index scans and how they fit into Couchbase's query execution
  - See several examples of different query predicates, and the resulting span ranges
  - This tutorial provides foundational knowledge for understanding a query's explain plan
content_type: tutorial
filter: n1ql
technology:
  - query
  - index
  - server
tags:
  - SQL++ (N1QL)
  - Optimization
sdk_language:
  - any
length: 10 Mins
---

FILTER, JOIN, and PROJECT are fundamental operations of database query processing. The filtering process takes the initial keyspace and produces an optimal subset of the documents the query is interested in. To produce the smallest possible subset, indexes are used to apply as many predicates as possible.

Query predicate indicates the subset of the data interested. During the query planning phase, we select the indexes to be used. Then, for each index, we decide the predicates to be applied by each index. The query predicates are translated into spans in the query plan and passed to Indexer. Spans simply express the predicates in terms of data ranges. Where each range has a start value, an end value, and specifies whether to include the start or the end value.

- A "High" field in the range indicates the end value. If "High" is missing, then there is no upper bound.
- A "Low" field in the range indicates the start value. If "Low" is missing, the scan starts with `MISSING`.
- Inclusion indicates if the values of the High and Low fields are included.

| Inclusion # | Meaning | Description                              |
| :---------- | :------ | :--------------------------------------- |
| 0           | NEITHER | Neither High nor Low fields are included |
| 1           | LOW     | Only Low fields are included             |
| 2           | HIGH    | Only High fields are included            |
| 3           | BOTH    | Both High and Low fields are included    |

## Example: Equality Predicate

```sql
SELECT meta().id FROM `travel-sample` WHERE id = 10
```

| Span Range for | Low | High | Inclusion |
| :------------- | :-- | :--- | :-------- |
| ID = 10        | 10  | 10   | 3 (BOTH)  |

## Example: Inclusive One-Sided Range Predicate

```sql
SELECT meta().id FROM `travel-sample` WHERE id >= 10
```

| Span Range for | Low | High      | Inclusion |
| :------------- | :-- | :-------- | :-------- |
| ID >= 10       | 10  | Unbounded | 1 (LOW)   |

## Example: Exclusive One-Sided Range Predicate

```sql
SELECT meta().id FROM `travel-sample` WHERE id > 10
```

| Span Range for | Low | High      | Inclusion   |
| :------------- | :-- | :-------- | :---------- |
| ID > 10        | 10  | Unbounded | 0 (NEITHER) |

## Example: AND Predicate

```sql
SELECT meta().id FROM `travel-sample` WHERE id >=10 AND id < 25
```

| Span Range for       | Low | High | Inclusion |
| :------------------- | :-- | :--- | :-------- |
| ID >= 10 AND ID < 25 | 10  | 25   | 1 (LOW)   |

## Example: OR Predicate

```sql
SELECT meta().id FROM `travel-sample` WHERE id = 10 OR id = 20
```

The predicate produces two independent ranges and both of them are pushed to index scan. Duplicate ranges are eliminated, but overlaps are not eliminated.

| Span Range for | Low | High | Inclusion |
| :------------- | :-- | :--- | :-------- |
| ID = 10        | 10  | 10   | 3 (BOTH)  |
| ID = 20        | 20  | 20   | 3 (BOTH)  |

When you analyze the explain plan, correlate the predicates in the explain to the spans. Ensure the most optimal index is selected and the spans have the expected range for all the index keys. More keys in each span will make the query more efficient. Further explanation and many [more detailed examples of index scans](https://docs.couchbase.com/server/current/learn/services-and-indexes/indexes/index-scans.html) can be found in our documentation site.
