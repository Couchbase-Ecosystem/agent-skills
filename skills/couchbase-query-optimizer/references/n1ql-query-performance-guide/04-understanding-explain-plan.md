---
# frontmatter
path: '/tutorial-understanding-explain-plan'
title: Understanding an Explain Plan
short_title: Explain Plan
description: 
  - Learn about the query explain plan and how to understand it
  - View all the various attributes available in the explain plan and learn how to interpret them
  - See a list of common things to look for when examining the explain plan
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

Plans are built from algebras using a visitor pattern. A separate planner/optimizer is used for index selection. You can view the explain plan by prefacing a query with the `EXPLAIN` keyword, clicking the "Explain" button in query workbench or by executing a query and viewing the "Plan Text". The table below describes the various attributes you see in the explain plan and how to interpret them. Reference the [Operators guides](/tutorial-operators-guide?learningPath=learn/n1ql-query-performance-guide) for a complete list of all operators.

## Attributes

| Attribute      | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| :------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| phaseTimes     | Cumulative execution times for various phases involved in the query execution, such as authorize, indexscan, fetch, parse, plan, run etc.                                                                                                                                                                                                                                                                                                                                                             |
| phaseCounts    | Count of documents processed at selective phases involved in the query execution, such as authorise, indexscan, fetch, parse, plan, run etc.                                                                                                                                                                                                                                                                                                                                                          |
| phaseOperators | Indicates the number of each kind of query operators involved in different phases of the query processing. For instance, this example, one non-covering index path was taken, which involves 1 indexScan and 1 fetch operators. <br><br>A join would have probably involved 2 fetches (1 per keyspace) <br><br>A union select would have twice as many operator counts (1 per each branch of the union). <br><br>This is, in essence, the count of all the operators in the `executionTimings` field. |
| #operator      | Name of the operator.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| #stats         | These values will be dynamic, depending on the documents processed by various phases up to this moment in time.                                                                                                                                                                                                                                                                                                                                                                                       |
| #itemsIn       | Number of input documents to the operator.                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| #itemsOut      | Number of output documents after the operator processing.                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| #phaseSwitches | Number of switches between executing, waiting for services, or waiting for the goroutine scheduler. <br><ul><li>execTime - Time spent executing the operator code inside N1QL query engine.</li><li>kernTime - Time spent waiting to be scheduled for CPU time.</li><li>servTime - Time spent waiting for another service, such as index or data.<ul><li>For index scan, it is time spent waiting for GSI/indexer</li><li>For fetch, it is time spent waiting on the KV store</li></ul>                |

These statistics (`kernTime`, `servTime`, and `execTime`) can be very helpful in troubleshooting query performance issues, for example as:

- A high `servTime` for a low number of items processed is an indication that the indexer or KV store is stressed.
- A high `kernTime` means there is a downstream issue in the query plan or the query server having many requests to process (so the scheduled waiting time will be more for CPU time).

When tuning (or writing) a N1QL statement the goal is to drive from the query that has the most selective filter. This means that there are fewer documents/keys are passed to the next step. If the next step is a join, then this means that fewer documents are joined. Check to see whether the access paths are optimal.

When examining the optimizer execution plan, look for the following:

- The driving query/subquery has the best filter.
- The join order in each step returns the fewest number of rows to the next step (that is, the join order should reflect, where possible, going to the best not-yet-used filters).
- Consider the predicates in the N1QL statement and the number of documents being returned.
- Ensure that the right indexes are being used. Telltale signs of poor performance are that the index you wouldn't expect is being used e.g. Primary Index or if the index can be covering is not being used. In general, a smaller more restrictive index will more performant than a primary index.
- Determine why an index is not used for selective predicates
- Ensure that the SPANS are correctly being leveraged for an index. Even if the index is being used by the optimizer if you are not able to push out appropriate SPANS to the optimizer the query performance will suffer
