# DROP GROUP

The DROP GROUP statement enables you to delete a group.

## Purpose

You can use this statement to clean up groups that are no longer needed.

Deleting a group removes all roles and privileges associated with the group.
Users in the deleted group no longer inherit the roles granted to it.

## RBAC Privileges

To execute the DROP GROUP statement, you must have etiher the Full Admin or the Security Admin role.
For more information about user roles, see [Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
drop-group ::= 'DROP' 'GROUP' ('IF' 'EXISTS' )? groupname
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/drop-group.png)

* **groupname**\
(Required) The unique identifier of the group you want to delete.

### IF EXISTS Clause

The optional `IF EXISTS` clause enables the statement to complete successfully when the specified group doesn’t exist.
If a group with the same name does not exist, then:

* If this clause is not present, an error is generated.
* If this clause is present, the statement does nothing and completes without error.

## Examples

**Delete a group named `sales`**

```sqlpp
DROP GROUP sales;
```

**Delete a group named `support` if it exists**

```sqlpp
DROP GROUP IF EXISTS support;
```

## Related Links
* To create a group, see [n1ql-language-reference/creategroup.adoc](n1ql-language-reference/creategroup.adoc).
* To alter a group, see [n1ql-language-reference/altergroup.adoc](n1ql-language-reference/altergroup.adoc).
* For step-by-step procedures for managing groups, see [Manage Groups](manage:manage-security/manage-users-and-roles.adoc).
