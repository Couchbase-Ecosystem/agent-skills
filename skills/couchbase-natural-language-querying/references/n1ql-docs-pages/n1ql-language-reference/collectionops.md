# Collection Operators

Collection operators enable you to evaluate expressions over every element in an array.
The operators include [Range Predicates](#range-predicates), [Range Transformations](#range-transformations), and [Membership and Existence Tests](#membership-and-existence).

**📌 NOTE**\
Although collection operators can be used with any array, they are particularly useful when used to evaluate expressions over an array of objects.
The term _collection_ is used here in a generic sense to refer to any array of objects, rather than in the specific sense of a [Couchbase collection](learn:data/scopes-and-collections.adoc).

## Range Predicates

Range predicates ([ANY](#any), [EVERY](#every), or [ANY AND EVERY](#any-and-every)) enable you to test a Boolean condition over elements in an array.
They use the `IN` and `WITHIN` operators to range through the array.

(((range condition)))
(((quantified expression)))
Range predicates may also be known as _range conditions_ or _quantified expressions_.

#### Syntax

```ebnf
range-cond ::= ( ( 'ANY' | 'SOME' ) ( 'AND' 'EVERY' )? | 'EVERY' )
               range 'SATISFIES' cond 'END'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/range-cond.png)

```ebnf
range ::= ( name-var ':' )? var ( 'IN' | 'WITHIN' ) expr
    ( ',' ( name-var ':' )? var ( 'IN' | 'WITHIN' ) expr )*
```

![Syntax diagram](../../assets/images/n1ql-language-reference/range.png)

#### Arguments

* **name-var**\
[Optional] An [identifier](n1ql-language-reference/identifiers.adoc) that represents the position of a single element in an array, counting from 0.
* **var**\
An [identifier](n1ql-language-reference/identifiers.adoc) that represents a single element in an array.
* **expr**\
An [expression](n1ql-language-reference/index.adoc#N1QL_Expressions) that returns an array to evaluate.
* **cond**\
A condition to evaluate for each specified element.
This condition may make use of the `var` and `name-var` identifiers as required.

### ANY

`ANY` tests whether any element in an array matches a specified condition.
(If the array is empty, then no element in the array is deemed to match the condition.)

Synonym: `SOME` is a synonym for `ANY`.

#### Return Values

If the array is non-empty and at least one element in the array matches the specified condition, then the operator returns `TRUE`; otherwise, it returns `FALSE`.

#### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="AnyExA"></a>**ANY with one matching element**

Retrieve the details of KL flight schedules from Albuquerque (ABQ) to Atlanta (ATL) if any of the flights are after 23:40.

```sqlpp
SELECT * FROM route
WHERE airline="KL" AND sourceairport="ABQ"
  AND destinationairport="ATL"
  AND ANY departure IN schedule SATISFIES departure.utc > "23:40" END;
```

Since the last flight departs at 23:41, this query results in the entire array.

**Results**

```json
[
  {
    "travel-sample": {
      "airline": "KL",
      "airlineid": "airline_3090",
      "destinationairport": "ATL",
      "distance": 2038.3535078909663,
      "equipment": "757 320",
      "id": 36159,
      "schedule": [
        {
          "day": 0,
          "flight": "KL938",
          "utc": "03:54:00"
        },
// ...
        {
          "day": 5,
          "flight": "KL169",
          "utc": "23:41:00"
        },
// ...
        {
          "day": 6,
          "flight": "KL636",
          "utc": "17:40:00"
        }
      ],
      "sourceairport": "ABQ",
      "stops": 0,
      "type": "route"
    }
  }
]
```

<a name="AnyExB"></a>**ANY with no matching elements**

But if you change the `SATISFIES` clause to 1 minute after the last flight (23:42), then the resulting array is empty.

**Results**

```json
[]
```

<a name="AnyExC"></a>**ANY with empty array**

This example tests the ANY operator with an empty array.

```sqlpp
SELECT ANY v IN [] SATISFIES v = "abc" END AS existential;
```

In this case, the operator returns `false`.

**Results**

```json
[
  {
    "existential": false
  }
]
```

### EVERY

`EVERY` tests whether every element in an array matches a specified condition.
(If the array is empty, then every element in the array is deemed to match the condition.)

#### Return Values

If the array is empty, or if the array is non-empty and every element in the array matches the specified condition, then the operator returns `TRUE`; otherwise, it returns `FALSE`.

#### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="EveryExA"></a>**EVERY with all matching elements**

Retrieve the details of KL flight schedules from Albuquerque (ABQ) to Atlanta (ATL) if all of the flights are after 00:35.

```sqlpp
SELECT * FROM route
WHERE airline="KL"
  AND sourceairport="ABQ"
  AND destinationairport="ATL"
  AND EVERY departure IN schedule SATISFIES departure.utc > "00:35" END;
```

Since the earliest flight departs at 00:36, this query results in the entire array.

**Results**

```json
[
  {
    "travel-sample": {
      "airline": "KL",
      "airlineid": "airline_3090",
      "destinationairport": "ATL",
      "distance": 2038.3535078909663,
      "equipment": "757 320",
      "id": 36159,
      "schedule": [
// ...
        {
          "day": 6,
          "flight": "KL884",
          "utc": "00:36:00"
        },
// ...
        {
          "day": 6,
          "flight": "KL636",
          "utc": "17:40:00"
        }
      ],
      "sourceairport": "ABQ",
      "stops": 0,
      "type": "route"
    }
  }
]
```

<a name="EveryExB"></a>**EVERY with no matching elements**

But if you change the `SATISFIES` clause to 1 minute after the first flight (00:37), then the resulting array is empty.

**Results**

```json
[]
```

<a name="EveryExC"></a>**EVERY with empty array**

This example tests the EVERY operator with an empty array.

```sqlpp
SELECT EVERY v IN [] SATISFIES v = "abc" END AS universal;
```

In this case, the operator returns `true`.

**Results**

```json
[
  {
    "universal": true
  }
]
```

### ANY AND EVERY

`ANY AND EVERY` tests whether every element in an array matches a specified condition.
(If the array is empty, then no element in the array is deemed to match the condition.)

Synonym: `SOME AND EVERY` is a synonym for `ANY AND EVERY`.

#### Return Values

If the array is non-empty and every element in the array matches the specified condition, then the operator returns `TRUE`; otherwise, it returns `FALSE`.

#### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="AnyAndEveryEx"></a>**ANY AND EVERY with empty array**

This example tests the ANY AND EVERY operator with an empty array.

```sqlpp
SELECT ANY AND EVERY v IN [] SATISFIES v = "abc" END AS universal;
```

In this case, the operator returns `false`.

**Results**

```json
[
  {
    "universal": false
  }
]
```

## Range Transformations

Range transformations ([ARRAY](#array), [FIRST](#first), and [OBJECT](#object)) enable you to map and filter elements and attributes from an input array.
They use the `IN` and `WITHIN` operators to range through the array.

#### Syntax

```ebnf
range-xform ::= ( ( 'ARRAY' | 'FIRST' ) | 'OBJECT' name-expr ':' ) var-expr
                'FOR' range ( 'WHEN' cond )? 'END'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/range-xform.png)

```ebnf
range ::= ( name-var ':' )? var ( 'IN' | 'WITHIN' ) expr
    ( ',' ( name-var ':' )? var ( 'IN' | 'WITHIN' ) expr )*
```

![Syntax diagram](../../assets/images/n1ql-language-reference/range.png)

#### Arguments

* **name-expr**\
[`OBJECT` only] An [expression](n1ql-language-reference/index.adoc#N1QL_Expressions) that resolves to a string, to use as the name of an attribute in the output.
This expression may make use of the `var` and `name-var` identifiers as required.
* **var-expr**\
An [expression](n1ql-language-reference/index.adoc#N1QL_Expressions) that returns a value to include in the output.
This expression may make use of the `var` and `name-var` identifiers as required.
* **name-var**\
[Optional] An [identifier](n1ql-language-reference/identifiers.adoc) that represents the position of a single element in an array, counting from 0.
* **var**\
An [identifier](n1ql-language-reference/identifiers.adoc) that represents a single element in an array.
* **expr**\
An [expression](n1ql-language-reference/index.adoc#N1QL_Expressions) that returns an array to evaluate.
* **cond**\
[Optional] A condition to evaluate for each specified element.
This condition may make use of the `var` and `name-var` identifiers as required.

### ARRAY

The `ARRAY` operator generates a new array, using values in the input array.

#### Return Values

The operator returns a new array, which contains one element for each element in the input array.
If the `WHEN` clause is specified, only elements in the input array which satisfy the `WHEN` clause are considered.

The value of each element in the output array is the output of the `var-expr` argument for one element in the input array.

If the input array is empty, or no elements in the input array satisfy the `WHEN` clause, the operator returns an empty array.

#### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ArrayEx1a"></a>**ARRAY with array of objects**

List the details of KL flights from Albuquerque to Atlanta on Fridays.

```sqlpp
SELECT ARRAY v FOR v IN schedule WHEN v.day = 5 END AS fri_flights
FROM route
WHERE airline="KL"
  AND sourceairport="ABQ"
  AND destinationairport="ATL";
```

**Results**

```json
[
  {
    "fri_flights": [
      {
        "day": 5,
        "flight": "KL347",
        "utc": "08:51:00"
      },
      {
        "day": 5,
        "flight": "KL281",
        "utc": "06:26:00"
      },
      {
        "day": 5,
        "flight": "KL567",
        "utc": "03:54:00"
      },
      {
        "day": 5,
        "flight": "KL169",
        "utc": "23:41:00"
      }
    ]
  }
]
```

Compare this with the results of [FIRST](#FirstEx) and [OBJECT with array of objects](#ObjectExA).

<a name="ArrayEx1b"></a>**ARRAY with multiple range terms**

List the details of KL flights from Albuquerque to Atlanta on Fridays after 7pm only.

```sqlpp
SELECT ARRAY v
  FOR v IN schedule, w IN schedule WHEN v.utc > "19:00" AND w.day = 5 END
  AS fri_evening_flights
FROM route
WHERE airline="KL"
  AND sourceairport="ABQ"
  AND destinationairport="ATL";
```

**Results**

```json
[
  {
    "fri_evening_flights": [
      {
        "day": 5,
        "flight": "KL169",
        "utc": "23:41:00"
      }
    ]
  }
]
```

The same results can be reached by writing the query as follows:

```sqlpp
SELECT ARRAY v
  FOR v IN schedule WHEN v.utc > "19:00" AND v.day = 5 END
  AS fri_evening_flights
FROM route
WHERE airline="KL"
  AND sourceairport="ABQ"
  AND destinationairport="ATL";
```

<a name="ArrayEx0b"></a>**ARRAY with position variable**

List the first two KL flights from Albuquerque to Atlanta.
This example uses the position variable `i` to return just the first two elements in the input array.

```sqlpp
SELECT ARRAY v FOR i:v IN schedule WHEN i < 2 END AS two_flights
FROM route
WHERE airline="KL"
  AND sourceairport="ABQ"
  AND destinationairport="ATL";
```

**Results**

```json
[
  {
    "two_flights": [
      {
        "day": 0,
        "flight": "KL938",
        "utc": "03:54:00"
      },
      {
        "day": 0,
        "flight": "KL270",
        "utc": "16:57:00"
      }
    ]
  }
]
```

Refer to [OBJECT with position variable](#ObjectExB) for another example with position variables.

### FIRST

The `FIRST` operator generates a new value, using a single value in the input array.

#### Return Values

The operator returns the output of the `var-expr` argument for the first element in the input array.
If the `WHEN` clause is specified, only elements in the input array which satisfy the `WHEN` clause are considered.

If the input array is empty, or no elements in the input array satisfy the `WHEN` clause, the operator returns MISSING.

#### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="FirstEx"></a>**FIRST**

List the first KL flight from Albuquerque to Atlanta after 7pm.

```sqlpp
SELECT FIRST v FOR v IN schedule WHEN v.utc > "19:00" END AS first_flight
FROM route
WHERE airline="KL"
  AND sourceairport="ABQ"
  AND destinationairport="ATL";
```

**Results**

```json
[
  {
    "first_flight": [
      {
        "day": 1,
        "flight": "KL672",
        "utc": "19:19:00"
      }
    ]
  }
]
```

Compare this with the results of [ARRAY with array of objects](#ArrayEx1a) and [OBJECT with array of objects](#ObjectExA).

### OBJECT

The `OBJECT` operator generates a new object, using values in the input array.

#### Return Values

The operator returns an object, which contains one attribute for each element in the input array.
If the `WHEN` clause is specified, only elements in the input array which satisfy the `WHEN` clause are considered.

The value of each attribute in the output object is the output of the `var-expr` argument for one element in the input array.

The name of each attribute in the output object is specified by the `name-expr` argument.
This argument must be an expression that generates a unique name string for every value in the output object.
If the expression does not generate a string, then the current attribute is not output.
If the expression does not generate a unique name string for each value, then only the last attribute is output; all previous attributes are suppressed.

The `name-expr` argument may reference the `var` argument or the `name-var` argument, or use any other expression that generates a unique value.

If the input array is empty, or no elements in the input array satisfy the `WHEN` clause, the operator returns an empty object.

#### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ObjectExA"></a>**OBJECT with array of objects**

List the details of KL flights from Albuquerque to Atlanta on Fridays.
This example uses the [UUID()](n1ql:n1ql-language-reference/metafun.adoc#uuid) function to generate a unique name for each attribute in the output object.

```sqlpp
SELECT OBJECT UUID():v FOR v IN schedule WHEN v.day = 5 END AS fri_flights
FROM route
WHERE airline="KL"
  AND sourceairport="ABQ"
  AND destinationairport="ATL";
```

**Results**

```json
[
  {
    "fri_flights": {
      "14c040c6-2247-442f-bc27-0d7b3ff403b5": {
        "day": 5,
        "flight": "KL169",
        "utc": "23:41:00"
      },
      "645a53d6-53a2-4c0c-9431-75073c48806b": {
        "day": 5,
        "flight": "KL281",
        "utc": "06:26:00"
      },
      "6d93a43f-ecec-4e9d-89bf-2468f2771fa0": {
        "day": 5,
        "flight": "KL567",
        "utc": "03:54:00"
      },
      "f2823bc0-86e0-4a1a-a9d8-4ca496de8193": {
        "day": 5,
        "flight": "KL347",
        "utc": "08:51:00"
      }
    }
  }
]
```

Compare this with the results of [ARRAY with array of objects](#ArrayEx1a) and [FIRST](#FirstEx).

<a name="ObjectExB"></a>**OBJECT with position variable**

An alternative version of [OBJECT with array of objects](#ObjectExA).
This example uses the [TOSTRING()](n1ql:n1ql-language-reference/typefun.adoc#tostring) function and the position variable `i` to generate a unique name for each attribute in the output object.

```sqlpp
SELECT OBJECT "num_" || TOSTRING(i):v
  FOR i:v IN schedule WHEN v.day = 5 END
  AS fri_flights
FROM route
WHERE airline="KL"
  AND sourceairport="ABQ"
  AND destinationairport="ATL";
```

Notice that the position of each element in the input array is calculated _before_ applying the `WHEN` condition -- so the Friday flights are numbered from 14 to 17.

**Results**

```json
[
  {
    "fri_flights": {
      "num_14": {
        "day": 5,
        "flight": "KL347",
        "utc": "08:51:00"
      },
      "num_15": {
        "day": 5,
        "flight": "KL281",
        "utc": "06:26:00"
      },
      "num_16": {
        "day": 5,
        "flight": "KL567",
        "utc": "03:54:00"
      },
      "num_17": {
        "day": 5,
        "flight": "KL169",
        "utc": "23:41:00"
      }
    }
  }
]
```

Refer to [ARRAY with position variable](#ArrayEx0b) for another example with position variables.

## Membership and Existence

Membership tests ([IN](#in) and [WITHIN](#within)) enable you to test whether a value exists within an array.
Membership tests are efficient over arrays with a large number of elements -- up to approximately 8000.

The existence test ([EXISTS](#exists)) enables you to test whether an array contains any elements at all.

### IN

The `IN` operator specifies the search depth to include only the current level of an array, and not to include any child or descendant arrays.

#### Syntax

```ebnf
in-expr ::= search-expr 'NOT'? 'IN' target-expr
```

![Syntax diagram](../../assets/images/n1ql-language-reference/in-expr.png)

#### Arguments

* **earch-expr**\
An [expression](n1ql-language-reference/index.adoc#N1QL_Expressions) that returns the value to search for.
* **target-expr**\
An [expression](n1ql-language-reference/index.adoc#N1QL_Expressions) that resolves to the array to search through.

#### Return Values

The `IN` operator evaluates to `TRUE` if the right-side value is an array and directly contains the left-side value.

The `NOT IN` operator evaluates to `TRUE` if the right-side value is an array and does not directly contain the left-side value.

#### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="InExA"></a>**IN with simple array**

Search for all airlines from the United Kingdom or France.

```sqlpp
SELECT * FROM airline AS t
WHERE country IN ["United Kingdom", "France"];
```

This results in 60 documents:

**Results**

```json
[
  {
    "t": {
      "callsign": "CORSAIR",
      "country": "France",
      "iata": "SS",
      "icao": "CRL",
      "id": 1908,
      "name": "Corsairfly",
      "type": "airline"
    }
  },
// ...
]
```

<a name="InExB"></a>**IN with array of objects**

Search for the author "Walton Wolf" in the hotel keyspace.

```sqlpp
SELECT * FROM hotel AS t WHERE "Walton Wolf" IN t;
```

This results in an empty set because authors are not in the current level (the root level) of the hotel keyspace.

**Results**

```json
[]
```

The authors are listed inside the `reviews` array (a child element) and would need the `WITHIN` keyword to search all child elements along with the root level.

### WITHIN

The `WITHIN` operator specifies the search depth to include the current level of an array, and all of its child and descendant arrays.

#### Syntax

```ebnf
within-expr ::= search-expr 'NOT'? 'WITHIN' target-expr
```

![Syntax diagram](../../assets/images/n1ql-language-reference/within-expr.png)

#### Arguments

* **search-expr**\
An [expression](n1ql-language-reference/index.adoc#N1QL_Expressions) that returns the value to search for.
* **target-expr**\
An [expression](n1ql-language-reference/index.adoc#N1QL_Expressions) that resolves to the array to search through.

#### Return Values

The `WITHIN` operator evaluates to `TRUE` if the right-side value is an array and contains the left-side value as a child or descendant, that is, directly or indirectly.

The `NOT WITHIN` operator evaluates to `TRUE` if the right-side value is an array and no child or descendant contains the left-side value.

#### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="WithinEx"></a>**WITHIN**

Search all elements for the author "Walton Wolf" in the hotel documents.

```sqlpp
SELECT * FROM hotel AS t WHERE "Walton Wolf" WITHIN t;
```

This results in 1 document since his name appears inside the `reviews` array.

**Results**

```json
[
  {
    "t": {
      "address": "Gilsland, CA8 7DA",
      "alias": null,
      "checkin": null,
      "checkout": null,
      "city": null,
      "country": "United Kingdom",
      "description": "Tantallon House offers accommodation around 10 minutes walk from the National Trail. It also has a holiday cottage.",
      "directions": null,
      "email": null,
      "fax": null,
      "free_breakfast": true,
      "free_internet": true,
      "free_parking": false,
      "geo": {
        "accuracy": "ROOFTOP",
        "lat": 54.99304,
        "lon": -2.58142
      },
      "id": 10851,
      "name": "Tantallon House B&B",
      "pets_ok": true,
      "phone": null,
      "price": "From £44 (no cards)",
      "public_likes": [
        "Victor Russel"
      ],
      "reviews": [
        {
          "author": "Walton Wolf",
// ...
        }
      ],
      "state": null,
      "title": "Hadrian's Wall",
      "tollfree": null,
      "type": "hotel",
      "url": "http://www.tantallonhouse.co.uk/",
      "vacancy": false
    }
  }
]
```

### EXISTS

The `EXISTS` operator enables you to test whether an array has any elements, or is empty.

This operator may be used in a `SELECT`, `INSERT`, `UPDATE`, or `DELETE` statement in combination with a subquery.
The condition is met if the subquery returns at least one result.

#### Syntax

```ebnf
exists-expr ::= 'EXISTS' expr
```

![Syntax diagram](../../assets/images/n1ql-language-reference/exists-expr.png)

#### Arguments

* **expr**\
An [expression](n1ql-language-reference/index.adoc#N1QL_Expressions) that returns an array.

#### Return Values

If the expression is an array which contains at least one element, the operator evaluates to `TRUE`; otherwise, it evaluates to `FALSE`.

#### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ExistsEx"></a>**EXISTS**

Of the 274 cities with a hotel, search for all cities that have hotels with reviews.

```sqlpp
SELECT DISTINCT h.city
FROM hotel AS h
WHERE EXISTS h.reviews;
```

This results in 255 cities that contain hotels with reviews.

**Results**

```json
[
  {
    "city": "Medway"
  },
  {
    "city": "Giverny"
  },
  {
    "city": "Glasgow"
  },
  {
    "city": "Highland"
  },
//...
]
```

## Related Links

Refer to [Construction Operators](n1ql:n1ql-language-reference/constructionops.adoc) for a simpler way to generate arrays and objects from a data source.
