# DROP USER

The DROP USER statement enables you to delete a user.

This statement permanently removes a user from the Couchbase Server Role-Based Access Control (RBAC) system.
It removes the user from all groups and revokes all roles and privileges assigned to that user.

## RBAC Privileges

To execute the DROP USER statement, you must have either the Full Admin or the Security Admin role.
For more information about user roles, see [Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
drop-user ::= 'DROP' 'USER' ( 'IF' 'EXISTS' )? username
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/drop-user.png)

* **username**\
(Required) The unique identifier of the local user you want to delete.

### IF EXISTS Clause

The optional `IF EXISTS` clause enables the statement to complete successfully when the specified user doesn’t exist.
If a user with the same username does not exist, then:

* If this clause is not present, an error is generated.
* If this clause is present, the statement does nothing and completes without error.

## Examples

**Delete a user named Bob**

```sqlpp
DROP USER Bob;
```

**Delete a user named David if they exist**

```sqlpp
DROP USER IF EXISTS David;
```

## Related Links
* To create a user, see [CREATE USER](n1ql-language-reference/createuser.adoc).
* To modify a user, see [ALTER USER](n1ql-language-reference/alteruser.adoc).
* For step by step procedures for managing users, see [Manage Users](manage:manage-security/manage-users-and-roles.adoc).
