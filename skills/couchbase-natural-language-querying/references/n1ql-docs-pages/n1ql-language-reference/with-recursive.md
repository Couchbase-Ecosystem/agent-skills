# WITH RECURSIVE Clause

Use the WITH RECURSIVE clause to enable recursive referencing in common table expressions.

## Purpose

The common table expressions (CTEs) created by the WITH clause simplify complex queries and create temporary result sets which can be used as data sources or as expressions for queries.

The WITH RECURSIVE clause is an extension of the WITH clause which enables you to create recursive queries.
You can use recursive queries with hierarchical data, or data in a tree structure.
In these cases, the data may have an arbitrary number of levels, and you won’t know in advance how deeply you need to traverse the data.

The CTE for a recursive query includes a UNION or UNION ALL [set operator](n1ql:n1ql-language-reference/union.adoc).

* The left arm of UNION/UNION ALL contains an anchor clause, which is non-recursive.
The anchor clause produces an initial set of documents as an intermediate result set for the CTE keyspace.
* The right arm of UNION/UNION ALL contains the recursive clause.
The recursive clause produces a new set of documents.

The recursive clause is executed again, with the CTE keyspace now referring to the result produced by the initial recursive clause.
This process repeats until it results in an empty intermediate result set.
The intermediate result sets are appended to produce a final output.

## Syntax

```ebnf
with-recursive-clause ::= 'WITH' 'RECURSIVE' alias 'AS' '(' ( recursive-select | select | expr ) ')' cycle-clause? options-clause?
                                       ( ',' alias 'AS' '(' ( recursive-select | select | expr ) ')' cycle-clause? options-clause? )*
```

![Syntax diagram](../../assets/images/n1ql-language-reference/with-recursive-clause.png)

### Recursive SELECT

```ebnf
recursive-select ::= anchor-select ('UNION' | 'UNION ALL') recursive-select-term
```

![Syntax diagram](../../assets/images/n1ql-language-reference/recursive-select.png)

The definition for a recursive CTE must be a SELECT statement that includes a UNION or UNION ALL set operator.
If it isn’t, the CTE is treated as a non-recursive CTE.

* **anchor-select**\
A [SELECT query](n1ql:n1ql-language-reference/select-syntax.adoc) that represents the anchor clause of the CTE.
* **recursive-select-term**\
A [select term](n1ql:n1ql-language-reference/select-syntax.adoc#select-term) that represents the recursive clause of the CTE.

### CYCLE Clause

```ebnf
cycle-clause ::= 'CYCLE' expr ( ',' expr )* 'RESTRICT'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/cycle-clause.png)

The optional CYCLE clause provides one method for avoiding infinite recursions.
It enables you to specify one or more fields whose values are likely to repeat.

* **expr**\
(Required) An [identifier](n1ql:n1ql-language-reference/identifiers.adoc) or a [path](n1ql:n1ql-language-reference/select-syntax.adoc#path) representing a field/nested-field.

The CYCLE clause returns the following error if you enter an invalid expression:

```json
{
  "errors": [
    {
      "code": 3307,
      "msg": "Cycle fields validation failed for with term: cyc - cause: invalid cycle field expression term: (1 + 1) only identifier/path expressions are allowed"
    }
  ]
}
```

### OPTIONS Clause
```ebnf
options-clause ::= 'OPTIONS' expr
```

![Syntax diagram](../../assets/images/n1ql-language-reference/options-clause.png)

The optional OPTIONS clause provides another method for avoiding infinite recursions.
It enables you to specify that the recursion should exit after a specified level, or after accumulating a specified number of documents.

* **expr**\
(Required) An object with the following properties.

| Name | Description | Schema |
| --- | --- | --- |
| ***levels***<br> __optional__ | Recursion should exit after reaching this level. This assumes the anchor is at level 0. | Integer |
| ***documents***<br> __optional__ | Recursion should exit after accumulating this many documents. | Integer |

## Limitations

* The recursive reference is only allowed once in the FROM clause.
It’s not allowed anywhere else.
* ORDER BY, LIMIT, and OFFSET clauses are not allowed in the SELECT statement in the subquery used to define the anchor and the recursive clause.
* The DISTINCT quantifier is not allowed in anchor and recursive clauses.
* GROUP BY, WINDOW, and AGGREGATE functions are not allowed in recursive clauses.
* OUTER JOINS are not allowed in recursive clauses because they can lead to potential infinite recursion.
* Recursive clauses do not support NEST and UNNEST clauses.
* If there is no UNION/UNION ALL separation for the recursive CTE, the query defaults to a normal CTE.
* A syntax error is returned when optional subclauses are used without the RECURSIVE keyword.
* In general, recursion is also limited by:
  * The logic in the recursive statement.
  * The stop in the options argument.
  * Breaching the request timeout, if configured.
  * Breaching the request memory quota, if configured.
  * Exceeding the implicit document limit (10000) when a memory quota is not in use and when no explicit document limit is set in the options.
  * Exceeding the implicit level limit (1000) when the level option is not in use and when no explicit document limit is set in the options.

## Examples

The following examples follow linear recursion.
Only one recursive reference is allowed in the FROM clause.
Self-joins or set-ops are not allowed in the recursive reference.

**Simple recursive referencing**

```sqlpp
WITH RECURSIVE cte AS (
    SELECT 1 AS r
        UNION
    SELECT cte.r+1 AS r
    FROM cte
    WHERE cte.r<4
)
SELECT cte.r FROM cte;
```

**Results**

```json
[
  {
    "r": 1
  },
  {
    "r": 2
  },
  {
    "r": 3
  },
  {
    "r": 4
  }
]
```

**Combine recursive and non-recursive CTEs with the WITH clause**

```sqlpp
WITH RECURSIVE cte AS (SELECT 1 r) ,
    rcte AS (
        SELECT cte.r FROM cte
            UNION
        SELECT rcte.r+2 r FROM rcte WHERE rcte.r<7
    )
SELECT * FROM rcte;
```

**Results**

```json
[
  {
    "rcte": {
      "r": 1
    }
  },
  {
    "rcte": {
      "r": 3
    }
  },
  {
    "rcte": {
      "r": 5
    }
  },
  {
    "rcte": {
      "r": 7
    }
  }
]
```

**Handle hierarchical or tree-structured data**

For this example, set the query context to the `tenant_agent_00` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Create a dataset containing employee information**

```sqlpp
CREATE COLLECTION employees IF NOT EXISTS;

INSERT INTO employees
   VALUES ("e1", {
       "employee_id": 1,
       "employee_name": "Carlos"
       }),
   VALUES ("e2", {
       "employee_id": 2,
       "employee_name": "Maya",
       "manager_id": 1
       }),
   VALUES ("e3", {
       "employee_id": 3,
       "employee_name": "Fatima",
       "manager_id": 1
       }),
   VALUES ("e4", {
       "employee_id": 4,
       "employee_name": "Yijing",
       "manager_id": 2
       }),
   VALUES ("e5", {
       "employee_id": 5,
       "employee_name": "Rahul",
       "manager_id": 3
       }),
   VALUES ("e6", {
       "employee_id": 6,
       "employee_name": "Lisa",
       "manager_id": 2
       })
RETURNING *;
```

**Create an index for the employees**

```sqlpp
CREATE INDEX e_idx ON employees(manager_id INCLUDE MISSING, employee_id, employee_name);
```

**Find the level of each employee in the organization**

```sqlpp
WITH RECURSIVE emplLevel AS (
   SELECT e.employee_id, e.employee_name, 0 lvl
   FROM employees e
   WHERE manager_id IS MISSING
       UNION
   SELECT e1.employee_id, e1.employee_name, e1.manager_id, emplLevel.lvl+1
   lvl
   FROM employees e1 JOIN emplLevel
   ON e1.manager_id = emplLevel.employee_id
)
SELECT * FROM emplLevel;
```

**Results**

```json
[
  {
    "emplLevel": {
      "employee_id": 1,
      "employee_name": "Carlos",
      "lvl": 0
    }
  },
  {
    "emplLevel": {
      "employee_id": 2,
      "employee_name": "Maya",
      "lvl": 1,
      "manager_id": 1
    }
  },
  {
    "emplLevel": {
      "employee_id": 3,
      "employee_name": "Fatima",
      "lvl": 1,
      "manager_id": 1
    }
  },
  {
    "emplLevel": {
      "employee_id": 4,
      "employee_name": "Yijing",
      "lvl": 2,
      "manager_id": 2
    }
  },
  {
    "emplLevel": {
      "employee_id": 6,
      "employee_name": "Lisa",
      "lvl": 2,
      "manager_id": 2
    }
  },
  {
    "emplLevel": {
      "employee_id": 5,
      "employee_name": "Rahul",
      "lvl": 2,
      "manager_id": 3
    }
  }
]
```

**Find the reporting hierarchy of the employees in the organization**

```sqlpp
SELECT e.employee_id, e.employee_name, e.manager_id,
(
    WITH RECURSIVE cte AS (
        SELECT e1.employee_id, e1.employee_name, e1.manager_id
        FROM employees e1 WHERE e1.manager_id = e.employee_id
            UNION
        SELECT e2.employee_id, e2.employee_name, e2.manager_id
        FROM employees e2, cte
        WHERE e2.manager_id = cte.employee_id
    )
    SELECT cte.* FROM cte
) as reports
FROM employees e;
```

**Results**

```json
[
  {
    "employee_id": 1,
    "employee_name": "Carlos",
    "reports": [
      {
        "employee_id": 2,
        "employee_name": "Maya",
        "manager_id": 1
      },
      {
        "employee_id": 3,
        "employee_name": "Fatima",
        "manager_id": 1
      },
      {
        "employee_id": 4,
        "employee_name": "Yijing",
        "manager_id": 2
      },
      {
        "employee_id": 6,
        "employee_name": "Lisa",
        "manager_id": 2
      },
      {
        "employee_id": 5,
        "employee_name": "Rahul",
        "manager_id": 3
      }
    ]
  },
  {
    "employee_id": 2,
    "employee_name": "Maya",
    "manager_id": 1,
    "reports": [
      {
        "employee_id": 4,
        "employee_name": "Yijing",
        "manager_id": 2
      },
      {
        "employee_id": 6,
        "employee_name": "Lisa",
        "manager_id": 2
      }
    ]
  },
  {
    "employee_id": 3,
    "employee_name": "Fatima",
    "manager_id": 1,
    "reports": [
      {
        "employee_id": 5,
        "employee_name": "Rahul",
        "manager_id": 3
      }
    ]
  },
  {
    "employee_id": 4,
    "employee_name": "Yijing",
    "manager_id": 2,
    "reports": []
  },
  {
    "employee_id": 6,
    "employee_name": "Lisa",
    "manager_id": 2,
    "reports": []
  },
  {
    "employee_id": 5,
    "employee_name": "Rahul",
    "manager_id": 3,
    "reports": []
  }
]
```

**Use the OPTIONS clause and the CYCLE clause to avoid infinite recursion**

For this example, set the query context to the `tenant_agent_00` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Create a dataset containing product information**

```sqlpp
CREATE COLLECTION products IF NOT EXISTS;

INSERT INTO products
  VALUES (uuid(), {
    "id": 1,
    "name": "Bicycle",
    "price": 299.99,
    "description": "A sturdy and reliable bicycle.",
    "category": "Sports",
    "related_items": [2, 4]
  }),
  VALUES (uuid(), {
    "id": 2,
    "name": "Helmet",
    "price": 49.99,
    "description": "A safety helmet for cycling.",
    "category": "Sports",
    "related_items": [1, 3]
  }),
  VALUES (uuid(), {
    "id": 3,
    "name": "Water Bottle",
    "price": 9.99,
    "description": "A convenient water bottle for cycling.",
    "category": "Accessories",
    "related_items": [2, 4]
  }),
  VALUES (uuid(), {
    "id": 4,
    "name": "Gloves",
    "price": 19.99,
    "description": "Comfortable gloves for cycling.",
    "category": "Sports",
    "related_items": [1, 3]
  })
RETURNING *;
```

**Create an index for the products**

```sqlpp
CREATE PRIMARY INDEX ON `default`:`travel-sample`.`tenant_agent_00`.`products`
```

**Query resulting in infinite recursion**

```sqlpp
WITH RECURSIVE similar_items AS (
  SELECT p.*, 0 as lvl FROM products p WHERE p.id=1
    UNION
  SELECT p1.*, similar_items.lvl+1 as lvl FROM products p1,
    similar_items WHERE p1.id IN similar_items.related_items
)
SELECT * FROM similar_items;
```

**Results**

```json
[
  {
    "code": 5500,
    "msg": "Request has exceeded memory quota"
  }
]
```

**Solution using the OPTIONS clause to add a level limit**

```sqlpp
WITH RECURSIVE similar_items AS (
  SELECT p.*, 0 as lvl FROM products p WHERE p.id=1
    UNION
  SELECT p1.*, similar_items.lvl+1 as lvl FROM products p1,
    similar_items WHERE p1.id IN similar_items.related_items
)
OPTIONS {"levels":2}
SELECT * FROM similar_items;
```

**Results**

```json
[
  {
    "similar_items": {
      "category": "Sports",
      "description": "A sturdy and reliable bicycle.",
      "id": 1,
      "lvl": 0,
      "name": "Bicycle",
      "price": 299.99,
      "related_items": [
        2,
        4
      ]
    }
  },
  {
    "similar_items": {
      "category": "Sports",
      "description": "A safety helmet for cycling.",
      "id": 2,
      "lvl": 1,
      "name": "Helmet",
      "price": 49.99,
      "related_items": [
        1,
        3
      ]
    }
  },
  {
    "similar_items": {
      "category": "Sports",
      "description": "Comfortable gloves for cycling.",
      "id": 4,
      "lvl": 1,
      "name": "Gloves",
      "price": 19.99,
      "related_items": [
        1,
        3
      ]
    }
  },
  {
    "similar_items": {
      "category": "Sports",
      "description": "A sturdy and reliable bicycle.",
      "id": 1,
      "lvl": 2,
      "name": "Bicycle",
      "price": 299.99,
      "related_items": [
        2,
        4
      ]
    }
  },
  {
    "similar_items": {
      "category": "Accessories",
      "description": "A convenient water bottle for cycling.",
      "id": 3,
      "lvl": 2,
      "name": "Water Bottle",
      "price": 9.99,
      "related_items": [
        2,
        4
      ]
    }
  }
]
```

**Solution using the CYCLE clause to track which fields are likely to repeat and cause a cycle**

```sqlpp
WITH RECURSIVE similar_items AS (
  SELECT p.*, 0 as lvl FROM products p WHERE p.id=1
    UNION
  SELECT p1.*, similar_items.lvl+1 as lvl FROM products p1,
    similar_items WHERE p1.id IN similar_items.related_items
)
CYCLE id RESTRICT
SELECT * FROM similar_items;
```

**Results**

```json
[
  {
    "similar_items": {
      "category": "Sports",
      "description": "A sturdy and reliable bicycle.",
      "id": 1,
      "lvl": 0,
      "name": "Bicycle",
      "price": 299.99,
      "related_items": [
        2,
        4
      ]
    }
  },
  {
    "similar_items": {
      "category": "Sports",
      "description": "A safety helmet for cycling.",
      "id": 2,
      "lvl": 1,
      "name": "Helmet",
      "price": 49.99,
      "related_items": [
        1,
        3
      ]
    }
  },
  {
    "similar_items": {
      "category": "Sports",
      "description": "Comfortable gloves for cycling.",
      "id": 4,
      "lvl": 1,
      "name": "Gloves",
      "price": 19.99,
      "related_items": [
        1,
        3
      ]
    }
  },
  {
    "similar_items": {
      "category": "Accessories",
      "description": "A convenient water bottle for cycling.",
      "id": 3,
      "lvl": 2,
      "name": "Water Bottle",
      "price": 9.99,
      "related_items": [
        2,
        4
      ]
    }
  }
]
```
