# SELECT Clause

<style type="text/css">
  /* DOC-10177 */
  .hdlist table tr td.hdlist1,
  .hdlist table tr td.hdlist2 {
    padding: 1.5rem 0 0;
  }

  /* Compact horizontal definition lists */
  .hdlist.compact,
  .hdlist.compact {
    padding-top: 1rem;
  }
  .hdlist.compact table tr td.hdlist1,
  .hdlist.compact table tr td.hdlist2 {
    padding: 0.5rem 0 0;
  }

  /* Descriptions in horizontal description lists should have left padding */
  .hdlist table tr td.hdlist2,
  .hdlist.compact table tr td.hdlist2 {
    padding-left: 1rem;
  }

  /* Paragraphs in horizontal description lists should not have left margin */
  .hdlist table .hdlist1 + .hdlist2 p {
    margin-left: 0; !important
  }

  /* Horizontal definitions should match style of vertical definitions */
  td.hdlist1 {
    font-weight: 600;
  }
</style>

The `SELECT` clause determines the result set.

## Purpose

In a `SELECT` statement, the `SELECT` clause determines the projection (result set).

## Prerequisites

For you to select data from a document or keyspace, you must have the `query_select` privilege on the document or keyspace.
For more details about user roles, see
[Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
select-clause ::= 'SELECT' hint-comment? projection exclude-clause?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/select-clause.png)

* **hint-comment**\
[Optimizer Hints](#optimizer-hints) icon:caret-down[]
* **projection**\
[Projection](#projection) icon:caret-down[]
* **exclude-clause**\
[EXCLUDE Clause](#exclude-clause) icon:caret-down[]

### Optimizer Hints

You can supply hints to the optimizer within a specially-formatted hint comment.
For further details, refer to [n1ql-language-reference/optimizer-hints.adoc](n1ql-language-reference/optimizer-hints.adoc).

### Projection

```ebnf
projection ::= ( 'ALL' | 'DISTINCT' )? ( result-expr ( ',' result-expr )* |
               ( 'RAW' | 'ELEMENT' | 'VALUE' ) expr ( 'AS'? alias )? )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/projection.png)

The projection consists of an optional `ALL` or `DISTINCT` [quantifier](#all--distinct), followed by one of the following alternatives:

* One or more [result expressions](#result-expression), separated by commas.
* A single [raw expression](#raw--element--value), including a [select expression](#field-expr) and an optional [alias](#as-alias).

#### ALL / DISTINCT

(Optional; default is ALL.)

SELECT ALL retrieves all of the data specified and will result in all of the specified columns, including all duplicates.

SELECT DISTINCT removes duplicate result objects from the query’s result set.

**📌 NOTE**\
The DISTINCT clause is not blocking in nature, since it streams the input and produces the output in parallel, while consuming less memory.

In general, `SELECT ALL` results in more returned documents than `SELECT DISTINCT` due to ``DISTINCT`’s extra step of removing duplicates.
Since `DISTINCT` is purely run in memory, it executes quickly, making the overhead of removing duplicates more noticeable as your recordset gets larger.
Refer to [SELECT ALL and SELECT DISTINCT](#ex-all-distinct).

#### Result Expression

```ebnf
result-expr ::= ( path '.' )? '*' | expr ( 'AS'? alias )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/result-expr.png)

```ebnf
path ::= identifier ( '[' expr ']' )* ( '.' identifier ( '[' expr ']' )* )*
```

![Syntax diagram](../../assets/images/n1ql-language-reference/path.png)

The result expression may contain one of the following alternatives:

* A [star expression](#star-expression-asterisk), preceded by an optional path.
* A [select expression](#select-expression), including an optional [alias](#as-alias).

#### RAW / ELEMENT / VALUE

(Optional; RAW and ELEMENT and VALUE are synonyms.)

When you specify one or more [result expressions](#result-expression) in the query projection, each result is wrapped in an object, and an implicit or explicit [alias](#as-alias) is given for each result expression.
This extra layer might not be desirable, since it requires extra output parsing.

SELECT RAW reduces the amount of data returned by eliminating the field attribute.
The RAW qualifier specifies that the expression that follows should not be wrapped in an object, and the alias for that expression should be suppressed, as shown in [SELECT and SELECT RAW with a simple expression](#ex-raw-expr) and [SELECT, SELECT RAW, and SELECT DISTINCT RAW with a field](#ex-raw-field).

The RAW qualifier only enables you to specify a single [select expression](#select-expression).
You cannot use the RAW qualifier with a [star expression](#star-expression-asterisk) or with multiple select expressions.

#### Star Expression ({asterisk})

The star expression `{asterisk}` enables you to select _all_ the fields from the source specified by the [FROM clause](n1ql-language-reference/from.adoc).

The star expression may be preceded by a [path](n1ql:n1ql-language-reference/nestedops.adoc), to select all the nested fields from within an array.

<dl><dt><strong>📌 NOTE</strong></dt><dd>

Omitting the keyspace name before a star expression adds the keyspace name to the result set; whereas if you include the keyspace name before a star expression, the keyspace name will not appear in the result set.
Refer to [Star expressions and select expressions with path](#ex-star).
</dd></dl>

#### Select Expression

The select expression is any expression that evaluates to a field to be included in the query’s result set.
At its simplest, this may be the name of a field in the data source, such as `id`, `airline`, or `stops`.
Refer to [Select fields by name](#ex-field).

The select expression may include a [path](n1ql:n1ql-language-reference/nestedops.adoc), to select a nested field from within an array, such as `schedule[0].day`.
Refer to [Select field with path](#ex-path).

If no field name is specified, the select expression allows you to perform calculations, such as `SELECT 10+20 AS Total;` or any other {sqlpp} expression.
For details with examples, see [{sqlpp} Expressions](n1ql-language-reference/index.adoc#N1QL_Expressions).

#### AS Alias

```ebnf
alias ::= identifier
```

![Syntax diagram](../../assets/images/n1ql-language-reference/alias.png)

A temporary name of a keyspace name or field name to make names more readable or unique.
Refer to [Select field with explicit alias](#ex-alias).

(((implicit alias)))
If you do not explicitly give a field an alias, it is given an _implicit alias_.

* For a field, the implicit alias is the same as the name of the field in the input.
* For a nested path, the implicit alias is defined as the last component in the path.
* For any expression which does not refer to a field, the implicit alias is a dollar sign followed by a number, based on the position of the expression in the projection; for example, `$1`, `$2`, and so on.

An implicit or explicit alias is returned in the result set, unless you suppress it using the [RAW keyword](#raw--element--value).

### EXCLUDE Clause

```ebnf
exclude-clause ::= 'EXCLUDE' exclude-term ( ',' exclude-term )*
```
![Syntax diagram](../../assets/images/n1ql-language-reference/exclude-clause.png)

The EXCLUDE clause removes specific fields from your query’s result set.

Instead of listing every field you want to include in the SELECT statement, use EXCLUDE to specify only the ones you want to omit.
This is particularly useful when you use the star expression (`{asterisk}`) to select all fields, but want to exclude a few.

The clause consists of one or more [EXCLUDE terms](#exclude-term), separated by commas.

#### EXCLUDE Term
```ebnf
exclude-term ::= identifier | string-expression
```
![Syntax diagram](../../assets/images/n1ql-language-reference/exclude-term.png)

An EXCLUDE term is a field that you want to exclude from the final projection.
It must exactly match the field name or alias as it appears in the projection.
Refer to [SELECT with an EXCLUDE clause](#ex-exclude-clause).

An EXCLUDE term can be:

* An identifier, such as `hotel.name`.
* A string expression with one or more fields separated by commas, such as `"hotel.name, address"`.

<dl><dt><strong>📌 NOTE</strong></dt><dd>

* If the field has an alias, you must use the alias as the term.
* When your query includes only one FROM term, fields are automatically qualified with it.
You can use the field name without the full identifier.
For example, `name` instead of `hotel.name`.
</dd></dl>

## Best Practices

When possible, explicitly list all fields you want in your result set instead of using a star expression `{asterisk}` to select all fields, since the `{asterisk}` requires an extra trip over your network -- one to get the list of field names and one to select the fields.

## Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-field"></a>**Select fields by name**

**Query**

```sqlpp
SELECT id, airline, stops FROM route LIMIT 1;
```

**Result**

```json
[
  {
    "airline": "AF",
    "id": 10000,
    "stops": 0
  }
]
```

<a name="ex-path"></a>**Select field with path**

**Query**

```sqlpp
SELECT schedule[0].day FROM route;
```

**Result**

```json
[
  {
    "day": 0
  }
]
```

<a name="ex-alias"></a>**Select field with explicit alias**

**Query**

```sqlpp
SELECT schedule[0].day AS Weekday FROM route LIMIT 1;
```

**Result**

```json
[
  {
    "Weekday": 0
  }
]
```

<a name="ex-all-distinct"></a>**SELECT ALL and SELECT DISTINCT**

Note that the queries in this example may take some time to run.

|     |     |
| --- | --- |
```sqlpp
SELECT ALL city FROM landmark;
```
| .Query 1 slightly slower | .Query 2 |
```sqlpp
SELECT DISTINCT city FROM landmark;
` slightly faster |

When used on a field such as `city`, which contains non-unique values, `SELECT DISTINCT` reduces the recordset to a small fraction of its original size; and while removing so many of the documents takes time, projecting the remaining small fraction is actually slightly faster than the overhead of removing duplicates.

|     |     |
| --- | --- |
```sqlpp
SELECT ALL META().id FROM landmark;
```
| .Query 3 much faster | .Query 4 |
```sqlpp
SELECT DISTINCT META().id FROM landmark;
` much slower |

On the other extreme, when used on a field such as `META().id` which contains only unique values, `SELECT DISTINCT` does not reduce the recordset at all, and the overhead of looking for duplicates is wasted effort.
In this case, `SELECT DISTINCT` takes about twice as long to execute as `SELECT ALL`.

<a name="ex-distinct-plan"></a>**Query plan using the `DISTINCT` operator**

**Query**

```sqlpp
EXPLAIN SELECT DISTINCT city FROM landmark;
```

**Results**

```json
[
  {
    "plan": {
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
                "distinct": true,
                "result_terms": [
                  {
                    "expr": "(`landmark`.`city`)"
                  }
                ]
              },
              {
                "#operator": "Distinct" // ①
              }
            ]
          }
        },
        {
          "#operator": "Distinct" // ①
        }
      ]
    },
    "text": "SELECT DISTINCT city FROM landmark;"
  }
]
```
1. Lines using the `DISTINCT` operator

<a name="ex-raw-expr"></a>**SELECT and SELECT RAW with a simple expression**

|     |     |
| --- | --- |
```sqlpp
SELECT {"a":1, "b":2};
```
| .Query | .Query |
```sqlpp
SELECT RAW {"a":1, "b":2};
```
```json
[
  {
    "$1": { // ①
      "a": 1,
      "b": 2
    }
  }
]
```
| .Results | .Results |
```json
[
  { // ②
    "a": 1,
    "b": 2
  }
]
```

1. Added implicit alias
2. No implicit alias

<a name="ex-raw-field"></a>**SELECT, SELECT RAW, and SELECT DISTINCT RAW with a field**

|     |     |     |
| --- | --- | --- |
```sqlpp
SELECT city
FROM airport
ORDER BY city LIMIT 5;
```
```sqlpp
SELECT RAW city
FROM airport
ORDER BY city LIMIT 5;
```
| .Query | .Query | .Query |
```sqlpp
SELECT DISTINCT RAW city
FROM airport
ORDER BY city LIMIT 5;
```
```json
[
  {
    "city": "Abbeville"
  },
  {
    "city": "Aberdeen"
  },
  {
    "city": "Aberdeen"
  },
  {
    "city": "Aberdeen"
  },
  {
    "city": "Abilene"
  }
]
```
```json
[
  "Abbeville",
  "Aberdeen",
  "Aberdeen",
  "Aberdeen",
  "Abilene"
]
```
| .Results | .Results | .Results |
```json
[
  "Abbeville",
  "Aberdeen",
  "Abilene",
  "Adak Island",
  "Addison"
]
```

<a name="ex1"></a>**Select all the fields of 1 document from the `airline` keyspace**

**Query**

```sqlpp
SELECT * FROM airline LIMIT 1;
```

**Results**

```json
[
  {
    "airline": {
      "callsign": "MILE-AIR",
      "country": "United States",
      "iata": "Q5",
      "icao": "MLA",
      "id": 10,
      "name": "40-Mile Air",
      "type": "airline"
    }
  }
]
```

<a name="ex2"></a>**Select all the fields of 1 document from the `landmark` keyspace**

**Query**

```sqlpp
SELECT * FROM landmark LIMIT 1;
```

**Results**

```json
[
  {
    "landmark": {
      "activity": "see",
      "address": "Prince Arthur Road, ME4 4UG",
      "alt": null,
      "city": "Gillingham",
      "content": "Adult - £6.99 for an Adult ticket that allows you to come back for further visits within a year (children's and concessionary tickets also available). Museum on military engineering and the history of the British Empire. A quite extensive collection that takes about half a day to see. Of most interest to fans of British and military history or civil engineering. The outside collection of tank mounted bridges etc can be seen for free. There is also an extensive series of themed special event weekends, admission to which is included in the cost of the annual ticket.",
      "country": "United Kingdom",
      "directions": null,
      "email": null,
      "geo": {
        "accuracy": "RANGE_INTERPOLATED",
        "lat": 51.39184,
        "lon": 0.53616
      },
      "hours": "Tues - Fri 9.00am to 5.00pm, Sat - Sun 11.30am - 5.00pm",
      "id": 10019,
      "image": null,
      "name": "Royal Engineers Museum",
      "phone": "+44 1634 822839",
      "price": null,
      "state": null,
      "title": "Gillingham (Kent)",
      "tollfree": null,
      "type": "landmark",
      "url": "http://www.remuseum.org.uk"
    }
  }
]
```

<a name="ex-star"></a>**Star expressions and select expressions with path**

<a name="q3"></a>**Query A**

```sqlpp
SELECT * FROM hotel LIMIT 5;
```

**Results**

```json
[
  {
    "hotel": { // ①
      "address": "Capstone Road, ME7 3JE",
      "alias": null,
      "checkin": null,
// ...
    }
  }
]
```

1. As the star expression does not include the keyspace name, the results are wrapped in an extra object, and the keyspace name is added to each result.

<a name="q4"></a>**Query B**

```sqlpp
SELECT hotel.* FROM hotel LIMIT 5;
```

**Results**

```json
[
  { // ①
    "address": "Capstone Road, ME7 3JE",
    "alias": null,
    "checkin": null,
// ...
  }
]
```

1. As the star expression includes the keyspace name, the keyspace name is not added to the results.

<a name="q5"></a>**Query C**

```sqlpp
SELECT meta().id, email, city, phone, hotel.reviews[0].ratings
FROM hotel LIMIT 5;
```

**Results**

```json
[
  { // ①
    "city": "Medway",
    "email": null,
    "id": "hotel_10025",
    "phone": "+44 870 770 5964",
    "ratings": {
      "Cleanliness": 5,
      "Location": 4,
      "Overall": 4,
      "Rooms": 3,
      "Service": 5,
      "Value": 4
    }
  },
// ...
]
```

1. With a select expression, you may optionally include the keyspace name; in either case, the keyspace name is not added to the results.

<a name="ex-exclude-clause"></a>**SELECT with an EXCLUDE clause**

**Query**

```sqlpp
SELECT * EXCLUDE reviews,h.public_likes,"geo,description"
FROM `travel-sample`.inventory.hotel h
ORDER BY meta().id LIMIT 1;
```

**Results**

```json
[
  {
    "h": {
      "address": "Capstone Road, ME7 3JE",
      "alias": null,
      "checkin": null,
      "checkout": null,
      "city": "Medway",
      "country": "United Kingdom",
      "directions": null,
      "email": null,
      "fax": null,
      "free_breakfast": true,
      "free_internet": false,
      "free_parking": true,
      "id": 10025,
      "name": "Medway Youth Hostel",
      "pets_ok": true,
      "phone": "+44 870 770 5964",
      "price": null,
      "state": null,
      "title": "Gillingham (Kent)",
      "tollfree": null,
      "type": "hotel",
      "url": "http://www.yha.org.uk",
      "vacancy": true
    }
  }
]
```

## Related Links

* [FROM clause](n1ql-language-reference/from.adoc)
* [USE clause](n1ql-language-reference/hints.adoc)
* [LET Clause](n1ql-language-reference/let.adoc)
* [WHERE Clause](n1ql-language-reference/where.adoc)
* [GROUP BY Clause](n1ql-language-reference/groupby.adoc)
* [UNION, INTERSECT, and EXCEPT Clause](n1ql-language-reference/union.adoc)
