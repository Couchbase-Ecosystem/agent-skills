---
# frontmatter
path: '/tutorial-understanding-cardinality-and-selectivity'
title: Understanding Cardinality and Selectivity
short_title: Cardinality and Selectivity
description: 
  - Learn how understanding cardinality and selectivity can help tune your indexes and speed up your application's performance
  - Read through several examples to cement your understanding
content_type: tutorial
filter: n1ql
technology:
  - query
  - server
tags:
  - SQL++ (N1QL)
  - Optimization
sdk_language:
  - any
length: 15 Mins
---

Cardinality and selectivity play a crucial role in index tuning and optimization as they can provide measurable insights into your data set and effectiveness of the index, pointing you to where specific optimizations can be made.

[Cardinality](https://en.wikipedia.org/wiki/Cardinality_%28SQL_statements%29) refers to the individual uniqueness of values in a specific index key. Each index key (document property) emitted into the index will have varying degrees of cardinality. Cardinality can be broken down into roughly 3 different types:

- _High-Cardinality_: Refers to values that are unique or very uncommon within the index key. Examples include fields such as GUIDs, IDs, email addresses, and usernames.
- _Normal-Cardinality_: Refers to values that are somewhat uncommon but not necessarily unique within the index key. Examples include: **first** / **middle** / **last name**, **zip codes**. There are last names / surnames that very well may be unique in the data set, however, if you were to examine all of the distinct values you'll find groupings of certain values (i.e. Jones).
- _Low-Cardinality_: Refers to values that are common within the data set and have very few possible values. Examples include status, gender, and booleans. Fields that have little uniqueness and are common across the index, examples are status, gender, and booleans.

Selectivity is the measure of variation in unique values in a given data set and it is represented as a number between `0 - 1` or `0 - 100%`. The formula to calculate selectivity can be represented as follows:

```bash
selectivity = cardinality/(number of records) * 100
```

or more simply stated:

```bash
Number of Distinct Values / Total number of Records = Selectivity
```

Cardinality and Selectivity can be applied to any "data set" such as an index, query or bucket. In general for database indexes, the higher cardinality -> better selectivity -> faster scans -> increased performance. Consider the table below:

|             | Name   | Breed              | Gender | Origin Country |
| ----------: | :----- | :----------------- | :----- | :------------- |
|           1 | Oakley | German Shepherd    | M      | Germany        |
|           2 | Zeus   | Doberman Pinscher  | M      | Germany        |
|           3 | Darby  | Doberman Pinscher  | F      | Germany        |
|           4 | Rocky  | Bulldog            | M      | United Kingdom |
|           5 | Lucy   | Labrador Retriever | F      | Canada         |
|           6 | Buddy  | Golden Retriever   | M      | United Kingdom |
|           7 | Molly  | Pug                | F      | China          |
|           8 | Sadie  | Labrador Retriever | F      | Canada         |
|           9 | Max    | Boxer              | M      | Germany        |
|          10 | Simba  | Great Dane         | M      | Germany        |
| Cardinality | 10     | 6                  | 2      | 4              |
| Selectivity | 100%   | 60%                | 20%    | 40%            |

## Examples

Using the `travel-sample` bucket, we'll calculate two selectivity values for some of the sample indexes:

- _Projection Selectivity_: This is a measure of the # of documents in the bucket that match the index filter/`WHERE` predicate and contain the leading field. This is often referred to as "index segmentation".
- _Index Selectivity_: This is a measure of the number of unique values in the index compared to the total # of entries in the index.

> For optimum performance, you will want a relatively low percentage of Projection Selectivity as this means the index is smaller, and a higher value for Index selectivity as this means there is a lot of uniqueness within the index.

Initially, we need to get the total # of documents in the bucket, as we will reuse this value in all of our calculations:

```sql
SELECT RAW COUNT(1)
FROM `travel-sample`
```

```json
[31591]
```

### Example 1: `def_type` index

```sql
CREATE INDEX `def_type` ON `travel-sample`(`type`)
```

Determine the total number of records in the index, this query will push the `COUNT()` down to the indexer, and we trigger the use of the index by referencing the first field in the index. If needed you could optionally specify a `USE INDEX()` statement to ensure the index is used:

```sql
SELECT COUNT(1)
FROM `travel-sample`
WHERE type IS NOT MISSING
```

```json
[31591]
```

Next, we need to determine the total number of possible unique values in the index:

```sql
SELECT RAW COUNT(DISTINCT type)
FROM `travel-sample`
WHERE type IS NOT MISSING
```

```json
[5]
```

| Description            | Formula                | Selectivity |
| :--------------------- | :--------------------- | :---------- |
| Projection Selectivity | (31591 / 31591) \* 100 | 100%        |
| Index Selectivity      | (5 / 31591) \* 100     | 0.015%      |

### Example 2: `def_faa` index

```sql
CREATE INDEX `def_faa` ON `travel-sample`(`faa`)
```

Determine the total number of records in the index:

```sql
SELECT RAW COUNT(1)
FROM `travel-sample`
WHERE faa IS NOT MISSING
```

```json
[1968]
```

Next, we need to determine the total number of possible unique values in the index:

```sql
SELECT RAW COUNT(DISTINCT faa)
FROM `travel-sample`
WHERE faa IS NOT MISSING
```

```json
[1708]
```

| Description            | Formula               | Selectivity |
| :--------------------- | :-------------------- | :---------- |
| Projection Selectivity | (1968 / 31591) \* 100 | 6.23%       |
| Index Selectivity      | (1708 / 1968) \* 100  | 86.79%      |

### Example 3: `def_country` index

```sql
CREATE INDEX `def_country` ON `travel-sample`(`country`, `type`)
```

Determine the total number of records in the index:

```sql
SELECT RAW COUNT(1)
FROM `travel-sample`
WHERE country IS NOT MISSING
```

```json
[7567]
```

Next, we need to determine the total number of possible unique values in the index. For this example, however, there are two index keys `country` and `type`. The selectivity depends on how the index will be used and when optimizing it is important to understand how the cardinality of one key can affect the other.

#### Example 3.a

```sql
SELECT *
FROM `travel-sample`
WHERE country = 'United States'
```

```sql
SELECT RAW COUNT(DISTINCT country)
FROM `travel-sample`
WHERE country IS NOT MISSING
```

```json
[3]
```

#### Example 3.b

```sql
SELECT *
FROM `travel-sample`
WHERE country = 'United States' AND type = 'landmark'
```

When both keys are used, the selectivity can be described in two ways, the first is the total uniqueness of both keys when combined together:

```sql
SELECT RAW COUNT(DISTINCT country || type)
FROM `travel-sample`
WHERE country IS NOT MISSING
```

```json
[12]
```

#### Example 3.c

The second is # of unique keys for the second index key which matches the previous index key:

```sql
SELECT RAW COUNT(1)
FROM `travel-sample`
WHERE country = 'United States'
```

```json
[3948]
```

```sql
SELECT RAW COUNT(DISTINCT type)
FROM `travel-sample`
WHERE country = 'United States'
```

```json
[4]
```

| Description             | Formula               | Selectivity |
| :---------------------- | :-------------------- | :---------- |
| Projection Selectivity  | (7567 / 31591) \* 100 | 23.95%      |
| Index Selectivity (3.a) | (3 / 7567) \* 100     | 0.039%      |
| Index Selectivity (3.b) | (12 / 7567) \* 100    | 0.16%       |
| Index Selectivity (3.c) | (4 / 3948) \* 100     | 0.10%       |

## Summary

Both cardinality and selectivity can affect the performance of IndexScans, and you should always consider their implications as it relates to your access patterns and query predicates. Having a solid understanding of cardinality and selectivity as it relates to your data set can provide solid guidance in the tuning and determining the order of index keys within the index.
