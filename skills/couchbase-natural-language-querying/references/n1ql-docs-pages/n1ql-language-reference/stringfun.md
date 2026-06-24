# String Functions

String functions perform operations on a string input value and returns a string or other value.

**📌 NOTE**\
If any arguments to any of the following functions are `MISSING` then the result is also `MISSING` -- that is, no result is returned.
Similarly, if any of the arguments passed to the functions are `NULL` or are of the wrong type, such as an integer instead of a string, then `NULL` is returned as the result.

## COMPRESS(`input_string`)

### Description

This function compresses a string using `zlib` compression and encodes the compressed data into `base64` format.
It returns a compact, encoded string that can be easily transmitted or stored.

**📌 NOTE**\
To convert a compressed string back to its original format, use the [UNCOMPRESS()](n1ql:n1ql-language-reference/stringfun.adoc#fn-str-uncompress) function.

### Arguments
* **input_string**\
A string or a valid expression that evaluates to a string.

### Return Value
A `base64` encoded string.

### Examples

**Example 1: Using a string argument**

**Query**

```sqlpp
SELECT COMPRESS("This is the string to compress");
```

**Result**

```json
[
  {
    "$1": "eJwKycgsVsgsVijJSFUoLinKzEtXKMlXSM7PLShKLS4GBAAA//+ouQs8"
  }
]
```

**Example 2: Using an expression that evaluates to a string as the argument**

**Query**

```sqlpp
SELECT COMPRESS(REPEAT("Hell0",10));
```

**Result**

```json
[
  {
    "$1": "eJzySM3JMSCJAAQAAP//tSYREw=="
  }
]
```

## CONCAT(`string1`, `string2`, …)

### Description
This function takes two or more strings and returns a new string after concatenating the input strings.
If there are fewer than two arguments, then it returns an error.

### Arguments
* **string1, string2, \...**\
[At least 2 are required] The strings, or valid [expressions](n1ql-language-reference/index.adoc) which evaluate to strings, to be concatenated together.

### Return Value
A new string, concatenated from the input strings.

### Examples
**Query**

```sqlpp
SELECT CONCAT("abc", "def", "ghi") AS concat;
```

**Result**

```json
[
  {
    "concat": "abcdefghi"
  }
]
```

## CONCAT2(`separator`, `arg1`, `arg2`, …)

### Description
This function takes the input strings, or arrays of strings, and concatenates them with the specified separator between each input string.
If there are fewer than two arguments, then it returns an error.

### Arguments
* **separator**\
[Required] The string to separate the input strings.
If no separator is required, specify the empty string "".
* **arg1, arg2, \...**\
[At least 1 is required] The strings, or arrays of strings, to be concatenated together.

### Return Value
A new string, concatenated from the inputs, with the separator between each input.
Arrays of strings are flattened and concatenated in the same order.
If there is only one string argument, the separator is not used.

If any argument or array element is MISSING, returns MISSING.
If any argument or array element is non-string, returns NULL.

### Examples
**Query**

```sqlpp
SELECT CONCAT2('-','a','b',['c','d'],['xyz']) AS c1,
CONCAT2('-','a') AS c2,
CONCAT2('-',['b']) AS c3;
```

**Result**

```json
[
  {
    "c1": "a-b-c-d-xyz",
    "c2": "a",
    "c3": "b"
  }
]
```

## CONTAINS(in_str, search_str)

### Description
Checks whether or not the specified search string is a substring of the input string -- that is, exists within.
This returns `true` if the substring exists within the input string, otherwise `false` is returned.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to search within.
* **search_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to search for.

### Return Value
A boolean, representing whether the search string exists within the input string.

### Examples
**Query**

```sqlpp
SELECT CONTAINS("SQL++ is awesome", "N1QL") as n1ql,
       CONTAINS("SQL++ is awesome", "SQL") as sql;
```

**Result**

```json
[
  {
    "n1ql": false,
    "sql": true
  }
]
```

## INITCAP(in_str)

### Description
Converts the string so that the first letter of each word is uppercase and every other letter is lowercase (known as 'Title Case').

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to convert to title case.

### Return Value
A string, representing the input string converted to title case.

### Limitations
This function capitalizes the initial letter of every word in the sentence, this means that even short words such as "the" and "or" will be capitalized.
This does not strictly follow title case conventions used in the writing domain.

### Examples
**Query**

```sqlpp
SELECT INITCAP("SQL++ is awesome") as sqlpp;
```

**Result**

```json
[
  {
    "sqlpp": "Sql++ Is Awesome"
  }
]
```

## LENGTH(in_str)

_Equivalent_: [LEN()](n1ql-language-reference/metafun.adoc#len)

### Description
Finds the length of a string, where length is defined as the number of code points within the string.

This function works with single bytes, not multi-byte characters.
For a variant of this function that works with multi-byte characters, see [MB_LENGTH()](#mb_lengthin_str).

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to find the length of.

### Return Value
An integer representing the length of the string.

### Examples
**Query**

```sqlpp
SELECT LENGTH("SQL++ is awesome") AS ascii,
       LENGTH("Café") AS diacritic,
       LENGTH("🙂") AS emoji,
       LENGTH("") AS zero;
```

**Result**

```json
[
  {
    "ascii": 16,
    "diacritic": 5, // ①
    "emoji": 4, // ②
    "zero": 0
  }
]
```

1. The letter with diacritic counts as two bytes.
2. The emoji counts as four bytes.

## LOWER(in_str)

### Description
Converts all characters in the input string to lower case.
This is useful for canonical comparison of string values.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to convert to lower case.

### Return Value
A string representing the input string converted to lower case.

### Examples
**Query**

```sqlpp
SELECT LOWER("SQL++ is awesome") as sqlpp;
```

**Result**

```json
[
  {
    "sqlpp": "sql++ is awesome"
  }
]
```

## LPAD(in_str, size [, char])

### Description
Pads a string with leading characters.
The function adds characters to the beginning of the string to pad the string to a specified length.

This function works with single bytes, not multi-byte characters.
For a variant of this function that works with multi-byte characters, see [MB_LPAD()](#mb_lpadin_str-size--char).

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to add the leading characters to.
* **size**\
An integer, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to an integer, that specifies the desired length of the result string.
* **char**\
[Optional] A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that represents the characters to add to the input string.

  If omitted, the default is space `" "`, Unicode U+0020.

### Return Value
A string representing the input string with leading characters added.

* If the specified size is smaller than the length of the input string, the input string is truncated and no padding is added.
* If the specified size is larger than the length of the input string, but shorter than the length of the input string plus the padding characters, the padding characters are truncated.
* If the specified size is greater than the length of the input string plus the padding characters, the padding characters are repeated in order until the specified size is reached.

### Examples
**Query**

```sqlpp
SELECT LPAD("SQL++ is awesome", 20) AS implicit_padding,
       LPAD("SQL++ is awesome", 20, "🙂!") AS repeated_padding,
       LPAD("SQL++ is awesome", 20, "987654321") AS truncate_padding,
       LPAD("SQL++ is awesome", 5, "987654321") AS truncate_string;
```

**Result**

```json
[
  {
    "implicit_padding": "    SQL++ is awesome",
    "repeated_padding": "🙂SQL++ is awesome", // ①
    "truncate_padding": "9876SQL++ is awesome",
    "truncate_string": "SQL++"
  }
]
```

1. The emoji counts as four bytes when calculating the size.

## LTRIM(in_str [, char])

### Description
Removes all leading characters from a string.
The function removes all consecutive characters from the beginning of the string that match the specified characters and stops when it encounters a character that does not match any of the specified characters.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to remove the leading characters from.
* **char**\
[Optional] A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that represents the characters to trim from the input string.
Each character in this string is trimmed from the input string -- you don’t need to delimit the characters to trim.
For example, specifying a character value of `"abc"` trims the characters "a", "b" and "c" from the start of the string.

  If omitted, the default is whitespace: space `" "`, tab `"\t"`, newline `"\n"`, formfeed `"\f"`, or carriage return `"\r"`.

### Return Value
A string representing the input string with leading characters removed.

### Examples
**Query**

```sqlpp
SELECT LTRIM("...SQL++ is awesome", ".") as dots,
       LTRIM("     SQL++ is awesome", " ") as explicit_spaces,
       LTRIM("\t   SQL++ is awesome") as implicit_spaces,
       LTRIM("SQL++ is awesome") as no_dots;
```

**Result**

```json
[
  {
    "dots": "SQL++ is awesome",
    "explicit_spaces": "SQL++ is awesome",
    "implicit_spaces": "SQL++ is awesome",
    "no_dots": "SQL++ is awesome"
  }
]
```

## MASK(in_str [, options])

### Description
Overlays specified characters in the string with masking characters.
This may be useful when returning sensitive information, such as credit card numbers or email addresses.

### Arguments

* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that represents the string to mask.
* **options**\
An object containing the following possible parameters:

mask;; A string containing masking characters that will be used to overlay the input string.
May optionally also contain _hole_ characters, representing gaps in the mask; and _inject_ characters, that are inserted into the output.
(Default: `pass:c[************]`)

hole;; A string containing the character or characters used to indicate holes in the mask string.
(Default: space)

inject;; A string containing the character or characters in the mask string that are inserted into the output, rather than overlaying the input.
(Default: none)

length;; Determines the length of the output string.
(Default: missing)

* If this property is missing, or set to anything other than `"source"`, the length of the output is dynamic.
Any characters in the input up to the anchor point (see below) are included in the output.
The mask then starts at the anchor point, and continues for the length of the specified mask string.
Any characters in the input beyond the end of the mask are deleted.
This method may therefore obscure the number of characters in the input.
* If the value is `"source"`, the length of the output is the same as the length of the input.
Any characters in the input up to the anchor point are included in the output.
The mask then starts at the anchor point.
If the mask is _longer than_ the remaining length of the input, the mask is truncated to fit.
If the mask string is _shorter than or the same length as_ the remaining length of the input, the mask continues for the length of the specified mask string.
Any characters in the input beyond the end of the mask are included in the output.

anchor;; Determines where in the input string the mask should start.
Possible values are `"start"`, `"end"`, a regular expression string, a positive integer, or a negative integer.
(Default: `"start"`)

* `"start"` -- the mask begins at the start of the input and is applied towards the end.
* `"end"` -- the mask begins at the end of the input and is applied from the end towards the start.
* Regular expression -- the mask begins at the first point in the input which matches the regular expression, and is applied towards the end.
If you need to match the strings `"start"` or `"end"`, use patterns such as `"[s]tart"` or `"[e]nd"`.
* Positive integer -- the mask begins the specified number of characters after the start of the input, and is applied towards the end.
* Negative integer -- the mask begins the specified number of characters before the end of the input, and is applied towards the start.

+
+
If an anchor places the mask outside the boundaries of the input string, the input string is returned unchanged.

### Return Value
A string representing the masked input string.

### Examples
Default mask, custom mask, custom mask demonstrating holes.

**Query**

```sqlpp
SELECT MASK('SomeTextToMask') AS mask,
       MASK('SomeTextToMask', {"mask": "++++"}) AS mask_custom,
       MASK('SomeTextToMask', {"mask": "++++    ++++"}) AS mask_hole;
```

**Result**

```json
[
  {
    "mask": "********",
    "mask_custom": "++++",
    "mask_hole": "++++Text++++"
  }
]
```

Mask with character injection.

**Query**

```sqlpp
SELECT MASK('1234abcd5678efgh', {"mask": "****-****-****-####",
                                 "hole": "#",
                                 "inject": "-"}) AS mask_inject;
```

**Result**

```json
[
  {
    "mask_inject": "****-****-****-efgh"
  }
]
```

Mask anchored to the end of the source, with the output length determined by the source.

**Query**

```sqlpp
SELECT MASK('1234abcd5678efgh', {"mask": "****", "anchor": "end", "length": "source"})
AS end_anchor;
```

**Result**

```json
[
  {
    "end_anchor": "1234abcd5678****"
  }
]
```

Mask anchored at the pattern `d5`.

**Query**

```sqlpp
SELECT MASK('1234abcd5678efgh', {"mask": "****", "anchor": "d5"}) AS regex_anchor;
```

**Result**

```json
[
  {
    "regex_anchor": "1234abc****"
  }
]
```

Mask anchored 2 characters from the end of the source, with length determined by the input string.

**Query**

```sqlpp
SELECT MASK('1234abcd5678efgh', {"mask": "****", "anchor": -2, "length": "source"})
AS negative_anchor;
```

**Result**

```json
[
  {
    "negative_anchor": "1234abcd56****gh"
  }
]
```

Mask anchored at the 14th character, with length determined by the input string.

**Query**

```sqlpp
SELECT MASK('1234abcd5678efgh', {"mask": "****", "anchor": 14, "length": "source"})
AS positive_anchor;
```

**Result**

```json
[
  {
    "positive_anchor": "1234abcd5678ef**"
  }
]
```

## MB_LENGTH(in_str)

### Description
Finds the length of a string, where length is defined as the number of characters within the string.

This function works with multi-byte characters, not single bytes.
For a variant of this function that works with single bytes, see [LENGTH()](#lengthin_str).

Because this function works with multi-byte characters, it may be slower than its single byte variant.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to find the length of.

### Return Value
An integer representing the length of the string.

### Examples
**Query**

```sqlpp
SELECT MB_LENGTH("SQL++ is awesome") AS ascii,
       MB_LENGTH("Café") AS diacritic,
       MB_LENGTH("🙂") AS emoji,
       MB_LENGTH("") AS zero;
```

**Result**

```json
[
  {
    "ascii": 16,
    "diacritic": 4, // ①
    "emoji": 1, // ②
    "zero": 0
  }
]
```

1. The letter with diacritic counts as a single character.
2. The emoji counts as a single character.

## MB_LPAD(in_str, size [, char])

### Description
Pads a string with leading characters.
The function adds characters to the beginning of the string to pad the string to a specified length.

This function works with multi-byte characters, not single bytes.
For a variant of this function that works with single bytes, see [LPAD()](#lpadin_str-size--char).

Because this function works with multi-byte characters, it may be slower than its single byte variant.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to add the leading characters to.
* **size**\
An integer, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to an integer, that specifies the desired length of the result string.
* **char**\
[Optional] A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that represents the characters to add to the input string.

  If omitted, the default is space `" "`, Unicode U+0020.

### Return Value
A string representing the input string with leading characters added.

* If the specified size is smaller than the length of the input string, the input string is truncated and no padding is added.
* If the specified size is larger than the length of the input string, but shorter than the length of the input string plus the padding characters, the padding characters are truncated.
* If the specified size is greater than the length of the input string plus the padding characters, the padding characters are repeated in order until the specified size is reached.

### Examples
**Query**

```sqlpp
SELECT MB_LPAD("SQL++ is awesome", 20) AS implicit_padding,
       MB_LPAD("SQL++ is awesome", 20, "🙂!") AS repeated_padding,
       MB_LPAD("SQL++ is awesome", 20, "987654321") AS truncate_padding,
       MB_LPAD("SQL++ is awesome", 5, "987654321") AS truncate_string;
```

**Result**

```json
[
  {
    "implicit_padding": "    SQL++ is awesome",
    "repeated_padding": "🙂!🙂!SQL++ is awesome", // ①
    "truncate_padding": "9876SQL++ is awesome",
    "truncate_string": "SQL++"
  }
]
```

1. The emoji counts as a single character when calculating the size.

## MB_RPAD(in_str, size [, char])

### Description
Pads a string with trailing characters.
The function adds characters to the end of the string to pad the string to a specified length.

This function works with multi-byte characters, not single bytes.
For a variant of this function that works with single bytes, see [RPAD()](#rpadin_str-size--char).

Because this function works with multi-byte characters, it may be slower than its single byte variant.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to add the trailing characters to.
* **size**\
An integer, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to an integer, that specifies the desired length of the result string.
* **char**\
[Optional] A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that represents the characters to add to the input string.

  If omitted, the default is space `" "`, Unicode U+0020.

### Return Value
A string representing the input string with trailing characters added.

* If the specified size is smaller than the length of the input string, the input string is truncated and no padding is added.
* If the specified size is larger than the length of the input string, but shorter than the length of the input string plus the padding characters, the padding characters are truncated.
* If the specified size is greater than the length of the input string plus the padding characters, the padding characters are repeated in order until the specified size is reached.

### Examples
**Query**

```sqlpp
SELECT MB_RPAD("SQL++ is awesome", 20) AS implicit_padding,
       MB_RPAD("SQL++ is awesome", 20, "🙂!") AS repeated_padding,
       MB_RPAD("SQL++ is awesome", 20, "123456789") AS truncate_padding,
       MB_RPAD("SQL++ is awesome", 5, "123456789") AS truncate_string;
```

**Result**

```json
[
  {
    "implicit_padding": "SQL++ is awesome    ",
    "repeated_padding": "SQL++ is awesome🙂!🙂!", // ①
    "truncate_padding": "SQL++ is awesome1234",
    "truncate_string": "SQL++"
  }
]
```

1. The emoji counts as a single character when calculating the size.

## MB_SUBSTR(in_str, start_pos [, length])

### Description
Returns the substring (of given length) counting forward from the provided position.
The position is zero-based -- that is, the first position is 0.
If position is negative, it is counted from the end of the string; -1 is the last position in the string.

This function works with multi-byte characters, not single bytes.
For a variant of this function that works with single bytes, see [SUBSTR()](#substrin_str-start_pos--length).

Because this function works with multi-byte characters, it may be slower than its single byte variant.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to convert to extract the substring from.
* **start_pos**\
An integer, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to an integer, that is the start position of the substring.
* **length**\
[Optional; default is to capture to the end of the string]

  An integer, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to an integer, that is the length of the substring to extract.

### Return Value
A string representing the substring extracted from the input string.

### Examples
**Query**

```sqlpp
SELECT MB_SUBSTR("🙂 SQL++ is awesome", 11) as rest_of_string,
       MB_SUBSTR("🙂 SQL++ is awesome", 11, 1) as single_letter,
       MB_SUBSTR("🙂 SQL++ is awesome", 0, 10) as ten_from_start;
```

**Result**

```json
[
  {
    "rest_of_string": "awesome",
    "single_letter": "a",
    "ten_from_start": "🙂 SQL++ is"
  }
]
```

The emoji counts as a single character for the starting position and the substring length.

## MB_SUBSTR1(in_str, start_pos [, length])

### Description
Returns the substring (of given length) counting forward from the provided position.
The position is one-based -- that is, the first position is 1.
If position is negative, it is counted from the end of the string; 0 is the last position in the string.

This function works with multi-byte characters, not single bytes.
For a variant of this function that works with single bytes, see [SUBSTR1()](#substr1in_str-start_pos--length).

Because this function works with multi-byte characters, it may be slower than its single byte variant.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to convert to extract the substring from.
* **start_pos**\
An integer, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to an integer, that is the start position of the substring.
* **length**\
[Optional; default is to capture to the end of the string]

  An integer, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to an integer, that is the length of the substring to extract.

### Return Value
A string representing the substring extracted from the input string.

### Examples
**Query**

```sqlpp
SELECT MB_SUBSTR1("🙂 SQL++ is awesome", 12) as rest_of_string,
       MB_SUBSTR1("🙂 SQL++ is awesome", 12, 1) as single_letter,
       MB_SUBSTR1("🙂 SQL++ is awesome", 0, 10) as ten_from_start;
```

**Result**

```json
[
  {
    "rest_of_string": "awesome",
    "single_letter": "a",
    "ten_from_start": "🙂 SQL++ is"
  }
]
```

The emoji counts as a single character for the starting position and the substring length.

## MB_POS(in_str, search_str)

Alias for [MB_POSITION()](#mb_positionin_str-search_str).

## MB_POS1(in_str, search_str)

Alias for [MB_POSITION1()](#mb_position1in_str-search_str).

## MB_POSITION(in_str, search_str)

### Description
Finds the first position of the search string within the string.
This position is zero-based -- that is, the first position is 0.
If the search string does not exist within the input string then the function returns -1.

This function works with multi-byte characters, not single bytes.
For a variant of this function that works with single bytes, see [POSITION()](#positionin_str-search_str).

Because this function works with multi-byte characters, it may be slower than its single byte variant.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to search within.
* **search_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to search for.

### Return Value
An integer representing the first position of the search string.

### Examples
**Query**

```sqlpp
SELECT MB_POSITION("🙂 SQL++ is awesome", "awesome") as awesome,
       MB_POSITION("🙂 SQL++ is awesome", "N1QL") as n1ql,
       MB_POSITION("🙂 SQL++ is awesome", "SQL") as sql;
```

**Result**

```json
[
  {
    "awesome": 11,
    "n1ql": -1,
    "sql": 2
  }
]
```

The emoji counts as a single character when calculating the position.

## MB_POSITION1(in_str, search_str)

### Description
Finds the first position of the search string within the string.
This position is one-based -- that is, the first position is 1.
If the search string does not exist within the input string then the function returns 0.

This function works with multi-byte characters, not single bytes.
For a variant of this function that works with single bytes, see [POSITION1()](#position1in_str-search_str).

Because this function works with multi-byte characters, it may be slower than its single byte variant.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to search within.
* **search_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to search for.

### Return Value
An integer representing the first position of the search string.

### Examples
**Query**

```sqlpp
SELECT MB_POSITION1("🙂 SQL++ is awesome", "awesome") as awesome,
       MB_POSITION1("🙂 SQL++ is awesome", "N1QL") as n1ql,
       MB_POSITION1("🙂 SQL++ is awesome", "SQL") as sql;
```

**Result**

```json
[
  {
    "awesome": 12,
    "n1ql": 0,
    "sql": 3
  }
]
```

The emoji counts as a single character when calculating the position.

## POS(in_str, search_str)

Alias for [POSITION()](#positionin_str-search_str).

## POS1(in_str, search_str)

Alias for [POSITION1()](#position1in_str-search_str).

## POSITION(in_str, search_str)

### Description
Finds the first position of the search string within the string.
This position is zero-based -- that is, the first position is 0.
If the search string does not exist within the input string then the function returns -1.

This function works with single bytes, not multi-byte characters.
For a variant of this function that works with multi-byte characters, see [MB_POSITION()](#mb_positionin_str-search_str).

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to search within.
* **search_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to search for.

### Return Value
An integer representing the first position of the search string.

### Examples
**Query**

```sqlpp
SELECT POSITION("🙂 SQL++ is awesome", "awesome") as awesome,
       POSITION("🙂 SQL++ is awesome", "N1QL") as n1ql,
       POSITION("🙂 SQL++ is awesome", "SQL") as sql;
```

**Result**

```json
[
  {
    "awesome": 14,
    "n1ql": -1,
    "sql": 5
  }
]
```

The emoji counts as four bytes when calculating the position.

## POSITION1(in_str, search_str)

### Description
Finds the first position of the search string within the string.
This position is one-based -- that is, the first position is 1.
If the search string does not exist within the input string then the function returns 0.

This function works with single bytes, not multi-byte characters.
For a variant of this function that works with multi-byte characters, see [MB_POSITION1()](#mb_position1in_str-search_str).

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to search within.
* **search_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to search for.

### Return Value
An integer representing the first position of the search string.

### Examples
**Query**

```sqlpp
SELECT POSITION1("🙂 SQL++ is awesome", "awesome") as awesome,
       POSITION1("🙂 SQL++ is awesome", "N1QL") as n1ql,
       POSITION1("🙂 SQL++ is awesome", "SQL") as sql;
```

**Result**

```json
[
  {
    "awesome": 15,
    "n1ql": 0,
    "sql": 6
  }
]
```

The emoji counts as four bytes when calculating the position.

## REPEAT(in_str, n)

### Description
Creates a new string which is the input string repeated the specified number of times.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to repeat.
* **n**\
An integer, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to an integer, that is the number of times to repeat the string.

### Return Value
A string representing the string generated by repeating the input string.

### Limitations
It is possible to generate very large strings using this function.
In some cases the query engine may be unable to process all of these and cause excessive resource consumption.
It is therefore recommended that you first validate the inputs to this function to ensure that the generated result is a reasonable size.

### Examples
**Query**

```sqlpp
SELECT REPEAT("SQL++", 0) as empty_string,
       REPEAT("SQL++", 3) as repeat_3;
```

**Result**

```json
[
  {
    "empty_string": "",
    "repeat_3": "SQL++SQL++SQL++"
  }
]
```

## REPLACE(in_str, search_str, replace [, n ])

### Description
Replaces occurrences of a given substring in an input string.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to search for replacements in.
* **search_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to replace.
* **replace**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to replace the search string with.
* **n**\
[Optional; default is all instances of the search string are replaced]

  An integer, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to an integer, which represents the number of instances of the search string to replace.
  If a negative value is specified then all instances of the search string are replaced.

### Return Value
A string representing the input string with the specified substring replaced.

### Examples
**Query**

```sqlpp
SELECT REPLACE("SQL SQL SQL", "L", "L++", -2) as negative_n,
       REPLACE("SQL SQL SQL", "L", "L++", 2) as replace_2,
       REPLACE("SQL SQL SQL", "L", "L++") as replace_all;
```

**Result**

```json
[
  {
    "negative_n": "SQL++ SQL++ SQL++",
    "replace_2": "SQL++ SQL++ SQL",
    "replace_all": "SQL++ SQL++ SQL++"
  }
]
```

## REVERSE(in_str)

### Description
Reverses the order of the characters in a given string.
That is, the first character becomes the last character and the last character becomes the first character, and so on.
Among other things, you can use this function to test whether or not a string is a palindrome.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to reverse.

### Return Value
A string representing the input string with its characters reversed.

### Examples
**Query**

```sqlpp
SELECT REVERSE("SQL++ is awesome") as sqlpp,
       REVERSE("racecar") as palindrome;
```

**Result**

```json
[
  {
    "sqlpp": "emosewa si ++LQS",
    "palindrome": "racecar"
  }
]
```

## RPAD(in_str, size [, char])

### Description
Pads a string with trailing characters.
The function adds characters to the end of the string to pad the string to a specified length.

This function works with single bytes, not multi-byte characters.
For a variant of this function that works with multi-byte characters, see [MB_RPAD()](#mb_rpadin_str-size--char).

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to add the trailing characters to.
* **size**\
An integer, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to an integer, that specifies the desired length of the result string.
* **char**\
[Optional] A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that represents the characters to add to the input string.

  If omitted, the default is space `" "`, Unicode U+0020.

### Return Value
A string representing the input string with trailing characters added.

* If the specified size is smaller than the length of the input string, the input string is truncated and no padding is added.
* If the specified size is larger than the length of the input string, but shorter than the length of the input string plus the padding characters, the padding characters are truncated.
* If the specified size is greater than the length of the input string plus the padding characters, the padding characters are repeated in order until the specified size is reached.

### Examples
**Query**

```sqlpp
SELECT RPAD("SQL++ is awesome", 20) AS implicit_padding,
       RPAD("SQL++ is awesome", 20, "🙂!") AS repeated_padding,
       RPAD("SQL++ is awesome", 20, "123456789") AS truncate_padding,
       RPAD("SQL++ is awesome", 5, "123456789") AS truncate_string;
```

**Result**

```json
[
  {
    "implicit_padding": "SQL++ is awesome    ",
    "repeated_padding": "SQL++ is awesome🙂", // ①
    "truncate_padding": "SQL++ is awesome1234",
    "truncate_string": "SQL++"
  }
]
```

1. The emoji counts as four bytes when calculating the size.

## RTRIM(in_str [, char])

### Description
Removes all trailing characters from a string.
The function removes all consecutive characters from the end of the string that match the specified characters and stops when it encounters a character that does not match any of the specified characters.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to convert to remove trailing characters from.
* **char**\
[Optional] A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that represents the characters to trim from the input string.
Each character in this string is trimmed from the input string -- you don’t need to delimit the characters to trim.
For example, specifying a character value of `"abc"` trims the characters `"a"`, `"b"` and `"c"` from the start of the string.

  If omitted, the default is whitespace: space `" "`, tab `"\t"`, newline `"\n"`, formfeed `"\f"`, or carriage return `"\r"`.

### Return Value
A string representing the input string with its trailing characters removed.

### Examples
**Query**

```sqlpp
SELECT RTRIM("SQL++ is awesome...", ".") as dots,
       RTRIM("SQL++ is awesome     ", " ") as explicit_spaces,
       RTRIM("SQL++ is awesome   \t") as implicit_spaces,
       RTRIM("SQL++ is awesome") as no_dots;
```

**Result**

```json
[
  {
    "dots": "SQL++ is awesome",
    "explicit_spaces": "SQL++ is awesome",
    "implicit_spaces": "SQL++ is awesome",
    "no_dots": "SQL++ is awesome"
  }
]
```

## SPLIT(in_str [, in_substr])

### Description
Splits the string into an array of substrings, based on the specified separator string.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to split.
* **in_substr**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the substring to split the input string on.

### Return Value
An array of strings containing the strings created by splitting the input string.

### Examples
**Query**

```sqlpp
SELECT SPLIT("SQL++ is awesome", " ") as explicit_spaces,
       SPLIT("SQL++ is awesome") as implicit_spaces,
       SPLIT("SQL++ is awesome", "is") as split_is;
```

**Result**

```json
[
  {
    "explicit_spaces": [
      "SQL++",
      "is",
      "awesome"
    ],
    "implicit_spaces": [
      "SQL++",
      "is",
      "awesome"
    ],
    "split_is": [
      "SQL++ ",
      " awesome"
    ]
  }
]
```

## SUBSTR(in_str, start_pos [, length])

### Description
Returns the substring (of given length) counting forward from the provided position.
The position is zero-based -- that is, the first position is 0.
If position is negative, it is counted from the end of the string; -1 is the last position in the string.

This function works with single bytes, not multi-byte characters.
For a variant of this function that works with multi-byte characters, see [MB_SUBSTR()](#mb_substrin_str-start_pos--length).

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to convert to extract the substring from.
* **start_pos**\
An integer, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to an integer, that is the start position of the substring.
* **length**\
[Optional; default is to capture to the end of the string]

  An integer, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to an integer, that is the length of the substring to extract.

### Return Value
A string representing the substring extracted from the input string.

### Examples
**Query**

```sqlpp
SELECT SUBSTR("🙂 SQL++ is awesome", 11) as rest_of_string,
       SUBSTR("🙂 SQL++ is awesome", 11, 1) as single_letter,
       SUBSTR("🙂 SQL++ is awesome", 0, 10) as ten_from_start;
```

**Result**

```json
[
  {
    "rest_of_string": "is awesome",
    "single_letter": "i",
    "ten_from_start": "🙂 SQL++"
  }
]
```

The emoji counts as four bytes for the starting position and the substring length.

## SUBSTR1(in_str, start_pos [, length])

### Description
Returns the substring (of given length) counting forward from the provided position.
The position is one-based -- that is, the first position is 1.
If position is negative, it is counted from the end of the string; 0 is the last position in the string.

This function works with single bytes, not multi-byte characters.
For a variant of this function that works with multi-byte characters, see [MB_SUBSTR1()](#mb_substr1in_str-start_pos--length).

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to convert to extract the substring from.
* **start_pos**\
An integer, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to an integer, that is the start position of the substring.
* **length**\
[Optional; default is to capture to the end of the string]

  An integer, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to an integer, that is the length of the substring to extract.

### Return Value
A string representing the substring extracted from the input string.

### Examples
**Query**

```sqlpp
SELECT SUBSTR1("🙂 SQL++ is awesome", 12) as rest_of_string,
       SUBSTR1("🙂 SQL++ is awesome", 12, 1) as single_letter,
       SUBSTR1("🙂 SQL++ is awesome", 0, 10) as ten_from_start;
```

**Result**

```json
[
  {
    "rest_of_string": "is awesome",
    "single_letter": "i",
    "ten_from_start": "🙂 SQL++"
  }
]
```

The emoji counts as four bytes for the starting position and the substring length.

## SUFFIXES(in_str)

### Description
Generates an array of all the suffixes of the input string.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to generate the suffixes of.

### Return Value
An array of strings containing all of the suffixes of the input string.

### Examples
**Query**

```sqlpp
SELECT SUFFIXES("SQL++ is awesome") as sqlpp;
```

**Result**

```json
[
  {
    "sqlpp": [
      "SQL++ is awesome",
      "QL++ is awesome",
      "L++ is awesome",
      "++ is awesome",
      "+ is awesome",
      " is awesome",
      "is awesome",
      "s awesome",
      " awesome",
      "awesome",
      "wesome",
      "esome",
      "some",
      "ome",
      "me",
      "e"
    ]
  }
]
```

The following example uses the `SUFFIXES()` function to index and query the airport names when a partial airport name is given.

For this example, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

**Query**

```sqlpp
CREATE INDEX autocomplete_airport_name
ON airport ( DISTINCT ARRAY array_element FOR array_element
IN SUFFIXES(LOWER(airportname)) END );
```

**Query**

```sqlpp
SELECT airportname
FROM airport
WHERE ANY array_element
IN SUFFIXES(LOWER(airportname)) SATISFIES array_element LIKE 'washing%' END;
```

**Result**

```json
[
  {
    "airportname": "Washington Dulles Intl"
  },
  {
    "airportname": "Baltimore Washington Intl"
  },
  {
    "airportname": "Ronald Reagan Washington Natl"
  },
  {
    "airportname": "Washington Union Station"
  }
]
```

This [blog](https://dzone.com/articles/a-couchbase-index-technique-for-like-predicates-wi) provides more information about this example.

## TITLE(in_str)

Alias for [INITCAP()](#initcapin_str).

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

## TRIM(in_str [, char])

### Description
Removes all leading and trailing characters from a string.
The function removes all consecutive characters from the beginning and end of the string that match the specified characters and stops when it encounters a character that does not match any of the specified characters.
This function is equivalent to calling [LTRIM()](#ltrimin_str--char) and [RTRIM()](#rtrimin_str--char) successively.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to convert to remove trailing and leading characters from.
* **char**\
[Optional] A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that represents the characters to trim from the input string.
Each character in this string is trimmed from the input string -- you don’t need to delimit the characters to trim.
For example, specifying a character value of `"abc"` trims the characters `"a"`, `"b"` and `"c"` from the start of the string.

  If omitted, the default is whitespace: space `" "`, tab `"\t"`, newline `"\n"`, formfeed `"\f"`, or carriage return `"\r"`.

### Return Value
A string representing the input string with trailing and leading characters removed.

### Examples
**Query**

```sqlpp
SELECT TRIM("...SQL++ is awesome...", ".") as dots,
       TRIM("     SQL++ is awesome     ", " ") as explicit_spaces,
       TRIM("\t   SQL++ is awesome     ") as implicit_spaces,
       TRIM("SQL++ is awesome") as no_dots;
```

**Result**

```json
[
  {
    "dots": "SQL++ is awesome",
    "explicit_spaces": "SQL++ is awesome",
    "implicit_spaces": "SQL++ is awesome",
    "no_dots": "SQL++ is awesome"
  }
]
```

## UPPER(in_str)

### Description
Converts all characters in the input string to upper case.

### Arguments
* **in_str**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to convert to upper case.

### Return Value
A string representing the input string converted to upper case.

### Examples
**Query**

```sqlpp
SELECT UPPER("SQL++ is awesome") as sqlpp;
```

**Result**

```json
[
  {
    "sqlpp": "SQL++ IS AWESOME"
  }
]
```

## URLDECODE(encoded_string)

### Description
Decodes the URL-encoded input string and returns the resulting plain string.

### Arguments
* **encoded_string**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to URL-decode.

### Return Value
The input string, with any percent encoding replaced by reserved characters.

If the input argument is MISSING, returns MISSING.
If the input argument is non-string, or if the argument is a string containing a single percent character `%`, returns NULL.

### Example
**Query**

```sqlpp
SELECT URLDECODE("SELECT%20name%20FROM%20%60travel-sample%60.inventory.hotel%20LIMIT%201%3B") AS decoded;
```
**Result**

```json
[
  {
    "decoded": "SELECT name FROM `travel-sample`.inventory.hotel LIMIT 1;"
  }
]
```

## URLENCODE(plain_string)

### Description
Returns the input string encoded for use in a URL.

### Arguments
* **plain_string**\
A string, or any valid [expression](n1ql-language-reference/index.adoc) which evaluates to a string, that is the string to URL-encode.

### Return Value
The input string, with any reserved characters replaced by percent encoding.

If the input argument is MISSING, returns MISSING.
If the input argument is non-string, returns NULL.

### Example
**Query**

```sqlpp
SELECT URLENCODE("SELECT name FROM `travel-sample`.inventory.hotel LIMIT 1;") AS encoded;
```
**Result**

```json
[
  {
    "encoded": "SELECT%20name%20FROM%20%60travel-sample%60.inventory.hotel%20LIMIT%201%3B"
  }
]
```

## UNCOMPRESS(`input_string`)

### Description

This function takes a `base64` encoded, compressed string as input and returns the original uncompressed string.

**📌 NOTE**\
This function is often used together with the [COMPRESS()](n1ql:n1ql-language-reference/stringfun.adoc#fn-str-compress) function, which compresses and encodes strings to `base64` format.

### Arguments

* **input_string**\
A `base64` encoded string that represents the compressed data.
It supports the following formats:
  * `zlib` compressed and `base64` encoded strings.
  * `gzip` compressed and `base64` encoded strings.
  * Execution plan strings stored in the `pln` array of AWR documents that are compressed and `base64` encoded.

### Return Value
A string that represents the decoded and uncompressed data.

### Examples

**Example 1: Uncompressing a `base64` encoded string**

**Query**

```sqlpp
SELECT UNCOMPRESS("eJwKycgsVsgsVijJSFVIzs8tKEotLk5NUSguKcrMSwcEAAD//5/2CwI=");
```

**Result**

```json
[
  {
    "$1": "This is the compressed string"
  }
]
```

**Example 2: Using UNCOMPRESS() and COMPRESS() together**

**Query**

```sqlpp
SELECT UNCOMPRESS(COMPRESS("This is the compressed string"));
```

**Result**

```json
[
  {
    "$1": "This is the compressed string"
  }
]
```

**Example 3: Uncompressing execution plan strings in AWR documents**

Consider a workload document with `pln` array as follows:

```json
"pln": [
                "0NM7AjQyYjVjNDMwZjIwNTFmNmIAX2RlZmF1bHQAE3RyYXZlbC1zYW1wbGUAJTA9AA==",
                "0NM7AjQyYjVjNDMwZjIwNTFmNmIAX2RlZmF1bHQAE3RyYXZlbC1zYW1wbGUAJTA9AA=="
      ]
```

**Query**

```sqlpp
SELECT UNCOMPRESS("0NM7AjQyYjVjNDMwZjIwNTFmNmIAX2RlZmF1bHQAE3RyYXZlbC1zYW1wbGUAJTA9AA==");
```
**Result**

```json
{
    "$1":
      "{ \"#operator\": \"Sequence\",
        \"~children\": [
          { \"#operator\": \"PrimaryScan3\",
            \"index_id\": \"42b5c430f2051f6b\",
            \"keyspace\": \"_default\"
          },
          { \"#operator\": \"Fetch\",
            \"keyspace\": \"travel-sample\"
          },
          { \"#operator\": \"InitialProject\" },
          { \"#operator\": \"Limit\" },
          { \"#operator\": \"Stream\" }
        ]
      }"
}
```
