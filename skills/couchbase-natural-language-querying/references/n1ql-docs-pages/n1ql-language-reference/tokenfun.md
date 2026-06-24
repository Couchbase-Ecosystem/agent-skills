# Token Functions

Tokenization is the process of breaking a stream of text up into words, phrases, symbols, or other meaningful elements called tokens.
The list of tokens becomes input for further processing such as parsing or text mining.
Token functions are not limited to string input since they work with generic JSON objects and documents.

**📌 NOTE**\
If any arguments to any of the following functions are `MISSING` then the result is also `MISSING` (i.e.
no result is returned).
Similarly, if any of the arguments passed to the functions are `NULL` or are of the wrong type (e.g.
an integer instead of a string), then `NULL` is returned as the result.

## CONTAINS_TOKEN(input_obj, token_expr [, options ])

### Description
Checks whether or not the specified search token `token_expr` is a sub-string of the input object `input_obj`.

### Arguments
* **input_obj**\
Any JSON object, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, to search within.
* **token_expr**\
A token string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is being searched for.
* **options**\
An optional JSON object to control tokenization.
Within options:
names;; A boolean to include object names (default: true)
case;; Either "lower" or "upper" for case folding (default: no change to the original text)
specials;; A boolean to include strings with special characters, such as email addresses and URLs (default: false)
split;; A boolean to split string values into words (default: true)
trim;; A boolean to trim spaces around unsplit string values (default: true)

### Return Value
A boolean, representing whether the search expression exists within the input object.

This returns `true` if the sub-string exists within the input string, otherwise `false` is returned.

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Finding hotels with the word "Inn" within their name**

```sqlpp
SELECT name
FROM hotel
WHERE CONTAINS_TOKEN(name, "Inn",{"specials":true})
LIMIT 4;
```

```json
[
    {
        "name": "Sportsman Inn"
    },
    {
        "name": "Keefer's Inn"
    },
    {
        "name": "Quality Inn King City Hotel"
    },
    {
        "name": "Premier Inn, Albert Dock"
    }
]
```

## CONTAINS_TOKEN_LIKE(input_obj, token_expr [, options ])

### Description
Checks whether or not the specified search token `token_expr` is a sub-string of the input object `input_obj`.

### Arguments
* **input_obj**\
Any JSON object, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, to search within.
* **token_expr**\
A token string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is being searched for.
* **options**\
An optional JSON object to control tokenization.
Within options:
names;; A boolean to include object names (default: true)
case;; Either "lower" or "upper" for case folding (default: no change to the original text)
specials;; A boolean to include strings with special characters, such as email addresses and URLs (default: false)
split;; A boolean to split string values into words (default: true)
trim;; A boolean to trim spaces around unsplit string values (default: true)

### Return Value
A boolean, representing whether the search expression exists within the input object.

This returns `true` if the sub-string exists within the input string, otherwise `false` is returned.

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Finding email addresses of UK hotels**

```sqlpp
SELECT email
FROM hotel
WHERE CONTAINS_TOKEN_LIKE(email, "%uk",{"specials":true})
LIMIT 4;
```

```json
[
    {
        "email": "glencoe@syha.org.uk"
    },
    {
        "email": "owner@hillhousellanrhidian.co.uk"
    },
    {
        "email": "julia@number38thegower.co.uk"
    },
    {
        "email": "stay@holiday-harlech.co.uk"
    }
]
```

## CONTAINS_TOKEN_REGEXP(input_obj, token_expr [, options ])

### Description
Checks whether or not the specified search token `token_expr` is a sub-string of the input object `input_obj`.

### Arguments
* **input_obj**\
Any JSON object, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, to search within.
* **token_expr**\
A token string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is being searched for.
* **options**\
An optional JSON object to control tokenization.
Within options:
names;; A boolean to include object names (default: true)
case;; Either "lower" or "upper" for case folding (default: no change to the original text)
specials;; A boolean to include strings with special characters, such as email addresses and URLs (default: false)
split;; A boolean to split string values into words (default: true)
trim;; A boolean to trim spaces around unsplit string values (default: true)

### Return Value
A boolean, representing whether the search expression exists within the input object.

This returns `true` if the sub-string exists within the input string, otherwise `false` is returned.

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Finding hotels with the word "Inn" within their name**

```sqlpp
SELECT name
FROM hotel
WHERE CONTAINS_TOKEN_REGEXP(name, "In+.*",{"specials":true})
LIMIT 4;
```

```json
[
    {
        "name": "Sportsman Inn"
    },
    {
        "name": "Inveraray Youth Hostel"
    },
    {
        "name": "Inverness Youth Hostel"
    },
    {
        "name": "Indian Cove Campground"
    }
]
```

## HAS_TOKEN(input_obj, token_expr [, options ])

Alias for [CONTAINS_TOKEN()](#contains_tokeninput_obj-token_expr--options-).

## TOKENS(in_str, opt)

### Description
This function tokenizes (i.e.
breaks up into meaningful segments) the given input string based on specified delimiters, and other options.
It recursively enumerates all tokens in a JSON value and returns an array of values (JSON atomic values) as the result.

### Arguments
* **in_str**\
A valid JSON object, this can be anything: constant literal, simple JSON value, JSON key name or the whole document itself.

  The following table lists the rules for each JSON type:

  | JSON Type | Return Value |
  | --- | --- |
  | MISSING | [] |
  | NULL | [NULL] |
  | false | [false] |
  | true | [true] |
  | number | [number] |
  | string | SPLIT(string) |
  | array | FLATTEN(TOKENS(element) for each element in array (Concatenation of element tokens) |
  | object | For each name-value pair, name+TOKENS(value) |
* **opt**\
A JSON object indicating the options passed to the `TOKENS()` function.
Options can take the following options, and each invocation of `TOKENS()` can choose one or more of the options:
{"name": true};; **Optional**.
Valid values are `true` or `false`.
By default, this is set to true and `TOKENS()` will include field names.
You can choose to not include field names by setting this option to `false`.
{"case":"lower"};; **Optional**.
Valid values are `lower` or `upper`.
Default is neither, as in it returns the case of the original data.
Use this option to specify the case sensitivity.
{"specials": true};; **Optional**.
Use this option to preserve strings with specials characters, such as email addresses, URLs, and hyphenated phone numbers.
The default value is `false`.

  **📌 NOTE**\
  The `specials` options preserves special characters except at the end of a word.

### Return Value
An array of strings containing all of the tokens obtained from the input string.

### Examples
**📌 NOTE**\
By default, for speed, the results are randomly ordered.
To make the difference more clear between the first two example queries, the `ARRAY_SORT()` function is used.

**List the tokens of an array where `specials` is FALSE**

```sqlpp
SELECT ARRAY_SORT(
  TOKENS( ['jim@example.com, kim@example.com, http://example.com/, 408-555-1212'],
          {'specials': false} ));
```

```json
[
  {
    "$1": [
      "1212",
      "408",
      "555",
      "abc",
      "com",
      "http",
      "jim",
      "kim"
    ]
  }
]
```

**List the tokens of an array where `specials` is TRUE**

```sqlpp
SELECT ARRAY_SORT(
  TOKENS( ['jim@example.com, kim@example.com, http://example.com/, 408-555-1212'],
          {'specials': true} ));
```

```json
[
  {
    "$1": [
      "1212",
      "408",
      "408-555-1212",
      "555",
      "abc",
      "com",
      "http",
      "http://example.com",
      "jim",
      "jim@example.com",
      "kim",
      "kim@example.com"
    ]
  }
]
```

**Convert all of the URL data into UPPER case and adds the full URL to the delimited words**

For this example, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

```sqlpp
SELECT ARRAY_SORT( TOKENS(url) ) AS defaulttoken,
       ARRAY_SORT( TOKENS(url, {"specials":true, "case":"UPPER"}) ) AS specialtoken
FROM hotel
LIMIT 1;
```

```json
[
  {
    "defaulttoken": [
      "http",
      "org",
      "uk",
      "www",
      "yha"
    ],
    "specialtoken": [
      "HTTP",
      "HTTP://WWW.YHA.ORG.UK",
      "ORG",
      "UK",
      "WWW",
      "YHA"
    ]
  }
]
```

You can also use `{"case":"lower"}` or `{"case":"upper"}` to have case sensitive search.
Index creation and querying can use this and other parameters in combination.
These parameters should be passed within the query predicates as well.
The parameters and values must match exactly for {sqlpp} to pick up and use the index correctly.

**Create an index with `case` and use it your application**

For this example, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

```sqlpp
CREATE INDEX idx_url_upper_special ON hotel(
    DISTINCT ARRAY v FOR v IN
        TOKENS(url, {"specials":true, "case":"UPPER"})
    END );
```

```sqlpp
SELECT name, address, url
FROM hotel
WHERE ANY v IN TOKENS(url, {"specials":true, "case":"UPPER"})
      SATISFIES v = "HTTP://WWW.YHA.ORG.UK"
      END;
```

```json
{
    "results": [
        {
            "address": "Capstone Road, ME7 3JE",
            "name": "Medway Youth Hostel",
            "url": "http://www.yha.org.uk"
        }
    ]
}
```
