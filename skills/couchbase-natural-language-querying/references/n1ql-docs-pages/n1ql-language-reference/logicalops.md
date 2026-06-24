# Logical Operators

Logical terms let you combine other expressions using [Boolean logic](n1ql-language-reference/booleanlogic.adoc).
{sqlpp} provides the following logical operators:

* AND
* OR
* NOT

In {sqlpp}, logical operators have their usual meaning; however, Boolean propositions can evaluate to NULL or MISSING as well as to TRUE and FALSE.
The truth tables for these operators therefore use four-valued logic.

## AND

```ebnf
and ::= cond 'AND' cond
```

![Syntax diagram](../../assets/images/n1ql-language-reference/and.png)

AND evaluates to TRUE only if both conditions are TRUE.

**AND Truth Table**

|  | TRUE | FALSE | NULL | MISSING |
| --- | --- | --- | --- | --- |
| TRUE | TRUE | FALSE | NULL | MISSING |
| FALSE | FALSE | FALSE | FALSE | FALSE |
| NULL | NULL | FALSE | NULL | MISSING |
| MISSING | MISSING | FALSE | MISSING | MISSING |

## OR

```ebnf
or ::= cond 'OR' cond
```

![Syntax diagram](../../assets/images/n1ql-language-reference/or.png)

OR evaluates to TRUE if one of the conditions is TRUE.

**OR Truth Table**

|  | TRUE | FALSE | NULL | MISSING |
| --- | --- | --- | --- | --- |
| TRUE | TRUE | TRUE | TRUE | TRUE |
| FALSE | TRUE | FALSE | NULL | MISSING |
| NULL | TRUE | NULL | NULL | NULL |
| MISSING | TRUE | MISSING | NULL | MISSING |

## NOT

```ebnf
not ::= 'NOT' cond
```

![Syntax diagram](../../assets/images/n1ql-language-reference/not.png)

NOT evaluates to TRUE if the condition is FALSE, and vice versa.

|  | NOT |
| --- | --- |
| TRUE | FALSE |
| FALSE | TRUE |
| NULL | NULL |
| MISSING | MISSING |

## Related Links

For further details, refer to [Boolean Logic](n1ql-language-reference/booleanlogic.adoc).
