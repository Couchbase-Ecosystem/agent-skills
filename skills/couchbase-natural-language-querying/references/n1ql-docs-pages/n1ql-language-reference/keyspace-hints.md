# Keyspace Hints

Keyspace hints apply to a specific keyspace.

A keyspace hint is a type of [optimizer hint](n1ql-language-reference/optimizer-hints.adoc).
Keyspace hints include _index_ hints, which enable you to specify indexes, and _join_ hints, which enable you to specify join methods.

For each keyspace hint, you must specify the keyspace or keyspaces that the hint applies to.
If a keyspace is given an explicit alias in the query, then the hint must refer to the explicit alias, not the keyspace name. This is to avoid confusion in situations where the same keyspace can be used multiple times (with different aliases) in the same query.

If the keyspace is _not_ given an explicit alias in the query, the hint must refer to the keyspace using the keyspace name.
(If the keyspace name is a dotted path, the hint must refer to the keyspace using its implicit alias, which is the last component in the keyspace path.)

There are two possible formats for each optimizer hint: simple syntax and JSON syntax.
Note that you cannot mix simple syntax and JSON syntax in the same hint comment.

**💡 TIP**\
While most keyspace hints guide the optimizer to use certain indexes or join methods, you can also use negative hints to instruct the optimizer what not to use.
For more information, see [Negative Keyspace Hints](n1ql-language-reference/negative-keyspace-hints.adoc).

## INDEX

This hint directs the optimizer to consider one or more specified secondary indexes.
If not specified, the optimizer selects the optimal available index.

### Simple Syntax

```ebnf
gsi-hint-simple ::= 'INDEX' '(' keyspace index* ')'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/gsi-hint-simple.png)

With the simple syntax, this hint specifies a single keyspace expression, and zero, one, or more indexes.
You can use this hint multiple times within the hint comment to specify hints for more than one keyspace.

#### Arguments

* **keyspace**\
The keyspace or alias to which this hint applies.
* **index**\
A secondary index that the optimizer should consider for the given keyspace.
This argument is optional; if omitted, the optimizer considers _all_ secondary indexes available in the given keyspace.

### JSON Syntax

```ebnf
gsi-hint-json ::= '"index"' ':' ( index-array | index-object )
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/gsi-hint-json.png)

With the JSON syntax, this hint takes the form of an `index` property.
You may only use this property once within the hint comment.
The value of this property may be an [Index Array](#index-array) or an [Index Object](#index-object).

#### Index Array

```ebnf
index-array ::= '[' index-object ( ',' index-object )* ']'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/index-array.png)

Use this array to specify indexes for multiple keyspaces.
Each element must be an [Index Object](#index-object).

#### Index Object

```ebnf
index-object ::= '{' keyspace-property ',' indexes-property '}'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/index-object.png)

Use this object to specify indexes for a single keyspace.
It must contain a [Keyspace Property](#keyspace-property) and an [Indexes Property](#indexes-property).
The order of the properties within the object is not significant.

#### Keyspace Property

```ebnf
keyspace-property ::= ( '"keyspace"' | '"alias"' ) ':' '"' keyspace '"'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-property.png)

Synonym for `"keyspace"`: `"alias"`

The value of this property is the keyspace or alias to which this hint applies.

#### Indexes Property

```ebnf
indexes-property ::= '"indexes"' ':' ( 'null'
                                     | '"' index '"'
                                     | '[' '"' index '"' ( ',' '"' index '"' )* ']' )
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/indexes-property.png)

The value of this property may be:

* **`null`**\
The optimizer considers all secondary indexes available in the given keyspace.
* **An _index_ string**\
A secondary index that the optimizer should consider for the given keyspace.
* **An array of _index_ strings**\
An array of secondary indexes that the optimizer should consider for the given keyspace.
### Examples

For the examples in this section, it is assumed that the cost-based optimizer is active, and all optimizer statistics are up-to-date.

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-index-opt"></a>**Optimized index selection**

The following query does not include an index hint.

**Query**

```sqlpp
SELECT id
FROM route
WHERE sourceairport = "SFO"
LIMIT 1;
```

If you examine the plan for this query, you can see that the optimizer has selected the index `def_inventory_route_sourceairport`, which is installed with the travel sample dataset.

**Explain plan**


{
  "#operator": "IndexScan3",
  "bucket": "travel-sample",
  "index": "def_inventory_route_sourceairport",
```

<a name="ex-index-hint"></a>**INDEX hint**

The following query hints that the optimizer should select the index `def_inventory_route_route_src_dst_day` for the keyspace `route`.

**Query**

```sqlpp
SELECT /*+ INDEX (route def_inventory_route_route_src_dst_day) */ id -- ①
FROM route -- ②
WHERE sourceairport = "SFO"
LIMIT 1;
```

1. The keyspace is not given an explicit alias in the query.
You must therefore refer to the keyspace using the keyspace name or implicit alias -- in this case, `route`.
2. The implicit alias is the last element in the keyspace path.

If you examine the plan for this query, you can see that the query uses the suggested index.

**Explain plan**


"scan": {
  "#operator": "IndexScan3",
  "bucket": "travel-sample",
  "index": "def_inventory_route_route_src_dst_day",
```

**INDEX hint in an UPDATE statement**

The following query hints that the optimizer should use the index `def_inventory_airport_city` for the keyspace `airport` when updating documents.

```sqlpp
UPDATE /*+ INDEX(airport def_inventory_airport_city) */ airport 
SET updated = true 
WHERE city = "San Jose";
```

If you examine the plan for this query, you can see that the query uses the suggested index.

**Explain plan**


"#operator": "IndexScan3",
"bucket": "travel-sample",
"index": "def_inventory_airport_city",
"index_id": "34798b782a732137",
```

### Legacy Equivalent

This hint is equivalent to the legacy `USE INDEX (USING GSI)` clause.
For more details, refer to [USE INDEX Clause](n1ql-language-reference/hints.adoc#use-index-clause).

Note that you cannot use a hint comment and the `USE` clause to specify optimizer hints on the same keyspace.
If you do this, the hint comment and the `USE` clause are marked as erroneous and ignored by the optimizer.

## INDEX_ALL

This hint directs the optimizer to consider all specified secondary indexes.

When you apply the hint on a keyspace, the optimizer performs an intersect scan across all specified indexes.
This process differs from a typical intersect scan and does not end early even when enough document IDs are found.
Instead, it waits for all index scans to complete before intersecting the documents IDs.

Furthermore, the hint operates on an all-or-nothing basis.
The optimizer uses this hint only if all specified indexes are usable.
If even one of the indexes is not usable (for example, due to the lack of necessary predicates on index keys), the optimizer ignores the hint entirely and reverts to the standard index selection process.
It does not attempt to use only a subset of the indexes.

If you do not specify this hint, the optimizer selects the optimal available index.

<dl><dt><strong>📌 NOTE</strong></dt><dd>


To use the INDEX_ALL hint effectively:

* You must specify at least two indexes for the hint to be valid.
* You can only use GSI indexes.
The hint does not support FTS indexes.
* You cannot mix INDEX_ALL with other index hints for the same keyspace.
It must be the only index hint present.
* You can use the hint on a keyspace on the right-hand side of an ANSI JOIN or ANSI NEST.
* You cannot use it on a keyspace on the inner side of a legacy JOIN or NEST, like LOOKUP JOIN/NEST or INDEX JOIN/NEST.
* INDEX_COMBINE is an alias for INDEX_ALL.
You can use either as the hint keyword.
* Negative hints are not available for INDEX_ALL.
</dd></dl>

### Simple Syntax

```ebnf
gsi-all-hint-simple ::= 'INDEX_ALL' '(' keyspace index* ')'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/gsi-all-hint-simple.png)

With the simple syntax, this hint specifies a single keyspace expression along with zero, one, or more indexes.
You can use this hint multiple times within the hint comment to specify hints for more than one keyspace.

**📌 NOTE**\
You must specify at least two indexes.
The hint is invalid if you provide zero or one index.

#### Arguments

* **keyspace**\
The keyspace or alias to which this hint applies.
* **index**\
A secondary index that the optimizer should consider for the given keyspace.
This argument is optional.
If omitted, the optimizer considers all secondary indexes available in the given keyspace.

### JSON Syntax

```ebnf
gsi-all-hint-json ::= '"index_all"' ':' ( index-array | index-object )
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/gsi-all-hint-json.png)

With the JSON syntax, this hint takes the form of an `index_all` property.
You may only use this property once within the hint comment.
The value of this property may be an [Index Array](#index-array) or an [Index Object](#index-object).

#### Index Array

```ebnf
index-array ::= '[' index-object ( ',' index-object )* ']'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/index-array.png)

Use this array to specify indexes for multiple keyspaces.
Each element must be an [Index Object](#index-object).

#### Index Object

```ebnf
index-object ::= '{' keyspace-property ',' indexes-property '}'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/index-object.png)

Use this object to specify indexes for a single keyspace.
It must contain a [Keyspace Property](#keyspace-property) and an [Indexes Property](#indexes-property).
The order of the properties within the object is not significant.

#### Keyspace Property

```ebnf
keyspace-property ::= ( '"keyspace"' | '"alias"' ) ':' '"' keyspace '"'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-property.png)

Synonym for `"keyspace"`: `"alias"`

The value of this property is the keyspace or alias to which this hint applies.

#### Indexes Property

```ebnf
indexes-property ::= '"indexes"' ':' ( 'null'
                                     | '"' index '"'
                                     | '[' '"' index '"' ( ',' '"' index '"' )* ']' )
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/indexes-property.png)

The value of this property may be:

* **null**\
The optimizer considers all secondary indexes available in the given keyspace.
* **An index string**\
A secondary index that the optimizer should consider for the given keyspace.
* **An array of index strings**\
An array of secondary indexes that the optimizer should consider for the given keyspace.

### Examples

For the examples in this section, it is assumed that the cost-based optimizer is active, and all optimizer statistics are up-to-date.

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-index-all-opt"></a>**Optimized index selection**

The following query does not include an index hint.

**Query**

```sqlpp
SELECT id
FROM route
WHERE sourceairport = "SFO"
LIMIT 1;
```

If you examine the plan for this query, you can see that the optimizer has selected the index `def_inventory_route_sourceairport`, which is installed with the travel sample dataset.

**Explain plan**


{
  "#operator": "IndexScan3",
  "bucket": "travel-sample",
  "index": "def_inventory_route_sourceairport",
```

<a name="ex-index-all-hint"></a>**INDEX_ALL hint**

The following query hints that the optimizer should select indexes `def_inventory_route_route_src_dst_day` and `def_inventory_route_sourceairport` for the keyspace `route`.

**Query**

```sqlpp
SELECT /*+ INDEX_ALL(route def_inventory_route_route_src_dst_day def_inventory_route_sourceairport) */ -- ①
       id 
FROM route -- ②
WHERE sourceairport = "SFO"
LIMIT 1;
```
1. The keyspace is not given an explicit alias in the query.
You must therefore refer to the keyspace using the keyspace name or implicit alias -- in this case, `route`.
2. The implicit alias is the last element in the keyspace path.

If you examine the plan for this query, you can see that the query uses the suggested index.

**Explain plan**


    "scan": {
        "#operator": "IndexScan3",
        "bucket": "travel-sample",
        "index": "def_inventory_route_route_src_dst_day",
        "index_id": "6c6a9ea47d763bf1",
        "index_projection": {
            "primary_key": true
        },
        "keyspace": "route",
        "namespace": "default",
        "optimizer_estimates": {
            "cardinality": 1,
            "cost": 12.172539443450269,
            "fr_cost": 12.172539443450269,
            "size": 11
        },
        "scope": "inventory",
        "spans": [{
            "exact": true,
            "range": [{
                "high": "\"SFO\"",
                "inclusion": 3,
                "index_key": "`sourceairport`",
                "low": "\"SFO\""
            }]
        }],
        "using": "gsi"
    }
},
{
    "#operator": "IndexScan3",
    "bucket": "travel-sample",
    "index": "def_inventory_route_sourceairport",
    "index_id": "f1b4c81456c850f0",
    "index_projection": {
        "primary_key": true
    },
    "keyspace": "route",
    "namespace": "default",
    "optimizer_estimates": {
        "cardinality": 1,
        "cost": 12.171488093767262,
        "fr_cost": 12.171488093767262,
        "size": 11
    },
    "scope": "inventory",
    "spans": [{
        "exact": true,
        "range": [{
            "high": "\"SFO\"",
            "inclusion": 3,
            "index_key": "`sourceairport`",
            "low": "\"SFO\""
        }]
    }],
    "using": "gsi"
}
```

## INDEX_FTS

This hint directs the optimizer to consider one or more specified full-text indexes.
If not specified, the optimizer selects the optimal available index.

### Simple Syntax

```ebnf
fts-hint-simple ::= 'INDEX_FTS' '(' keyspace index* ')'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/fts-hint-simple.png)

With the simple syntax, this hint specifies a single keyspace expression; and zero, one, or more indexes.
You can use this hint multiple times within the hint comment to specify hints for more than one keyspace.

#### Arguments

* **keyspace**\
The keyspace or alias to which this hint applies.
* **index**\
A full-text index that the optimizer should consider for the given keyspace.
This argument is optional; if omitted, the optimizer considers _all_ full-text indexes available in the given keyspace.

### JSON Syntax

```ebnf
fts-hint-json ::= '"index_fts"' ':' ( index-array | index-object )
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/fts-hint-json.png)

With the JSON syntax, this hint takes the form of an `index_fts` property.
You may only use this property once within the hint comment.
The value of this property may be an [Index Array](#index-array) or an [Index Object](#index-object).

#### Index Array

```ebnf
index-array ::= '[' index-object ( ',' index-object )* ']'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/index-array.png)

Use this array to specify indexes for multiple keyspaces.
Each element must be an [Index Object](#index-object).

#### Index Object

```ebnf
index-object ::= '{' keyspace-property ',' indexes-property '}'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/index-object.png)

Use this object to specify indexes for a single keyspace.
It must contain a [Keyspace Property](#keyspace-property) and an [Indexes Property](#indexes-property).
The order of the properties within the object is not significant.

#### Keyspace Property

```ebnf
keyspace-property ::= ( '"keyspace"' | '"alias"' ) ':' '"' keyspace '"'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-property.png)

Synonym for `"keyspace"`: `"alias"`

The value of this property is the keyspace or alias to which this hint applies.

#### Indexes Property

```ebnf
indexes-property ::= '"indexes"' ':' ( 'null'
                                     | '"' index '"'
                                     | '[' '"' index '"' ( ',' '"' index '"' )* ']' )
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/indexes-property.png)

The value of this property may be:

* **`null`**\
The optimizer considers all full-text indexes available in the given keyspace.
* **_index_ string**\
A full-text index that the optimizer should consider for the given keyspace.
* **_index_ array**\
An array of full-text indexes that the optimizer should consider for the given keyspace.

### Examples

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-index-fts-hint"></a>**INDEX_FTS hint**

This example specifies that the optimizer should prefer any suitable FTS index, without specifying an index by name.
To qualify for this query, there must be an FTS index on `state` and `type`, using the keyword analyzer.
(Or alternatively, an FTS index on `state`, with a custom type mapping on "hotel".)

**Query**

```sqlpp
SELECT /*+ INDEX_FTS (hotel) */
       META().id
FROM hotel
WHERE state = "Corse" OR state = "California";
```

All FTS indexes are considered.
If a qualified FTS index is available, it is selected for the query.
If none of the available FTS indexes are qualified, the available GSI indexes are considered instead.

### Legacy Equivalent

This hint is equivalent to the legacy `USE INDEX (USING FTS)` clause.
For more details, refer to [USE INDEX Clause](n1ql-language-reference/hints.adoc#use-index-clause).

Note that you cannot use a hint comment and the `USE` clause to specify optimizer hints on the same keyspace.
If you do this, the hint comment and the `USE` clause are marked as erroneous and ignored by the optimizer.

## USE_NL

This hint directs the optimizer to consider a nested-loop join for the specified keyspace.
This hint must be specified on the keyspace on the right-hand side of the join.
If not specified, the optimizer selects the optimal join method.

**📌 NOTE**\
This hint is only available in [SELECT](n1ql-language-reference/selectclause.adoc) and [MERGE](n1ql-language-reference/merge.adoc) statements.

### Simple Syntax

```ebnf
nl-hint-simple ::= 'USE_NL' '(' ( keyspace )+ ')'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/nl-hint-simple.png)

With the simple syntax, this hint specifies one or more keyspaces.
You may also use this hint multiple times within the hint comment.

#### Arguments

* **keyspace**\
The keyspace or alias to which this hint applies.

### JSON Syntax

```ebnf
nl-hint-json ::= '"use_nl"' ':' ( keyspace-array | keyspace-object )
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/nl-hint-json.png)

With the JSON syntax, this hint takes the form of a `use_nl` property.
You may only use this property once within the hint comment.
The value of this property may be a [Keyspace Array](#keyspace-array) or a [Keyspace Object](#keyspace-object).

#### Keyspace Array

```ebnf
keyspace-array ::= '[' keyspace-object ( ',' keyspace-object )* ']'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-array.png)

Use this array to apply the hint to multiple keyspaces.
Each element must be a [Keyspace Object](#keyspace-object).

#### Keyspace Object

```ebnf
keyspace-object ::= '{' keyspace-property '}'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-object.png)

Use this object to apply the hint to a single keyspace.
It must contain a [Keyspace Property](#keyspace-property).

#### Keyspace Property

```ebnf
keyspace-property ::= ( '"keyspace"' | '"alias"' ) ':' '"' keyspace '"'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-property.png)

Synonym for `"keyspace"`: `"alias"`

The value of this property is the keyspace or alias to which this hint applies.

### Examples

For the examples in this section, it is assumed that the cost-based optimizer is active, and all optimizer statistics are up-to-date.

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-use-nl-opt"></a>**Optimized join method selection**

The following query does not include a join hint.

**Query**

```sqlpp
SELECT a.airportname AS airport, r.id AS route
FROM route AS r,
     airport AS a
WHERE a.faa = r.sourceairport
  AND r.sourceairport = "SFO"
LIMIT 4;
```

If you examine the plan for this query, you can see that the optimizer has selected the hash join method.

**Explain plan**


{
  "#operator": "HashJoin",
```

<a name="ex-use-nl-hint"></a>**USE_NL hint**

The following query is equivalent to the one in the [Optimized join method selection](#ex-use-nl-opt) example, but includes a nested-loop join hint.

**Query**

```sqlpp
SELECT /*+ USE_NL (a) */ -- ①
       a.airportname AS airport, r.id AS route
FROM route AS r,
     airport AS a -- ②
WHERE a.faa = r.sourceairport
  AND r.sourceairport = "SFO"
LIMIT 4;
```

1. The keyspace is given an explicit alias in the query.
You must therefore refer to the keyspace using the explicit alias.
2. In this case, the explicit alias is `a`.

If you examine the plan text for this query, you can see that the query uses the suggested join method.

**Explain plan**


{
  "#operator": "NestedLoopJoin",
```

### Legacy Equivalent

This hint is equivalent to the legacy `USE NL` clause.
For more details, refer to [USE NL Clause](n1ql-language-reference/join.adoc#use-nl-hint).

Note that you cannot specify optimizer hints and the `USE` clause on the same keyspace in the same query.
If you do this, the optimizer hints and `USE` clause are both marked as erroneous and ignored by the optimizer.

## USE_HASH

{enterprise}

This hint directs the optimizer to consider a hash join for the specified keyspace.
This hint must be specified on the keyspace on the right-hand side of the join.
If not specified, the optimizer selects the optimal join method.

A hash join has two sides: a **build** side and a **probe** side.
The build side of the join is used to create an in-memory hash table.
The probe side uses that table to find matches and perform the join.
Typically, this means you want the build side to be used on the smaller of the two sets.

This hint enables you specify whether the right side of the join should be the build side or the probe side.
If you specify that the right side of the join is the build side, then the left side will be the probe side, and vice versa.

<dl><dt><strong>📌 NOTE</strong></dt><dd>

* This hint is only available in [SELECT](n1ql-language-reference/selectclause.adoc) and [MERGE](n1ql-language-reference/merge.adoc) statements.
* For Couchbase Server Community Edition (CE), only nested-loop join is considered by the optimizer, and any specified `USE_HASH` hint will be silently ignored.
</dd></dl>

### Simple Syntax

```ebnf
hash-hint-simple ::= 'USE_HASH' '(' ( keyspace ( '/' ( 'BUILD' | 'PROBE' ) )? )+ ')'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/hash-hint-simple.png)

With the simple syntax, this hint specifies one or more keyspaces.
For each keyspace, you may also add a slash, followed by an option.
You may also use this hint multiple times within the hint comment.

#### Arguments

* **keyspace**\
The keyspace or alias to which this hint applies.

#### Options

* **/BUILD**\
The specified keyspace is to be used as the build side of the join.
* **/PROBE**\
The specified keyspace is to be used as the probe side of the join.

If you omit the option (including the slash), the optimizer determines whether the specified keyspace is to be used as the build side or the probe side of the join, based on the estimated cardinality of both sides.

### JSON Syntax

```ebnf
hash-hint-json ::= '"use_hash"' ':' ( hash-array | hash-object )
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/hash-hint-json.png)

With the JSON syntax, this hint takes the form of a `use_hash` property.
You may only use this property once within the hint comment.
The value of this property may be a [Hash Array](#hash-array) or a [Hash Object](#hash-object).

#### Hash Array

```ebnf
hash-array ::= '[' hash-object ( ',' hash-object )* ']'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/hash-array.png)

Use this array to apply the hint to multiple keyspaces.
Each element must be a [Hash Object](#hash-object).

#### Hash Object

```ebnf
hash-object ::= '{' keyspace-property ( "," option-property )? '}'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/hash-object.png)

Use this object to apply the hint to a single keyspace.
It must contain a [Keyspace Property](#keyspace-property) and an optional [Option Property](#option-property).
The order of the properties within the object is not significant.

#### Keyspace Property

```ebnf
keyspace-property ::= ( '"keyspace"' | '"alias"' ) ':' '"' keyspace '"'
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-property.png)

Synonym for `"keyspace"`: `"alias"`

The value of this property is the keyspace or alias to which this hint applies.

#### Option Property

```ebnf
option-property ::= '"option"' ':' ( '"build"' | '"probe"' | 'null' )
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/option-property.png)

The value of this property may be:

* **`"build"`**\
The specified keyspace is to be used as the build side of the join.
* **`"probe"`**\
The specified keyspace is to be used as the probe side of the join.
* **`null`**\
The optimizer determines whether the specified keyspace is to be used as the build side or the probe side of the join, based on the estimated cardinality of both sides.

Similarly, if you omit this property entirely, the optimizer determines whether the specified keyspace is to be used as the build side or the probe side of the join.

### Examples

For the examples in this section, it is assumed that the cost-based optimizer is active, and all optimizer statistics are up-to-date.

To try the examples in this section, set the query context to the `inventory` scope in the travel sample dataset.
For more information, see [Query Context](n1ql:n1ql-intro/queriesandresults.adoc#query-context).

<a name="ex-use-hash-opt"></a>**Optimized join method selection**

The following query does not include a join hint.

**Query**

```sqlpp
SELECT COUNT(1) AS Total_Count
FROM route rte
INNER JOIN airline aline
ON rte.airlineid = META(aline).id;
```

If you examine the plan for this query, you can see that the optimizer has selected to use the hash join method, and to put the `aline` keyspace on the build side of the join.

**Explain plan**


{
  "#operator": "HashJoin",
  "build_aliases": [
    "aline"
  ],
  "build_exprs": [
    "cover ((meta(`aline`).`id`))"
  ],
  "on_clause": "(((`rte`.`airlineid`) = cover ((meta(`aline`).`id`))))",
// ...
  "probe_exprs": [
    "(`rte`.`airlineid`)"
  ],
```

<a name="ex-use-hash-probe-hint"></a>**USE_HASH with PROBE**

The following query is equivalent to the one in the [Optimized join method selection](#ex-use-hash-opt) example, but specifies that the keyspace `aline` is to be joined (with `rte`) using a hash join, and `aline` is used as the probe side of the hash join.

**Query -- simple syntax**

```sqlpp
SELECT /*+ USE_HASH (aline/PROBE) */
       COUNT(1) AS Total_Count
FROM route rte
INNER JOIN airline aline
ON rte.airlineid = META(aline).id;
```

If you examine the explain plan for this query, you can see that the query uses the hash join method as suggested, with the `aline` keyspace on the probe side of the join.

**Explain plan**

n
{
  "#operator": "HashJoin",
  "build_aliases": [
    "rte"
  ],
  "build_exprs": [
    "(`rte`.`airlineid`)"
  ],
  "on_clause": "(((`rte`.`airlineid`) = cover ((meta(`aline`).`id`))))",
// ...
  "probe_exprs": [
    "cover ((meta(`aline`).`id`))"
  ],
```

<a name="ex-use-hash-build-hint"></a>**USE_HASH with BUILD**

This is effectively the same query as the [USE_HASH with PROBE](#ex-use-hash-probe-hint) example, except the two keyspaces are switched, and here the `BUILD` option is used, indicating the hash join should use `rte` as the build side.

**Query**

```sqlpp
SELECT /*+ { "use_hash": { "keyspace": "rte", "option": "build" } } */
       COUNT(1) AS Total_Count
FROM airline aline
INNER JOIN route rte
ON (rte.airlineid = META(aline).id);
```

If you examine the explain plan for this query, you can see that the query uses the hash join method as suggested, with the `rte` keyspace on the build side.

**Explain plan**

n
{
  "#operator": "HashJoin",
  "build_aliases": [
    "rte"
  ],
  "build_exprs": [
    "(`rte`.`airlineid`)"
  ],
  "on_clause": "(((`rte`.`airlineid`) = cover ((meta(`aline`).`id`))))",
// ...
  "probe_exprs": [
    "cover ((meta(`aline`).`id`))"
  ],
```

<a name="ex-use-hash-null-hint"></a>**USE_HASH with optimizer**

This is the same query as the [USE_HASH with PROBE](#ex-use-hash-probe-hint) example, but the hint does not specify whether the `aline` keyspace should be on the probe side or the build side of the join.

**Query -- JSON syntax**

```sqlpp
SELECT /*+ USE_HASH (aline) */
       COUNT(1) AS Total_Count
FROM route rte
INNER JOIN airline aline
ON rte.airlineid = META(aline).id;
```

If you examine the explain plan for this query, you can see that the query uses the hash join method as suggested, but the optimizer has selected to put the `aline` keyspace on the build side of the join.

**Explain plan**


{
  "#operator": "HashJoin",
  "build_aliases": [
    "aline"
  ],
  "build_exprs": [
    "cover ((meta(`aline`).`id`))"
  ],
  "on_clause": "(((`rte`.`airlineid`) = cover ((meta(`aline`).`id`))))",
// ...
  "probe_exprs": [
    "(`rte`.`airlineid`)"
  ],
```

### Legacy Equivalent

This hint is equivalent to the legacy `USE HASH` clause.
For more details, refer to [USE HASH Clause](n1ql-language-reference/join.adoc#use-hash-hint).

Note that you cannot specify both optimizer hints and the `USE` clause on the same keyspace.
If you do this, the optimizer hints and the `USE` clause are both marked as erroneous and ignored by the optimizer.

## Related Links

* [n1ql-language-reference/cost-based-optimizer.adoc](n1ql-language-reference/cost-based-optimizer.adoc)
* [n1ql-language-reference/optimizer-hints.adoc](n1ql-language-reference/optimizer-hints.adoc)
* [n1ql-language-reference/query-hints.adoc](n1ql-language-reference/query-hints.adoc)
* [n1ql-language-reference/negative-keyspace-hints.adoc](n1ql-language-reference/negative-keyspace-hints.adoc)
