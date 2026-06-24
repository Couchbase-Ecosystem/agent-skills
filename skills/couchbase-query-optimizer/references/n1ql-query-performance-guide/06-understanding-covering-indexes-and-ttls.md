---
# frontmatter
path: '/tutorial-understanding-covering-indexes-and-ttls'
title: Understanding Covering Indexes and TTLs
short_title: Covering Indexes, TTLs
description: 
  - Learn about special considerations and adjustments to make when querying using a covering index
  - Explore TTL and `meta.expiration()` in Couchbase
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
length: 10 Mins
---

When using covering indexes, there are some important considerations in-terms of how your N1QL queries are constructed to ensure they do NOT return stale data from your indexes(GSIs). To better understand this concept, it's important to have a basic understanding of [document expiration](https://docs.couchbase.com/server/6.6/learn/buckets-memory-and-storage/expiration.html#bucket-expiration-and-xdcr) and how it works.

## Example Use Case

To prove the importance of this concept, let's consider a 3-Legged OAuth grant flow scenario that uses a covering index and also has documents with TTLs set to 10 minutes. After the 10 minute expiry, the document(s) with this TTL will expire and no longer be available for use.

**Example model using a Document Key of:** `temp:code:7zk5ZDczMzRlNDEwYLj`

```json
{
  "scopes": ["account.read", "account.update", "groups.read"],
  "expiry": 1571668070320,
  "userID": "34200980012",
  "docType": "tempCode",
  "email": "user@yourdomain.com",
  "roledID": "1"
}
```

### Example Index

```sql
CREATE INDEX idx_temp_code ON bucket_name(
  email, userid, scopes, expiry, META().expiration
)
WHERE docType = "tempCode"
```

The example query below returns documents after the bucket TTL has expired and yields stale data.

### Example N1QL Query with Unexpected Results

```sql
SELECT meta().expiration, email, scopes, userid
FROM bucket_name
WHERE docType="tempCode" AND email="user@yourdomain.com"
```

### Why does this happen?

When a document's expiration is reached(i.e. TTL expires), it is deleted when one of the following occurs:

- expiry pager runs(default every 60 minutes)
- compaction runs(default 30% fragmentation)
- attempt is made to access the document(this only applies to KV operations)

The issue in the case of covering indexes, is that N1QL does not currently use the underlying capabilities of the Subdoc API when a query is executed, so the metadata associated with the document is not taken into consideration during the phases of query execution. Therefore, we have to ensure the queries encapsulate the appropriate logic and provide the expected results.

The solution is simple and to obtain accurate results, all we need to do is modify our queries to have an additional condition. So, to solve for this situation, we simply add a condition in the WHERE clause to reference the `meta().expiration` and make sure it is greater than the current time(i.e. `NOW_MILLIS()`).

#### Example N1QL Query with Expected Results

```sql
SELECT meta().expiration,email,scopes,userid
FROM bucket_name
WHERE docType="tempCode" AND email="user@yourdomain.com"
  AND TOSTRING(META().expiration) > SPLIT(TOSTRING(NOW_MILLIS() / 1000), ".")[0]
```
