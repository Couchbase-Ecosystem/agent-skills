# ALTER GROUP

The ALTER GROUP statement enables you to update an existing group.

## Purpose

Use the ALTER GROUP statement to modify an existing group within the Couchbase Server Role-Based Access Control (RBAC) system.
You can update the group’s description and its roles.
You can either add new roles or remove all the existing ones.
When you update a role for a group, all users in the group inherit the updated permissions automatically.

**🔥 CAUTION**\
When you add new roles to a group, the ALTER GROUP statement replaces the group’s existing role assignments with the new ones you provide.
It updates the entire role list, so any existing roles not included in the new list will be removed.
If you want to add or remove specific roles without affecting the others, use the [GRANT](n1ql:n1ql-language-reference/grant.adoc) and [REVOKE](n1ql:n1ql-language-reference/revoke.adoc) statements instead.

## RBAC Privileges

To execute the ALTER GROUP statement, you must have either the Full Admin or the Security Admin role.
For more information about user roles, see [Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
alter-group ::= 'ALTER' 'GROUP' name ( 'WITH' description )? 
                ( 'ROLE' rbac-role | 'ROLES' rbac-role (',' rbac-role )* | 'NO' 'ROLES' )?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/alter-group.png)

* **name**\
(Required) The unique identifier of the group you want to update.
* **description**\
(Optional) A quoted string containing the updated description for the group.
* **rbac-role**\
(Optional)
[Update Roles](#update-roles)

<dl><dt><strong>📌 NOTE</strong></dt><dd>

When altering a group, you can update its roles using one of the following options: `ROLE`, `ROLES`, or `NO ROLES`.
You can specify only one of these options per statement.

* `ROLE` assigns a single role to the group.
* `ROLES` assigns multiple roles to group (the names must be separated by commas).
* `NO ROLES` removes all roles from the group.
</dd></dl>

### Update Roles

```ebnf
rbac-role ::= role ( 'ON' keyspace-ref )?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/rbac-role.png)

* **role**\
One of the [RBAC role names predefined](learn:security/authorization-overview.adoc) by Couchbase Server.

  The following roles have short forms that can be used as well:
  * `query_select` → `select`
  * `query_insert` → `insert`
  * `query_update` → `update`
  * `query_delete` → `delete`
* **keyspace-ref**\
[Keyspace Reference](#keyspace-reference)

#### Keyspace Reference

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

Use keyspace reference to specify the target for the update.
For more information about each element, see the [Keyspace Reference](n1ql-language-reference/from.adoc#from-keyspace-ref) section in the FROM clause.

## Examples

**Alter a group and update its description**

```sqlpp
ALTER GROUP support WITH "Support team for customer queries";
```

**Alter a group and add new roles**

```sqlpp
ALTER GROUP support
ROLES
query_select ON `travel-sample`.`inventory`.`airline`,
query_insert ON `travel-sample`.`inventory`.`airline`;
```

**Alter a group and remove all roles**

```sqlpp
ALTER GROUP support NO ROLES WITH "Currently unused group";
```

## Related Links
* To create a group, see [n1ql-language-reference/creategroup.adoc](n1ql-language-reference/creategroup.adoc).
* To delete a group, see [n1ql-language-reference/altergroup.adoc](n1ql-language-reference/altergroup.adoc).
* To create a new user, see [n1ql-language-reference/createuser.adoc](n1ql-language-reference/createuser.adoc).
