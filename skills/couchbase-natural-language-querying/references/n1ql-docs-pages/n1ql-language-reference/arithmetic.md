# Arithmetic Operators

Arithmetic operations perform the basic mathematical operations of addition, subtraction, multiplication, division, and modulo within an expression or any numerical value retrieved as part of query clauses.
Additionally, {sqlpp} provides a negation operation which changes the sign of a value.

<dl><dt><strong>📌 NOTE</strong></dt><dd>

These arithmetic operators only operate on numbers.
In {sqlpp}, arithmetic operators have their usual meaning.
However, in any of these expressions:

* If any operand is MISSING, the value of the expression is MISSING.
* If any operand is NULL and no operand is MISSING, the value of the expression is NULL.
* If any operand is not a number, the operator evaluates to NULL.
</dd></dl>

## Syntax

There are six different arithmetic syntaxes:

```ebnf
arithmetic-term ::= expr '+' expr |
                    expr '-' expr |
                    expr '*' expr |
                    expr '/' expr |
                    expr '%' expr |
                    '-' expr
```

![Syntax diagram](../../assets/images/n1ql-language-reference/arithmetic-term.png)

| Operator | Description |
| --- | --- |
| + | Add values. |
| - | Subtract right value from left value. |
| * | Multiply values. |
| / | Divide left value by right value. |
| % | Modulo. Divide left value by right value and return the remainder. NOTE: Modulo is an integer operator and will use only the integer part of each value. |
| -`value` | Negate value. |

## Arguments

* **expr1, expr2**\
Number or an expression that results in a number value.

## Return Value

A number, representing the value of the arithmetic operation.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Select the longest flight and return its two airports and the distance in feet**

**Query**

```sqlpp
SELECT sourceairport, destinationairport, ROUND(distance) AS DistanceInMiles,
       ROUND(distance)*5280 AS DistanceInFeet
FROM route
ORDER BY distance DESC
LIMIT 1;
```

**Returns**

```json
[
  {
    "DistanceInFeet": 72906240,
    "DistanceInMiles": 13808,
    "destinationairport": "DFW",
    "sourceairport": "SYD"
  }
]
```

**Select the modulo of 5 and 3 and compare to the modulo of 5.4 and 3.4**

**Modulo with integers**

```sqlpp
SELECT 5 % 3;
```

**Returns**

```json
[
  {
    "$1": 2
  }
]
```

**Modulo with fractions**

```sqlpp
SELECT 5.4 % 3.4;
```

**Returns**

```json
[
  {
    "$1": 2
  }
]
```

## Related Links

Refer to [Comparison Operators](n1ql:n1ql-language-reference/comparisonops.adoc) for numeric comparisons.
