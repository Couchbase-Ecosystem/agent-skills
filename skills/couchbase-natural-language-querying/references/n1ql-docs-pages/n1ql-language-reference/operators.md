# Operators Overview

Operators perform a specific operation on the input values or expressions.

{sqlpp} provides a full set of operators that you can use within its statements.
Here are the categories of {sqlpp} operators:

* [Arithmetic Operators](n1ql-language-reference/arithmetic.adoc) to perform basic mathematical operations (such as addition, subtraction, multiplication, and divisions) on numbers.
* [Collection Operators](n1ql-language-reference/collectionops.adoc) to evaluate expressions on collections or objects.
* [Comparison Operators](n1ql-language-reference/comparisonops.adoc) to compare two expressions.
* [Conditional Operators](n1ql-language-reference/conditionalops.adoc) to evaluate conditional logic in an expression.
* [Construction Operators](n1ql-language-reference/constructionops.adoc) to construct arrays and objects.
* [Logical Operators](n1ql-language-reference/logicalops.adoc) to combine operators using Boolean logic.
* [Nested Operators and Expressions](n1ql-language-reference/nestedops.adoc) to access nested elements and embedded arrays.
* [Sequence Operators](n1ql-language-reference/sequenceops.adoc) to access values in a sequence.
* [String Operators](n1ql-language-reference/stringops.adoc) to concatenate two expressions.

## Operator Precedence

{sqlpp} supports the use of parentheses to group operators and expressions.
Expressions enclosed in parentheses are evaluated first.

The following table shows operator precedence level.
An operator at a higher level is evaluated before an operator at a lower level.

| Evaluation Order | Operator |
| --- | --- |
| 1 | `CASE` |
| 2 | `.` (period) |
| 3 | `[ ]` (left and right bracket) |
| 4 | `-` (unary) |
| 5 | `*` (multiply), `/` (divide), `%` (modulo) |
| 6 | `+`, `-` (binary) |
| 7 | `IS` |
| 8 | `IN` |
| 9 | `BETWEEN` |
| 10 | `LIKE` |
| 11 | `<` (less than, `\<=` (less than or equal to, `>` (greater than), and `\=>` (equal to or greater than) |
| 12 | `=` (equal to) , `==` (equal to), `<>` (less than or greater than), `!=` (not equal to) |
| 13 | `NOT` |
| 15 | `AND` |
| 16 | `OR` |
