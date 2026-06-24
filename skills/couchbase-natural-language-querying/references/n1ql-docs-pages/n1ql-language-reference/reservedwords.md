# Reserved Words

{sqlpp} defines an extensive list of keywords that are reserved words. \
All of the {sqlpp} keywords are case-insensitive.

Some keywords are not currently implemented but are reserved for future use.

## Using Reserved Words as Identifiers

{sqlpp} allows escaped identifiers to overlap with keywords.
To use a reserved word as an identifier, you must escape it by enclosing the reserved word inside backticks ({backtick}{backtick}).
For example, if your JSON document contains a field named `index`, you can use it in your queries by escaping it like this:

```json
{
    "age": "42",
    "index": 27,
    "name": "Elvis"
}
```

```sqlpp
CREATE INDEX myindex ON default(`index`) USING GSI;
```

## {sqlpp} Reserved Words

The following keywords are reserved and cannot be used as unescaped identifiers.

**📌 NOTE**\
The word `AI` is not a reserved word, even though you can use it in combination with the `USING` keyword as part of the [USING AI](n1ql-language-reference/using-ai.adoc) statement.
You do not have to escape the word `AI` inside backticks when using it by itself as an identifier.

<style>

.openblock.columns .content .paragraph {
  column-count: 3;
  column-width: auto;
}

</style>

### Symbols
_INDEX_CONDITION\
_INDEX_KEY

### A
[ADVISE](n1ql-language-reference/advise.adoc)\
[ALL](n1ql-language-reference/selectclause.adoc#all)\
ALTER\
ANALYZE\
[AND](n1ql-language-reference/logicalops.adoc#logical-op-and)\
[ANY](n1ql-language-reference/collectionops.adoc#collection-op-any)\
[ARRAY](n1ql-language-reference/collectionops.adoc#array)\
[AS](n1ql-language-reference/from.adoc#section_ax5_2nx_1db)\
ASC\
AT

### B
BEGIN\
[BETWEEN](n1ql-language-reference/comparisonops.adoc#between)\
[BINARY](n1ql-language-reference/datatypes.adoc#datatype-binary)\
[BOOLEAN](n1ql-language-reference/datatypes.adoc#datatype-boolean)\
BREAK\
BUCKET\
BUILD\
BY

### C
CACHE\
CALL\
[CASE](n1ql-language-reference/conditionalops.adoc)\
CAST\
CLUSTER\
COLLATE\
COLLECTION\
COMMIT\
[COMMITTED](n1ql:n1ql-language-reference/set-transaction.adoc)\
CONNECT\
CONTINUE\
CORRELATED\
COVER\
[CREATE](n1ql-language-reference/createindex.adoc)\
[CURRENT](n1ql-language-reference/window.adoc#window-frame-extent)\
CYCLE

### D
DATABASE\
DATASET\
DATASTORE\
DECLARE\
DECREMENT\
DEFAULT\
[DELETE](n1ql-language-reference/delete.adoc)\
DERIVED\
DESC\
DESCRIBE\
[DISTINCT](n1ql-language-reference/selectclause.adoc#distinct)\
DO\
[DROP](n1ql-language-reference/dropindex.adoc)

### E
EACH\
ELEMENT\
ELSE\
END\
ESCAPE\
[EVERY](n1ql-language-reference/collectionops.adoc#collection-op-every)\
[EXCEPT](n1ql-language-reference/union.adoc)\
[EXCLUDE](n1ql-language-reference/selectclause.adoc#sec_ExcludeClause)\
[EXECUTE](n1ql-language-reference/execute.adoc)\
[EXISTS](n1ql-language-reference/collectionops.adoc#exists)\
[EXPLAIN](n1ql-language-reference/explain.adoc)

### F
FALSE\
FETCH\
FILTER\
[FIRST](n1ql-language-reference/collectionops.adoc#first)\
FLATTEN\
FLATTEN_KEYS\
FLUSH\
[FOLLOWING](n1ql-language-reference/window.adoc#window-frame-extent)\
FOR\
FORCE\
[FROM](n1ql-language-reference/from.adoc)\
[FTS](n1ql-language-reference/hints.adoc#index-type)\
[FUNCTION](n1ql-language-reference/createfunction.adoc)

### G
GOLANG\
[GRANT](n1ql-language-reference/grant.adoc)\
[GROUP](n1ql-language-reference/groupby.adoc)\
[GROUPS](n1ql-language-reference/window.adoc#window-frame-clause)\
[GSI](n1ql-language-reference/hints.adoc#index-type)

### H
[HASH](n1ql-language-reference/join.adoc#use-hash-hint)\
HAVING

### I
IF\
IGNORE\
ILIKE\
[IN](n1ql-language-reference/collectionops.adoc#collection-op-in)\
INCLUDE\
INCREMENT\
INDEX\
[INFER](n1ql-language-reference/infer.adoc)\
INLINE\
INNER\
[INSERT](n1ql-language-reference/insert.adoc)\
[INTERSECT](n1ql-language-reference/union.adoc)\
INTO\
[IS](n1ql-language-reference/comparisonops.adoc#is)\
[ISOLATION](n1ql:n1ql-language-reference/set-transaction.adoc)

### J
[JAVASCRIPT](n1ql-language-reference/createfunction.adoc)\
[JOIN](n1ql-language-reference/join.adoc)

### K
KEY\
KEYS\
KEYSPACE\
KNOWN

### L
[LANGUAGE](n1ql-language-reference/createfunction.adoc)\
LAST\
LATERAL\
LEFT\
[LET](n1ql-language-reference/let.adoc)\
LETTING\
[LEVEL](n1ql:n1ql-language-reference/set-transaction.adoc)\
[LIKE](n1ql-language-reference/comparisonops.adoc#like)\
[LIMIT](n1ql-language-reference/limit.adoc)\
LSM

### M
MAP\
MAPPING\
MATCHED\
MATERIALIZED\
MAXVALUE\
[MERGE](n1ql-language-reference/merge.adoc)\
MINUS\
MINVALUE\
[MISSING](n1ql-language-reference/comparisonops.adoc#null-and-missing)

### N
NAMESPACE\
NAMESPACE_ID\
[NEST](n1ql-language-reference/nest.adoc)\
NEXT\
NEXTVAL\
[NL](n1ql-language-reference/join.adoc#use-nl-hint)\
[NO](n1ql-language-reference/window.adoc#window-frame-exclusion)\
[NOT](n1ql-language-reference/logicalops.adoc#logical-op-not)\
NOT_A_TOKEN\
[NTH_VALUE](n1ql-language-reference/windowfun.adoc#fn-window-nth-value)\
[NULL](n1ql-language-reference/comparisonops.adoc#null-and-missing)\
[NULLS](n1ql-language-reference/window.adoc#nulls-treatment)\
NUMBER

### O
OBJECT\
[OFFSET](n1ql-language-reference/offset.adoc)\
ON\
OPTION\
[OPTIONS](n1ql-language-reference/insert.adoc#insert-values)\
[OR](n1ql-language-reference/logicalops.adoc#or-operator)\
[ORDER](n1ql-language-reference/orderby.adoc)\
[OTHERS](n1ql-language-reference/window.adoc#window-frame-exclusion)\
OUTER\
[OVER](n1ql-language-reference/window.adoc)

### P
PARSE\
PARTITION\
PASSWORD\
PATH\
POOL\
[PRECEDING](n1ql-language-reference/window.adoc#window-frame-extent)\
[PREPARE](n1ql-language-reference/prepare.adoc)\
PREV\
PREVIOUS\
PREVVAL\
PRIMARY\
PRIVATE\
PRIVILEGE\
[PROBE](n1ql-language-reference/join.adoc#use-hash-hint)\
PROCEDURE\
PUBLIC

### R
[RANGE](n1ql-language-reference/window.adoc#window-frame-clause)\
RAW\
READ\
REALM\
RECURSIVE\
REDUCE\
RENAME\
REPLACE\
[RESPECT](n1ql-language-reference/window.adoc#nulls-treatment)\
RESTART\
RESTRICT\
RETURN\
RETURNING\
[REVOKE](n1ql-language-reference/revoke.adoc)\
RIGHT\
ROLE\
ROLES\
[ROLLBACK](n1ql:n1ql-language-reference/rollback-transaction.adoc)\
[ROW](n1ql-language-reference/window.adoc#window-frame-extent)\
[ROWS](n1ql-language-reference/window.adoc#window-frame-clause)

### S
SATISFIES\
[SAVEPOINT](n1ql:n1ql-language-reference/savepoint.adoc)\
SCHEMA\
SCOPE\
[SELECT](n1ql-language-reference/selectclause.adoc)\
SELF\
SEQUENCE\
SEMI\
SET\
SHOW\
SOME\
START\
STATISTICS\
STRING\
SYSTEM

### T
THEN\
[TIES](n1ql-language-reference/window.adoc#window-frame-exclusion)\
TO\
[TRAN](n1ql:n1ql-language-reference/begin-transaction.adoc)\
[TRANSACTION](n1ql:n1ql-language-reference/begin-transaction.adoc)\
TRIGGER\
TRUE\
TRUNCATE

### U
[UNBOUNDED](n1ql-language-reference/window.adoc#window-frame-extent)\
UNDER\
[UNION](n1ql-language-reference/union.adoc)\
UNIQUE\
UNKNOWN\
[UNNEST](n1ql-language-reference/unnest.adoc)\
[UNSET](n1ql-language-reference/update.adoc#unset-clause)\
[UPDATE](n1ql-language-reference/update.adoc)\
[UPSERT](n1ql-language-reference/upsert.adoc)\
[USE](n1ql-language-reference/hints.adoc)\
USER\
USERS\
USING

### V
VALIDATE\
VALUE\
VALUED\
VALUES\
VECTOR\
VIA\
VIEW

### W
WHEN\
[WHERE](n1ql-language-reference/where.adoc)\
WHILE\
[WINDOW](n1ql-language-reference/window.adoc)\
[WITH](n1ql-language-reference/with.adoc)\
[WITHIN](n1ql-language-reference/collectionops.adoc#collection-op-within)\
[WORK](n1ql:n1ql-language-reference/begin-transaction.adoc)

### X
XOR
