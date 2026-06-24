# ALTER USER

The ALTER USER statement enables you to alter the details of an existing user.

## Purpose

Use the ALTER USER statement to update a local user’s attributes, such as their password, full name, and group.
You can add the user to new groups or remove them from all existing groups.

This statement helps manage access control and keeps user information up to date within Couchbase Server.

**🔥 CAUTION**\
When you add new groups to a user, the ALTER USER statement replaces the user’s existing group assignments with the new ones you provide.
It updates the entire group list, so any existing groups not included in the new list will be removed.

## RBAC Privileges

To execute the ALTER USER statement, you must have either the Full Admin or the Security Admin role.
For more information about user roles, see [Authorization](learn:security/authorization-overview.adoc).

## Syntax

```ebnf
alter-user ::= 'ALTER' 'USER' username ( 'PASSWORD' password )? 
                ( 'WITH' name )? 
                ( 'GROUP' group | 'GROUPS' group ( ',' group )* | 'NO' 'GROUPS' )?
```

![Syntax diagram: refer to source code listing](../../assets/images/n1ql-language-reference/alter-user.png)

* **username**\
(Required) The unique identifier of the local user.
* **password**\
(Optional) A quoted string containing the user’s new password.
It must be at least 6 characters long.
* **name**\
(Optional) A quoted string containing the user’s updated name.
* **group**\
(Optional) The group you want to assign the user to.

<dl><dt><strong>📌 NOTE</strong></dt><dd>

When altering a user, you can update their group using one of the following options: `GROUP`, `GROUPS`, or `NO GROUPS`.
You can specify only one of these options per statement.

* `GROUP` assigns the user to a single group.
* `GROUPS` assigns the user to multiple groups (the names must be separated by commas).
* `NO GROUPS` removes the user from all groups.
</dd></dl>

## Examples

**Change a user’s password and full name**

```sqlpp
ALTER USER Hilary PASSWORD "newpassword" WITH "Hilary Chloe";
```

**Assign a user to a new group**

```sqlpp
ALTER USER Alice GROUP support;
```

**Remove a user from existing groups**

```sqlpp
ALTER USER Bob NO GROUPS;
```

## Related Links
* To create a new user, see [n1ql:n1ql-language-reference/createuser.adoc](n1ql:n1ql-language-reference/createuser.adoc).
* To delete a user, see [n1ql:n1ql-language-reference/dropuser.adoc](n1ql:n1ql-language-reference/dropuser.adoc).
* To create a new group, see [n1ql:n1ql-language-reference/creategroup.adoc](n1ql:n1ql-language-reference/creategroup.adoc).
