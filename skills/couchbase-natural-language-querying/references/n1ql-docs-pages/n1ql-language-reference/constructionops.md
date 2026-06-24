# Construction Operators

{sqlpp} supports array and object construction operators.

## Array Constructors

Arrays are ordered lists with 0 or more values.
Arrays are enclosed in square brackets `[&#160;]`.
Commas separate each value.

### Syntax

```ebnf
array ::= '[' ( expr ( ',' expr )* )? ']'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/array.png)

### Arguments

* **expr**\
An expression resolving to any supported JSON data type.

### Example

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Simple array construction**

**Query**

```sqlpp
SELECT ["one", "two", "three"], [1, 2, 3];
```

**Results**

```json
[
  {
    "$1": [
      "one",
      "two",
      "three"
    ],
    "$2": [
      1,
      2,
      3
    ]
  }
]
```

**Dynamic array construction**

This example constructs a new array using the `address`, `city`, and `country` fields in the data source.

**Query**

```sqlpp
SELECT [ address, city, country ] AS location
FROM hotel LIMIT 3;
```

**Results**

```json
[
  {
    "location": [
      "Capstone Road, ME7 3JE",
      "Medway",
      "United Kingdom"
    ]
  },
  {
    "location": [
      "57-59 Balmoral Road, ME7 4NT",
      "Gillingham",
      "United Kingdom"
    ]
  },
  {
    "location": [
      "6 rue aux Juifs",
      "Giverny",
      "France"
    ]
  }
]
```

## Object Constructors

Objects contain name-value pairs or attributes.
Objects are enclosed in curly braces ``{``&#160;``}``.
Commas separate each attribute.
The colon (`:`) character separates the key or name from its value within each attribute.

### Syntax

```ebnf
object ::= '{' ( ( name-expr ':' )? expr (',' ( name-expr ':' )? expr)* )? '}'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/object.png)

### Arguments

* **name-expr**\
[Optional] An expression resolving to a string, which specifies the name of the attribute.
All names must be distinct from each other within the object.

  If a name does not evaluate to a string, the result of the object construction is NULL.
* **expr**\
An expression resolving to any supported JSON data type, which specifies the value of the attribute.

**Dynamic names**

**📌 NOTE**\
If the `expr` argument is an identifier referring to a named field in the data source, then you can omit the `name-expr` argument.
In this case, the name of the field in the data source will be used as the name of the attribute in the output object.

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Simple object construction**

**Query**

```sqlpp
SELECT { UPPER("foo") : 1, "foo" || "bar" : 2 };
```

**Results**

```json
[
  {
    "$1": {
      "FOO": 1,
      "foobar": 2
    }
  }
]
```

**Dynamic object construction**

This example constructs a new object using the `address`, `city`, and `country` fields in the data source.

**Query**

```sqlpp
SELECT { "street": address, city, country } AS location
FROM hotel LIMIT 3;
```

Notice we have provided a new name for the `street` attribute, but the `city` and `country` attributes are named dynamically.

**Results**

```json
[
  {
    "location": {
      "city": "Medway",
      "country": "United Kingdom",
      "street": "Capstone Road, ME7 3JE"
    }
  },
  {
    "location": {
      "city": "Gillingham",
      "country": "United Kingdom",
      "street": "57-59 Balmoral Road, ME7 4NT"
    }
  },
  {
    "location": {
      "city": "Giverny",
      "country": "France",
      "street": "6 rue aux Juifs"
    }
  }
]
```

## Related Links

Refer to [Range Transformations](n1ql:n1ql-language-reference/collectionops.adoc#range-xform) for a more sophisticated way to generate arrays and objects from a data source.
