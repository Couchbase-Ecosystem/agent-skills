# Pattern-Matching Functions

Pattern-matching functions allow you to find regular expression patterns in strings or attributes.
Regular expressions can formally represent various string search patterns using different special characters to indicate wildcards, positional characters, repetition, optional or mandatory sequences of letters, etc.
{sqlpp} functions are available to find matching patterns, find position of matching pattern, or replace a pattern with a new string.

For more information on all supported REGEX patterns, see [https://golang.org/pkg/regexp/syntax](https://golang.org/pkg/regexp/syntax).

**📌 NOTE**\
From Couchbase Server 5.0, {sqlpp} supports regular expressions supported by The Go Programming Language version 1.8.

## REGEXP_CONTAINS(`expression`, `pattern`)

This function has an alias [REGEX_CONTAINS()](#aliases).

### Arguments

* **expression**\
String, or any {sqlpp} expression that evaluates to a string.
* **pattern**\
String representing a supported regular expression.

### Return Value

Returns TRUE if the string value contains any sequence that matches the regular expression pattern.

### Example

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Query**

```sqlpp
SELECT name
FROM landmark
WHERE REGEXP_CONTAINS(name, "In+.*")
LIMIT 5;
```

**Results**

```json
[
  {
    "name": "Beijing Inn"
  },
  {
    "name": "Sportsman Inn"
  },
  {
    "name": "In-N-Out Burger"
  },
  {
    "name": "Mel's Drive-In"
  },
  {
    "name": "Inverness Castle"
  }
]
```

## REGEXP_LIKE(`expression`, `pattern`)

This function has an alias [REGEX_LIKE()](#aliases).

### Arguments

* **expression**\
String, or any {sqlpp} expression that evaluates to a string.
* **pattern**\
String representing a supported regular expression.

### Return Value

Returns TRUE if the string value exactly matches the regular expression pattern.

### Example

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Query**

```sqlpp
SELECT name
FROM landmark
WHERE REGEXP_LIKE(name, "In+.*")
LIMIT 5;
```

**Results**

```json
[
  {
    "name": "In-N-Out Burger"
  },
  {
    "name": "Inverness Castle"
  },
  {
    "name": "Inverness Museum & Art Gallery"
  },
  {
    "name": "Inverness Botanic Gardens"
  },
  {
    "name": "International Petroleum Exchange"
  }
]
```

## REGEXP_MATCHES(`expression`, `pattern`)

### Arguments

* **expression**\
String, or any {sqlpp} expression that evaluates to a string.
* **pattern**\
String representing a supported regular expression.

### Return Value

Returns an array of all substrings matching the expression _pattern_ within the input string _expression_.
Returns an empty array if no match is found.

### Examples

**REGEXP_MATCHES() Example 1**

The following query finds all words beginning with upper or lower case B.

**Query**

```sqlpp
SELECT REGEXP_MATCHES("So, 'twas better Betty Botter bought a bit of better butter",
                      "\\b[Bb]\\w+"); -- ①
```

1. The backslash that introduces an escape sequence in the regular expression must itself be escaped by another backslash in the {sqlpp} query.
So `\b` (word boundary) must be entered as `\\b` and `\w` (word character) must be entered as `\\w`.

**Results**

```json
[
  {
    "$1": [
      "better",
      "Betty",
      "Botter",
      "bought",
      "bit",
      "better",
      "butter"
    ]
  }
]
```

**REGEXP_MATCHES() Example 2**

The following query finds sequences of two words beginning with upper or lower case B.

**Query**

```sqlpp
SELECT REGEXP_MATCHES("So, 'twas better Betty Botter bought a bit of better butter",
                      "\\b[Bb]\\w+ \\b[Bb]\\w+");
```

**Results**

```json
[
  {
    "$1": [
      "better Betty",
      "Botter bought", // ①
      "better butter"
    ]
  }
]
```

1. Note that `Betty Botter` is not found in this example, because `Betty` has already been found by the first match.

## REGEXP_POSITION(`expression`, `pattern`)

This function has an alias [REGEX_POSITION()](#aliases).

### Arguments

* **expression**\
String, or any {sqlpp} expression that evaluates to a string.
* **pattern**\
String representing a supported regular expression.

### Return Value

Returns first position of the occurrence of the regular expression _pattern_ within the input string _expression_.
Returns -1 if no match is found.
Position counting starts from zero.

### Example

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

The following query finds positions of first occurrence of vowels in each word of the _name_ attribute.

**Query**

```sqlpp
SELECT name, ARRAY REGEXP_POSITION(x, "[aeiou]") FOR x IN TOKENS(name) END
FROM hotel
LIMIT 2;
```

**Results**

```json
[
  {
    "$1": [
      1,
      1,
      1
    ],
    "name": "Medway Youth Hostel"
  },
  {
    "$1": [
      2,
      1,
      1
    ],
    "name": "The Balmoral Guesthouse"
  }
]
```

Note that the order of tokens in the second result may be different.

## REGEXP_REPLACE(`expression`, `pattern`, `repl` [, `n`])

This function has an alias [REGEX_REPLACE()](#aliases).

### Arguments

* **expression**\
String, or any {sqlpp} expression that evaluates to a string.
* **pattern**\
String representing a supported regular expression.
* **repl**\
String, or any {sqlpp} expression that evaluates to a string.
* **n**\
[Optional] The maximum number of times to find and replace the matching pattern.

### Return Value

Returns new string with occurrences of pattern replaced with _repl_.
If _n_ is given, at the most _n_ replacements are performed.
If _n_ is not provided, all matching occurrences are replaced.

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**REGEXP_REPLACE() Example 1**

**Query**

```sqlpp
SELECT REGEXP_REPLACE("Sql++ is sql for NoSql", "[sS][qQ][lL]", "SQL"),
       REGEXP_REPLACE("Winning innings Inn", "[Ii]n+", "Hotel", 6),
       REGEXP_REPLACE("Winning innings Inn", "[IiNn]+g", upper("inning"), 2);
```

**Results**

```json
[
  {
    "$1": "SQL++ is SQL for NoSQL",
    "$2": "WHotelHotelg HotelHotelgs Hotel",
    "$3": "WINNING INNINGs Inn"
  }
]
```

**REGEXP_REPLACE() Example 2**

In this example, the query retrieves first 4 documents and replaces the pattern of repeating n with emphasized NNNN.

**Query**

```sqlpp
SELECT name, REGEXP_REPLACE(name, "n+", "NNNN") as new_name
FROM airline
LIMIT 4;
```

**Results**

```json
[
  {
    "name": "40-Mile Air",
    "new_name": "40-Mile Air"
  },
  {
    "name": "Texas Wings",
    "new_name": "Texas WiNNNNgs"
  },
  {
    "name": "Atifly",
    "new_name": "Atifly"
  },
  {
    "name": "Jc royal.britannica",
    "new_name": "Jc royal.britaNNNNica"
  }
]
```

## REGEXP_SPLIT(`expression`, `pattern`)

### Arguments

* **expression**\
String, or any {sqlpp} expression that evaluates to a string.
* **pattern**\
String representing a supported regular expression.

### Return Value

Returns an array of all the substrings created by splitting the input string _expression_ at each occurrence of the expression _pattern_.
Returns an empty array if no match is found.

### Example

**Query**

```sqlpp
SELECT REGEXP_SPLIT("C:\\Program Files\\couchbase\\server\\bin", "[\\\\]") AS Windows, -- ①
REGEXP_SPLIT("/opt/couchbase/bin", "/") AS Unix;
```

1. The regular expression `[\\\\]` matches the escaped backslash `\\`.

**Results**

```json
[
  {
    "Unix": [
      "", // ①
      "opt",
      "couchbase",
      "bin"
    ],
    "Windows": [
      "C:",
      "Program Files",
      "couchbase",
      "server",
      "bin"
    ]
  }
]
```

1. The `REGEXP_SPLIT` function returns any zero-length matches that occur at the start of the _expression_ string, except when the split pattern is zero-length.
Otherwise, it returns any zero-length matches immediately after a previous match.

## Aliases

Some pattern-matching functions have an alias whose name begins with `REGEX_`.

* `REGEX_CONTAINS()` is an alias for [REGEXP_CONTAINS()](#regexp_containsexpression-pattern).
* `REGEX_LIKE()` is an alias for [REGEXP_LIKE()](#regexp_likeexpression-pattern).
* `REGEX_POSITION()` is an alias for [REGEXP_POSITION()](#regexp_positionexpression-pattern).
* `REGEX_REPLACE()` is an alias for [REGEXP_REPLACE()](#regexp_replaceexpression-pattern-repl--n).
