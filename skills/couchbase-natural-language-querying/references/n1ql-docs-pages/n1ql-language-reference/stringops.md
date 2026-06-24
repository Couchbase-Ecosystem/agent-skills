# String Operators

{sqlpp} provides the concatenation string operator.

## Concatenation

The concatenation operator joins two strings.
The result of the concatenation operator is also a string.

### Syntax

```ebnf
concatenation-term ::= expr '||' expr
```

![Syntax diagram](../../assets/images/n1ql-language-reference/concatenation-term.png)

### Example

The following example shows concatenation of two strings.

**Query**

```sqlpp
WITH airline AS (
   [
      { "name": "Delta Airlines", "code": "DL" },
      { "name": "United Airlines", "code": "UA" }
   ]
)
SELECT name || " (" || code || ")" AS full_airline_name
FROM airline
```

**Result**

```json
[
  {
    "full_airline_name": "Delta Airlines (DL)"
  },
  {
    "full_airline_name": "United Airlines (UA)"
  }
]
```

## Related Links

Refer to [Comparison Operators](n1ql:n1ql-language-reference/comparisonops.adoc) for string comparisons.
