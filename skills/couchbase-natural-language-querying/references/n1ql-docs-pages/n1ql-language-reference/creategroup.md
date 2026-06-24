# CREATE GROUP

The CREATE GROUP statement enables you to create a group.

## Purpose

Use the CREATE GROUP statement to define a new group within the Couchbase Server Role-Based Access Control (RBAC) system.
You can specify the group’s name, description, and assign it one or more roles.

By creating groups, you can organize users and assign roles collectively.
When you add users to a group, they automatically inherit the roles assigned to that group.

## RBAC Privileges

To execute the CREATE GROUP statement, you must have either the Full Admin or the Security Admin role.
For more information about user roles, see [Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
create-group ::= 'CREATE' 'GROUP' ( 'IF' 'NOT' 'EXISTS' )? name 
                 ( 'WITH' description )? 
                 ( 'ROLE' rbac-role | 'ROLES' rbac-role ( ',' rbac-role )* | 'NO' 'ROLES' )
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/create-group.png)

* **name**\
(Required) The unique identifier for the new group.
* **description**\
(Optional) A quoted string containing the description for the group.
* **rbac-role**\
(Required)
[Add Roles](#add-roles)

<dl><dt><strong>📌 NOTE</strong></dt><dd>

When creating a group, you can grant roles to them using one of the following options: `ROLE`, `ROLES`, or `NO ROLES`.
You can specify only one of these options per statement.

* `ROLE` assigns a single role to the group.
* `ROLES` assigns multiple roles to group (the names must be separated by commas).
* `NO ROLES` creates a group with no roles assigned.
This option has no effect during group creation.
</dd></dl>

### IF NOT EXISTS Clause

The optional `IF NOT EXISTS` clause enables the statement to complete successfully when the specified group already exists.
If a group with the same name already exists, then:

* If this clause is not present, an error is generated.
* If this clause is present, the statement does nothing and completes without error.

### Add Roles

```ebnf
rbac-role ::= role ( 'ON' keyspace-ref )?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/rbac-role.png)

* **role**\
One of the [RBAC role names predefined](learn:security/authorization-overview.adoc) by Couchbase Server.

  For the following roles, you can use their short forms as well:
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

Use keyspace reference to specify the target keyspace.
For more information about each element, see the [Keyspace Reference](n1ql-language-reference/from.adoc#from-keyspace-ref) section in the FROM clause.

## Examples

**Create a group `sales` and assign it the `query_select` role**

```sqlpp
CREATE GROUP sales ROLE query_select ON `travel-sample`.`inventory`.`airline`;
```

**Create a group `travelagents` and assign it multiple roles**

```sqlpp
CREATE GROUP travelagents
WITH "Sample travel agents group"
ROLES data_reader ON `travel-sample`.`inventory`.`airline`,
select ON `travel-sample`.`inventory`.`landmark`;
```

**Create a group `support` if it does not already exist**

```sqlpp
CREATE GROUP IF NOT EXISTS support ROLE query_update
ON `travel-sample`.`inventory`.`airport`;
```

## Related Links
* To create a new user, see [n1ql:n1ql-language-reference/createuser.adoc](n1ql:n1ql-language-reference/createuser.adoc).
* To update an existing group, see [n1ql:n1ql-language-reference/altergroup.adoc](n1ql:n1ql-language-reference/altergroup.adoc).
* To delete a group, see [n1ql:n1ql-language-reference/dropgroup.adoc](n1ql:n1ql-language-reference/dropgroup.adoc).
