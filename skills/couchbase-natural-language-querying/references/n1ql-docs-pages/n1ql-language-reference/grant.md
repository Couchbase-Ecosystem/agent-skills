# GRANT

The GRANT statement allows granting any RBAC roles to a specific user or group.

Roles can be of the following two types:

* **simple**\
Roles which apply generically to all keyspaces or resources in the cluster.

  For example: `cluster_admin` or `bucket_admin`
* **parameterized by a keyspace**\
Roles which are defined for the context of the specified keyspace only.
Specify the keyspace name after the keyword ON.

  For example: `pass:c[data_reader ON `travel-sample`]`\
  or `pass:c[query_select ON `travel-sample`.`inventory`.`airline`]`

**📌 NOTE**\
Only Full Administrators can run the GRANT statement.
For more details about user roles, see [Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
grant ::= grant-user | grant-group
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/grant.png)

```ebnf
grant-user ::= 'GRANT' role ( ',' role )* ( 'ON' keyspace-ref ( ',' keyspace-ref )* )?
          'TO' ( 'USER' | 'USERS' )? user ( ',' user )*
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/grant-user.png)

```ebnf
grant-group ::= 'GRANT' role ( ',' role )* ( 'ON' keyspace-ref ( ',' keyspace-ref )* )?
          'TO' ( 'GROUP' | 'GROUPS' ) group ( ',' group )*          
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/grant-group.png)

* **role**\
One of the [RBAC role names predefined](learn:security/authorization-overview.adoc) by Couchbase Server.

  For the following roles, you can use their short forms as well:
  * `query_select` → `select`
  * `query_insert` → `insert`
  * `query_update` → `update`
  * `query_delete` → `delete`
* **keyspace-ref**\
[Keyspace Reference](#keyspace-reference)
* **user**\
A user name created by the Couchbase Server RBAC system.
* **group**\
A group name created by the Couchbase Server RBAC system.

**📌 NOTE**\
When granting roles to users, the keyword `USER` or `USERS` is optional.
However, when granting roles to groups, you must include the keyword `GROUP` or `GROUPS`.
You can use either the singular or plural form of these keywords as this does not affect the number of users or groups the role applies to.

### Keyspace Reference

```ebnf
keyspace-ref ::= keyspace-path | keyspace-partial
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-ref.png)

```ebnf
keyspace-path ::= ( namespace ':' )? bucket ( '.' scope '.' collection )?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-path.png)

```ebnf
keyspace-partial ::= collection
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/keyspace-partial.png)

The simple name or fully qualified name of a keyspace.
For more information about the syntax, see the [CREATE INDEX](n1ql-language-reference/createindex.adoc#keyspace-ref) statement.

## Usage

GRANT statements have two forms:

**{counter:form}. Unparameterized Roles**

```sqlpp
GRANT replication_admin, query_external_access
   TO cchaplan, jgleason;
```

**{counter:form}. Parameterized Roles**

```sqlpp
GRANT query_select, views_admin
   ON orders, customers
   TO bill, linda;
```

**📌 NOTE**\
Mixing of parameterized and unparameterized roles or syntax is not allowed and will create an error.

## Examples

**Grant the role of Cluster Admin to multiple users**

```sqlpp
GRANT cluster_admin TO david, michael, robin;
```

**Grant Query Select and Data Reader roles on the `travel-sample` keyspace to a specific user**

```sqlpp
GRANT query_select, data_reader ON `travel-sample` TO debby;
```

**Grant the role of Data Reader on the `travel-sample` keyspace to a specific group**

```sqlpp
GRANT data_reader ON `travel-sample` TO GROUP sales;
```
