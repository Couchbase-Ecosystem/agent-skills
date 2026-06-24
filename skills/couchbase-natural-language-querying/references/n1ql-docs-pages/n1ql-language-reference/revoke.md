# REVOKE

The REVOKE statement allows revoking of any RBAC roles from specific users or groups.

Roles can be of the following two types:

* **simple**\
Roles which apply generically to all keyspaces/resources in the cluster.

  For example: `cluster_admin` or `bucket_admin`
* **parameterized by a keyspace**\
Roles which are defined for the context of the specified keyspace only.
Specify the keyspace name after the keyword ON.

  For example: `pass:c[data_reader ON `travel-sample`]`\
  or `pass:c[query_select ON `travel-sample`.`inventory`.`airline`]`

**📌 NOTE**\
Only Full Administrators can run the REVOKE statement.
For more details about user roles, see [Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
revoke ::= revoke-user | revoke-group
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/revoke.png)

```ebnf
revoke-user ::= 'REVOKE' role ( ',' role )* ( 'ON' keyspace-ref ( ',' keyspace-ref )* )?
           'FROM' ( 'USER' | 'USERS' )? user ( ',' user )*
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/revoke-user.png)

```ebnf
revoke-group ::= 'REVOKE' role ( ',' role )* ( 'ON' keyspace-ref ( ',' keyspace-ref )* )?
           'FROM' ( 'GROUP' | 'GROUPS' ) group ( ',' group )*
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/revoke-group.png)

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
When revoking roles from users, the keyword `USER` or `USERS` is optional.
However, when revoking roles from groups, you must include the keyword `GROUP` or `GROUPS`.
You can use either the singular or plural form of these keywords as this does not affect the number of users or groups from which the role is revoked.

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

## Examples

**Revoke the Cluster Admin role from multiple users**

```sqlpp
REVOKE cluster_admin FROM david, michael, robin
```

**Revoke Query Select and Data Reader roles on the `travel-sample` keyspace from a specific user**

```sqlpp
REVOKE query_select, data_reader
  ON `travel-sample`
  FROM debby
```

**Revoke the Data Reader role on the `travel-sample` keyspace from a specific group**

```sqlpp
REVOKE query_update
  ON `travel-sample`
  FROM GROUP sales
```
