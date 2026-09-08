## Admin Access Patterns — the menu

How to give an "admin" (a principal who can see/manage more than a regular user) access, from simplest to most selective. Pick based on how much control you need over *which* documents/channels the admin reaches. **Start from the FieldTaskTracker approach (Option 3) and move to another option only if the app needs it.**

Two independent choices run through all of these:
- **Principal type:** an App **Role** named `admin` (recommended — every user with the role inherits the access) vs. a single App **User** named `admin` (fine for exactly one admin, but a role is conceptually cleaner and scales).
- **Grant mechanism:** **static** via the Admin REST API at role/user creation (`admin_channels`, inside `collection_access` for named scopes) vs. **dynamic** via `access(principal, channel)` inside the Access Control Function.

> **Performance rule (important):** the Access Control Function runs on **every document write**. A channel grant that never changes (like an admin's access) should be set **once, statically via REST** — not re-issued through `access()` on every function run, which is redundant and expensive. Use `access()` only for grants that are genuinely data-driven and per-user (e.g. granting each user their own channel).
>
> On App Services, granting a **role** via `access()` is also unreliable (no `role:` prefix — see `role-channel-rules.md`), which is a second reason to grant role/admin access statically.

> **"admin" is two independent names.** A role/user named `admin` and a channel named `admin` are separate identifiers that share a string only by convention — the principal (who) and the channel (which documents) are unrelated. Rename either freely (role `managers`, channel `all-tasks`). Also note the `channel("admin")` routing line in the function belongs **only to the named-channel design (Option 3)**. With the `*` design (Option 1), the admin already receives every channel, so you **omit `channel("admin")`** entirely. But note `*` does **not** satisfy `requireAccess()` on a named channel (Rule 9), so authorize the admin write-path with `requireRole()` — e.g. `try { requireAccess([assignee]); } catch (e) { requireRole("admin"); }` — not `requireAccess([assignee, "admin"])`.

### Option 1 — Role `admin` with `*` (RECOMMENDED for "admin sees everything")

A role named `admin` granted the `*` (all-channels) channel, set statically via REST. Every user with `admin_roles: ["admin"]` inherits access to all channels automatically. No per-document admin routing needed in the function.

```bash
# static, once — named scope → inside collection_access
POST /_role/  {"name":"admin","collection_access":{"fieldops":{"tasks":{"admin_channels":["*"]}}}}
POST /_user/  {"name":"manager","password":"…","admin_roles":["admin"]}   # inherits *
```

Use when: admins should see **all** data. Cleanest and cheapest for *reads*. Similar in spirit to FieldTaskTracker's admin role, but using `*` so you don't route each doc to a named admin channel. **Caveat:** if your function gates writes with `requireAccess()` on a named channel, `*` alone won't authorize the admin (Rule 9) — wrap that gate with `requireRole("admin")` as shown in `admin-assigns-sync-function.js`, or use Option 3 (named admin channel), which composes with `requireAccess()` directly.

### Option 2 — User `admin` with `*`

Same as Option 1 but granted directly to a single App **User** instead of a role.

```bash
POST /_user/  {"name":"admin","password":"…","collection_access":{"fieldops":{"tasks":{"admin_channels":["*"]}}}}
```

Use when: there is exactly **one** admin and you don't want a role. Works, but prefer the role (Option 1) — roles scale to multiple admins and keep access decoupled from a specific account.

### Option 3 — Role/User `admin` + named `admin` channel (FieldTaskTracker's approach — start here)

The function routes each document to both the user's private channel **and** a shared `admin` channel; the admin principal is granted the `admin` channel. Grant that channel **once via REST** (`admin_channels`), not via `access()` every run.

```javascript
// in the function
channel(assignee);   // per-user private channel
channel("admin");    // shared admin channel
access(assignee, assignee);          // dynamic, per-user — correct use of access()
// do NOT grant the admin channel here every run — grant it once via REST (below)
requireAccess([assignee, "admin"]);
```
```bash
# static, once
POST /_role/  {"name":"admin","collection_access":{"fieldops":{"tasks":{"admin_channels":["admin"]}}}}
```

Use when: you want admins to see everything **that the function explicitly routes to the `admin` channel** — i.e. you keep a named, auditable "admin stream" rather than blanket `*`. This is FieldTaskTracker's model and a good default when "all channels" is broader than you want.

### Option 4 — Role/User `admin` + access to specific user private channels

The function routes documents **only** to per-user private channels (no shared admin channel). The admin is then granted access to selected users' private channels — statically via REST for a fixed set, or dynamically via `access()` when the set is data-driven.

```javascript
channel(assignee);                 // only the user's private channel
access(assignee, assignee);        // user sees their own docs
// admin access granted out-of-band (REST) or, if data-driven, via access() to chosen channels
```

Use when: the admin should see only a **selective subset** of users/channels (e.g. a regional supervisor over specific field workers), not everything.

### Choosing

| Need | Option |
|---|---|
| Admin sees **all** data, multiple admins | **1** (role + `*`) — recommended |
| Admin sees all data, exactly one admin, no role | 2 (user + `*`) |
| Admin sees a curated "admin stream" of routed docs | **3** (named `admin` channel) — FieldTaskTracker |
| Admin sees a **selective subset** of user channels | 4 (grant specific private channels) |

Options 3 and 4 trade a little more function logic for finer control over exactly which documents/channels the admin reaches. Options 1 and 2 are simplest when "admin = sees everything."

### Documentation references

- Channels & security: https://docs.couchbase.com/cloud/app-services/channels/channels.html
- Access control & data validation function: https://docs.couchbase.com/cloud/app-services/deployment/access-control-data-validation.html
- Create App Roles: https://docs.couchbase.com/cloud/app-services/user-management/create-app-role.html
- Create App Users: https://docs.couchbase.com/cloud/app-services/user-management/create-user.html
- Admin REST API reference: https://docs.couchbase.com/cloud/app-services/references/rest_api_admin.html
