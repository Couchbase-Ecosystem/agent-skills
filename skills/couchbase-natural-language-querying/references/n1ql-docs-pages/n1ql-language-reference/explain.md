# EXPLAIN

<style type="text/css">

/* details like other paragraph divs */
  .doc details {
    margin-top: 1rem;
  }
  .doc .paragraph + .details {
    margin-top: 1.5rem;
  }

/* summary like other titles */
  .doc details > summary.title {
    font-size: 1rem;
    font-weight: 600;
    line-height: 1.2;
    margin-bottom: 1rem;
    color: #52566c;
  }

</style>

The EXPLAIN statement when used before any {sqlpp} statement, provides information about the execution plan for the statement.

## Prerequisites

To execute the EXPLAIN statement, you must have the privileges required for the {sqlpp} statement that is being explained.
For more details about user roles, see
[Authorization](learn:security/authorization-overview.adoc).

<details>
<summary>RBAC Examples</summary>

======
For this example, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

To execute the following statement, you must have the _Query Insert_ privilege on the `landmark` keyspace and the _Query Select_ privilege on the `pass:c[`beer-sample`]` keyspace.

```sqlpp
EXPLAIN INSERT INTO landmark (KEY foo, VALUE bar)
        SELECT META(doc).id AS foo, doc AS bar
        FROM `beer-sample` AS doc WHERE type = "brewery";
```

To execute the following statement, you must have the _Query Insert_, _Query Update_, and _Query Select_ privileges on the `testbucket` keyspace.

```sqlpp
EXPLAIN UPSERT INTO testbucket VALUES ("key1", { "a" : "b" }) RETURNING meta().cas;
```
======
</details>

## Syntax

```ebnf
explain ::= 'EXPLAIN' statement
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/explain.png)

The statement consists of the `EXPLAIN` keyword, followed by the query whose execution plan you want to see.

## Example

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

```sqlpp
EXPLAIN SELECT title, activity, hours
FROM landmark
ORDER BY title;
```

**Results**

```json
[
  {
    "plan": {
      "#operator": "Sequence",
      "~children": [
        {
          "#operator": "Sequence",
          "~children": [
            {
              "#operator": "PrimaryScan3",
              "bucket": "travel-sample",
              "index": "def_inventory_landmark_primary",
              "index_projection": {
                "primary_key": true
              },
              "keyspace": "landmark",
              "namespace": "default",
              "scope": "inventory",
              "using": "gsi"
            },
            {
              "#operator": "Fetch",
              "bucket": "travel-sample",
              "keyspace": "landmark",
              "namespace": "default",
              "scope": "inventory"
            },
            {
              "#operator": "Parallel",
              "~child": {
                "#operator": "Sequence",
                "~children": [
                  {
                    "#operator": "InitialProject",
                    "result_terms": [
                      {
                        "expr": "(`landmark`.`title`)"
                      },
                      {
                        "expr": "(`landmark`.`activity`)"
                      },
                      {
                        "expr": "(`landmark`.`hours`)"
                      }
                    ]
                  }
                ]
              }
            }
          ]
        },
        {
          "#operator": "Order",
          "sort_terms": [
            {
              "expr": "(`landmark`.`title`)"
            }
          ]
        }
      ]
    },
    "text": "SELECT title, activity, hours FROM landmark ORDER BY title;"
  }
]
```
