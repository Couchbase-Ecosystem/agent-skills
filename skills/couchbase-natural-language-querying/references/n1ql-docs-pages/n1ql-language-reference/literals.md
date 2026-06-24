# Literals

Literal values include strings, numbers, TRUE, FALSE, NULL, and MISSING.

{sqlpp} supports the same literals as JSON, as defined by [json.org](http://json.org/), with these exceptions:

* In {sqlpp}, "true", "false," and "null" are case-insensitive to be consistent with other {sqlpp} keywords.
In standard JSON, "true", "false," and "null" are case-sensitive.
* "missing" is added as a literal expression, although it is not returned in final results.
Missing is omitted from objects, and is converted to null in result arrays.
* In {sqlpp} single and double quotation marks can be used for strings.
JSON supports only double quotation marks.

Wherever a value is expected, either of two special values may appear: NULL (denoting an out-of-band value that is not comparable to any other value), and MISSING (denoting the absence of a value).
Every value also has a "truth" value; these truth value conversions are explained in [Boolean Logic](n1ql-language-reference/booleanlogic.adoc).

## Booleans

```ebnf
boolean ::= 'TRUE' | 'FALSE'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/boolean.png)

Boolean propositions evaluate to TRUE and FALSE.
These values are case-insensitive.

## Numbers

```ebnf
number ::= '-'? integer fraction? exponent?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/number.png)

```ebnf
integer ::= [0-9] | [1-9] [0-9]+
```

![Syntax diagram](../../assets/images/n1ql-language-reference/integer.png)

```ebnf
fraction ::= '.' [0-9]+
```

![Syntax diagram](../../assets/images/n1ql-language-reference/fraction.png)

```ebnf
exponent ::= ('e' | 'E') ('-' | '+')? [0-9]+
```

![Syntax diagram](../../assets/images/n1ql-language-reference/exponent.png)

Numbers can be either signed or unsigned integers with an optional fractional component and an optional exponent.
If the integer component has more than one digit, the number should not start with a leading zero.

## Strings

```ebnf
string ::= '"' char* '"' | "'" char* "'"
```

![Syntax diagram](../../assets/images/n1ql-language-reference/string.png)

```ebnf
char ::= unicode-character |
         '\' ( '\' | '"' | "'" | 'b' | 'f' | 'n' | 'r' | 't' | 'u' hex hex hex hex )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/char.png)

```ebnf
hex ::= [0-9a-fA-F]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/hex.png)

Strings can be either Unicode characters or escaped characters.

## NULL

```ebnf
null ::= 'NULL'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/null.png)

The literal NULL represents an empty value.
This value is case-insensitive.

## MISSING

```ebnf
missing ::= 'MISSING'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/missing.png)

The MISSING literal is specific to {sqlpp} and represents a missing name-value pair in a document.
This value is case-insensitive.
