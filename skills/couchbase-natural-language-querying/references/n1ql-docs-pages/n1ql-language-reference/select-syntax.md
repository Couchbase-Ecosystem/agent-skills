# SELECT Syntax

This page enables you to drill down through the syntax of a SELECT query.

```
select ::= <<select-term>> ( <<set-op>> <<select-term>> )* <<order-by-clause>>? <<limit-clause>>? <<offset-clause>>?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/select.png)

```
select-term ::= <<subselect>> | '(' <<select>> ')'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/select-term.png)

```
subselect ::= <<select-from>> | <<from-select>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/subselect.png)

```
select-from ::= <<with-clause>>? <<select-clause>> <<from-clause>>? <<let-clause>>? <<where-clause>>?
                <<group-by-clause>>? <<window-clause>>?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/select-from.png)

```
from-select ::= <<with-clause>>? <<from-clause>> <<let-clause>>? <<where-clause>>? <<group-by-clause>>?
                <<window-clause>>? <<select-clause>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/from-select.png)

```
set-op ::= ( 'UNION' | 'INTERSECT' | 'EXCEPT' ) 'ALL'?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/set-op.png)

## WITH Clause

```
with-clause ::= 'WITH' {alias}[alias] 'AS' '(' ( <<select>> | {expression}[expression] ) ')'
                 ( ',' {alias}[alias] 'AS' '(' ( <<select>> | {expression}[expression] ) ')' )*
```

![Syntax diagram](../../assets/images/n1ql-language-reference/with-clause.png)

```
alias ::= {identifier}[identifier]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/alias.png)

## SELECT Clause

```
select-clause ::= 'SELECT' {hints}[hint-comment]? <<projection>> <<exclude-clause>>?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/select-clause.png)

```
projection ::= ( 'ALL' | 'DISTINCT' )?
               ( <<result-expr>> ( ',' <<result-expr>> )* |
               ( 'RAW' | 'ELEMENT' | 'VALUE' ) {expression}[expr] ( 'AS'? {alias}[alias] )? )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/projection.png)

```
result-expr ::= ( ( <<path>> '.' )? '*' | {expression}[expr] ( 'AS'? {alias}[alias] )? )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/result-expr.png)

```
path ::= {identifier}[identifier] ( '[' {expression}[expr] ']' )* ( '.' {identifier}[identifier] ( '[' {expression}[expr] ']' )* )*
```

![Syntax diagram](../../assets/images/n1ql-language-reference/path.png)

```
exclude-clause ::= 'EXCLUDE' <<exclude-term>> ( ',' <<exclude-term>> )*
```

![Syntax diagram](../../assets/images/n1ql-language-reference/exclude-clause.png)

```
exclude-term ::= {identifier}[identifier] | {string-expression}[string-expr]
```
![Syntax diagram](../../assets/images/n1ql-language-reference/exclude-term.png)

## FROM Clause

```
from-clause ::= 'FROM' <<from-term>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/from-clause.png)

```
from-terms ::= ( <<from-keyspace>> | <<from-subquery>> | <<from-generic>> )
               ( <<join-clause>> | <<nest-clause>> | <<unnest-clause>> )*  <<comma-separated-join>>*
```

![Syntax diagram](../../assets/images/n1ql-language-reference/from-terms.png)

```
from-keyspace ::= <<keyspace-ref>> ( 'AS'? {alias}[alias] )? <<use-clause>>?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/from-keyspace.png)

```
keyspace-ref ::= <<keyspace-path>> | <<keyspace-partial>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/keyspace-ref.png)

```
keyspace-path ::= ( <<namespace>> ':' )? <<bucket>> ( '.' <<scope>> '.' <<collection>> )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/keyspace-path.png)

```
keyspace-partial ::= <<collection>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/keyspace-partial.png)

```
namespace ::= {identifier}[identifier]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/namespace.png)

```
bucket ::= {identifier}[identifier]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/keyspace.png)

```
scope ::= {identifier}[identifier]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/keyspace.png)

```
collection ::= {identifier}[identifier]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/keyspace.png)

```
from-subquery ::= <<subquery-expr>> 'AS'? {alias}[alias]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/from-subquery.png)

```
subquery-expr ::= '(' <<select>> ')'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/subquery-expr.png)

```
from-generic ::= {expression}[expr] ( 'AS' {alias}[alias] )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/generic-expr.png)

## JOIN Clause

```
join-clause ::= <<ansi-join-clause>> | <<lookup-join-clause>> | <<index-join-clause>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/join-clause.png)

### ANSI JOIN

```
ansi-join-clause ::= <<ansi-join-type>>? 'JOIN' <<ansi-join-rhs>> <<ansi-join-predicate>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/ansi-join-clause.png)

```
ansi-join-type ::= 'INNER' | ( 'LEFT' 'OUTER'? ) | ( 'RIGHT' 'OUTER'? )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/ansi-join-type.png)

```
ansi-join-rhs ::= <<rhs-keyspace>> | <<rhs-subquery>> | <<rhs-generic>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/ansi-join-rhs.png)

```
rhs-keyspace ::= <<keyspace-ref>> ( 'AS'? {alias}[alias] )? <<ansi-join-hints>>?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/rhs-keyspace.png)

```
rhs-subquery ::= <<subquery-expr>> 'AS'? {alias}[alias]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/rhs-subquery.png)

```
rhs-generic ::= {expression}[expr] ( 'AS'? {alias}[alias] )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/rhs-generic.png)

```
ansi-join-hints ::= <<use-hash-hint>> | <<use-nl-hint>> | <<multiple-hints>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/ansi-join-hints.png)

```
use-hash-hint ::= 'USE' <<use-hash-term>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/use-hash-hint.png)

```
use-hash-term ::= 'HASH' '(' ( 'BUILD' | 'PROBE' ) ')'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/use-hash-term.png)

```
use-nl-hint ::= 'USE' <<use-nl-term>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/use-nl-hint.png)

```
use-nl-term ::= 'NL'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/use-nl-term.png)

```
multiple-hints ::= 'USE' ( <<ansi-hint-terms>> <<other-hint-terms>> ) | ( <<other-hint-terms>> <<ansi-hint-terms>> )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/multiple-hints.png)

```
ansi-hint-terms ::= <<use-hash-term>> | <<use-nl-term>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/ansi-hint-terms.png)

```
other-hint-terms ::= <<use-index-term>> | <<use-keys-term>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/other-hint-terms.png)

```
ansi-join-predicate ::= 'ON' {expression}[expr]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/ansi-join-predicate.png)

### Lookup JOIN

```
lookup-join-clause ::= <<lookup-join-type>>? 'JOIN' <<lookup-join-rhs>> <<lookup-join-predicate>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/lookup-join-clause.png)

```
lookup-join-type ::= 'INNER' | ( 'LEFT' 'OUTER'? )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/lookup-join-type.png)

```
lookup-join-rhs ::= <<keyspace-ref>> ( 'AS'? {alias}[alias] )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/lookup-join-rhs.png)

```
lookup-join-predicate ::= 'ON' 'PRIMARY'? 'KEYS' {expression}[expr]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/lookup-join-predicate.png)

### Index JOIN

```
index-join-clause ::= <<index-join-type>>? 'JOIN' <<index-join-rhs>> <<index-join-predicate>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/index-join-clause.png)

```
index-join-type ::= 'INNER' | ( 'LEFT' 'OUTER'? )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/index-join-type.png)

```
index-join-rhs ::= <<keyspace-ref>> ( 'AS'? {alias}[alias] )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/index-join-rhs.png)

```
index-join-predicate ::= 'ON' 'PRIMARY'? 'KEY' {expression}[expr] 'FOR' {alias}[alias]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/index-join-predicate.png)

## NEST Clause

```
nest-clause ::= <<ansi-nest-clause>> | <<lookup-nest-clause>> | <<index-nest-clause>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/nest-clause.png)

### ANSI NEST

```
ansi-nest-clause ::= <<ansi-nest-type>>? 'NEST' <<ansi-nest-rhs>> <<ansi-nest-predicate>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/ansi-nest-clause.png)

```
ansi-nest-type ::= 'INNER' | ( 'LEFT' 'OUTER'? )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/ansi-nest-type.png)

```
ansi-nest-rhs ::= <<keyspace-ref>> ( 'AS'? {alias}[alias] )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/ansi-nest-rhs.png)

```
ansi-nest-predicate ::= 'ON' {expression}[expr]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/ansi-nest-predicate.png)

### Lookup NEST

```
lookup-nest-clause ::= <<lookup-nest-type>>? 'NEST' <<lookup-nest-rhs>> <<lookup-nest-predicate>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/lookup-nest-clause.png)

```
lookup-nest-type ::= 'INNER' | ( 'LEFT' 'OUTER'? )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/lookup-nest-type.png)

```
lookup-nest-rhs ::= <<keyspace-ref>> ( 'AS'? {alias}[alias] )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/lookup-nest-rhs.png)

```
lookup-nest-predicate ::= 'ON' 'KEYS' {expression}[expr]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/lookup-nest-predicate.png)

### Index NEST

```
index-nest-clause ::= <<index-nest-type>>? 'NEST' <<index-nest-rhs>> <<index-nest-predicate>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/index-nest-clause.png)

```
index-nest-type ::= 'INNER' | ( 'LEFT' 'OUTER'? )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/index-nest-type.png)

```
index-nest-rhs ::= <<keyspace-ref>> ( 'AS'? {alias}[alias] )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/index-nest-rhs.png)

```
index-nest-predicate ::= 'ON' 'KEY' {expression}[expr] 'FOR' {alias}[alias]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/index-nest-predicate.png)

## UNNEST Clause

```
unnest-clause ::= <<unnest-type>>? ( 'UNNEST' | 'FLATTEN' ) {expression}[expr] ( 'AS'? {alias}[alias] )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/unnest-clause.png)

```
unnest-type ::= 'INNER' | ( 'LEFT' 'OUTER'? )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/unnest-type.png)

## Comma-Separated Join

```
comma-separated-join ::= ',' ( <<rhs-keyspace>> | <<rhs-subquery>> | <<rhs-generic>> )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/comma-separated-join.png)

## USE Clause

```
use-clause ::= <<use-keys-clause>> | <<use-index-clause>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/use-clause.png)

```
use-keys-clause ::= 'USE' <<use-keys-term>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/use-keys-clause.png)

```
use-keys-term ::= 'PRIMARY'? 'KEYS' {expression}[expr]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/use-keys-term.png)

```
use-index-clause ::= 'USE' <<use-index-term>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/use-index-clause.png)

```
use-index-term ::= 'INDEX' '(' <<index-ref>> ( ',' <<index-ref>> )* ')'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/use-index-term.png)

```
index-ref ::= <<index-name>>? <<index-type>>?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/index-ref.png)

```
index-name ::= {identifier}[identifier]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/index-name.png)

```
index-type ::= 'USING' ( 'GSI' | 'FTS' )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/index-type.png)

## LET Clause

```
let-clause ::= 'LET' {alias}[alias] '=' {expression}[expr] ( ',' {alias}[alias] '=' {expression}[expr] )*
```

![Syntax diagram](../../assets/images/n1ql-language-reference/let-clause.png)

## WHERE Clause

```
where-clause ::= 'WHERE' <<cond>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/where-clause.png)

```
cond ::= {expression}[expr]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/cond.png)

## GROUP BY Clause

```
group-by-clause ::= 'GROUP' 'BY' {expression}[expr] ( ',' {expression}[expr] )* <<letting-clause>>? <<having-clause>>? | <<letting-clause>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/group-by-clause.png)

```
letting-clause ::= 'LETTING' {alias}[alias] '=' {expression}[expr] ( ',' {alias}[alias] '=' {expression}[expr] )*
```

![Syntax diagram](../../assets/images/n1ql-language-reference/letting-clause.png)

```
having-clause ::= 'HAVING' <<cond>>
```

![Syntax diagram](../../assets/images/n1ql-language-reference/having-clause.png)

## WINDOW Clause

```
window-clause ::= 'WINDOW' <<window-declaration>> ( ',' <<window-declaration>> )*
```

![Syntax diagram](../../assets/images/n1ql-language-reference/window-clause.png)

```
window-declaration ::= <<window-name>> 'AS' '(' <<window-definition>> ')'
```

![Syntax diagram](../../assets/images/n1ql-language-reference/window-declaration.png)

```
window-name ::= {identifier}[identifier]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/window-name.png)

```
window-definition ::= <<window-ref>>? <<window-partition-clause>>? <<window-order-clause>>?
                      <<window-frame-clause>>?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/window-definition.png)

```
window-ref ::= {identifier}[identifier]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/window-ref.png)

```
window-partition-clause ::= 'PARTITION' 'BY' {expression}[expr] ( ',' {expression}[expr] )*
```

![Syntax diagram](../../assets/images/n1ql-language-reference/window-partition-clause.png)

```
window-order-clause ::= 'ORDER' 'BY' <<ordering-term>> ( ',' <<ordering-term>> )*
```

![Syntax diagram](../../assets/images/n1ql-language-reference/window-order-clause.png)

```
window-frame-clause ::= ( 'ROWS' | 'RANGE' | 'GROUPS' ) <<window-frame-extent>> <<window-frame-exclusion>>?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/window-frame-clause.png)

```
window-frame-extent ::= 'UNBOUNDED' 'PRECEDING' | {number}[valexpr] 'PRECEDING' | 'CURRENT' 'ROW' |
                        'BETWEEN' ( 'UNBOUNDED' 'PRECEDING' | 'CURRENT' 'ROW' |
                                     {number}[valexpr] ( 'PRECEDING' | 'FOLLOWING' ) )
                            'AND' ( 'UNBOUNDED' 'FOLLOWING' | 'CURRENT' 'ROW' |
                                     {number}[valexpr] ( 'PRECEDING' | 'FOLLOWING' ) )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/window-frame-extent.png)

```
window-frame-exclusion ::= 'EXCLUDE' ( 'CURRENT' 'ROW' | 'GROUP' | 'TIES' | 'NO' 'OTHERS' )
```

![Syntax diagram](../../assets/images/n1ql-language-reference/window-frame-exclusion.png)

## ORDER BY Clause

```
order-by-clause ::= 'ORDER' 'BY' <<ordering-term>> ( ',' <<ordering-term>> )*
```

![Syntax diagram](../../assets/images/n1ql-language-reference/order-by-clause.png)

```
ordering-term ::= {expression}[expr] ( 'ASC' | 'DESC' )? ( 'NULLS' ( 'FIRST' | 'LAST' ) )?
```

![Syntax diagram](../../assets/images/n1ql-language-reference/ordering-term.png)

## LIMIT Clause

```
limit-clause ::= 'LIMIT' {expression}[expr]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/limit-clause.png)

## OFFSET Clause

```
offset-clause ::= 'OFFSET' {expression}[expr]
```

![Syntax diagram](../../assets/images/n1ql-language-reference/offset-clause.png)

## Related Links

* [Conventions](n1ql-language-reference/conventions.adoc)
