## Worked Example — Comprehensive Access Model (FieldTaskTracker)

A self-contained reference for the **full users + roles + channels** access model. Use this when the app needs more than store/tenant isolation — i.e. an admin who sees everything, per-user private data, and shared read-only data, all in one endpoint. (This fills the gap left by the public Couchbase Retail Demo, whose access model is simple store isolation.)

> The patterns here were distilled from an internal example app (FieldTaskTracker) that is **not** bundled or published. This doc is self-contained — you do not need that app.

> This captures the *model* so the skill does not depend on the app source being reachable once published. The access control functions below use `requireRole("admin")` — no `role:` prefix, unlike self-managed Sync Gateway (see `role-channel-rules.md` Rule A, confirmed via docs and a live test). Admin channel access is granted via `admin_channels` on the role rather than a per-document `access()` call -- a design choice for a one-time grant, not a proven platform limitation of `access()` (see Rule B: the earlier claim that `access()` has no role-principal form on App Services at all was never actually verified and isn't supported by Couchbase's own `access()` docs).
>
> **FieldTaskTracker's bundled `.js`** used `requireRole("role:admin")` / `access(["role:admin"], …)` — that code is Sync Gateway-only and does not work on App Services, where the prefixed role form matches nothing. (A 2026-09-22 edit to this doc claimed otherwise and rewrote the examples to add the prefix back; that edit was itself wrong and has been reverted -- see `role-channel-rules.md` Rule A for the verification.)

### The model in one paragraph

Two collections in one endpoint. `tasks` are **per-user**: each task is routed to the assignee's personal channel (their username) and to an `admin` channel; a field worker sees only their own tasks, an admin sees all. `resources` are **shared read-only**: routed to the public `!` channel that every authenticated user receives, writable by admins only. Admins are a **role** whose all-access comes from `admin_channels` set on the role at creation, so no per-document grant is needed for them.

### Principals

| Principal | Type | How it gets access |
|---|---|---|
| Field worker (e.g. `alice`) | App User | Dynamic `access(username, username)` in the tasks function grants their personal channel; every user implicitly receives `!`. |
| Admin | App Role (`admin`) | Role created with `admin_channels` covering the `admin` channel (and `!`). Users in the role inherit it — **no `access()` call in the function**. |

### Access pattern summary

| Action | Field worker | Admin |
|---|---|---|
| Create task | ✗ (admin-assigns) | ✓ |
| Read/update own task | ✓ | ✓ (any task) |
| Reassign task | ✗ | ✓ |
| Modify a `closed` task | ✗ (locked) | ✓ |
| Delete task | ✗ | ✓ |
| Read resources | ✓ | ✓ |
| Create/edit/delete resources | ✗ | ✓ |

### `tasks` — per-user + admin (corrected idiom)

```javascript
function(doc, oldDoc) {
  if (doc.type == "task" || (doc._deleted && oldDoc && oldDoc.type == "task")) {
    var assignee = oldDoc ? oldDoc.assignee : doc.assignee;
    if (!assignee) throw({forbidden: "Task must have an assignee"});

    // Deletes: admin only (tombstone inherits channels)
    if (doc._deleted) { requireRole("admin"); return; }

    if (!doc.title)  throw({forbidden: "title is required"});
    if (!doc.status) throw({forbidden: "status is required"});

    if (oldDoc && !oldDoc._deleted) {
      if (doc.type !== oldDoc.type)         throw({forbidden: "type cannot be changed"});
      if (doc.assignee !== oldDoc.assignee) requireRole("admin");   // only admin reassigns
      if (oldDoc.status === "closed")       requireRole("admin");   // closed = locked for non-admins
    }

    channel(assignee);          // per-user channel
    channel("admin");           // admin channel (admins receive via role admin_channels)
    // No access(assignee, assignee) here — the worker already has access to their own channel
    // from user creation (admin_channels/collection_access set to their username). Admin access
    // likewise comes from admin_channels on the role, set once, not re-issued per write.
    requireAccess([assignee, "admin"]);
  }
}
```

### `resources` — shared read-only (corrected idiom)

```javascript
function(doc, oldDoc) {
  if (doc.type == "resource" || (doc._deleted && oldDoc && oldDoc.type == "resource")) {
    if (doc._deleted) { requireRole("admin"); return; }   // admin-only delete
    if (!doc.title) throw({forbidden: "title is required"});
    if (oldDoc && !oldDoc._deleted && doc.type !== oldDoc.type)
      throw({forbidden: "type cannot be changed"});
    requireRole("admin");   // only admin can create/edit
    channel("!");           // public channel — all authenticated users receive it
  }
}
```

### Two ways to grant a principal channel access

Channel access can be granted **dynamically** or **statically** — both are valid, and admins can use either:

1. **Dynamically, inside the function** via `access(principal, channel)` — evaluated per document as data flows. In this skill's patterns a worker's private channel is always named after their username, so `admin_channels`/`collection_access` set at user creation already grants it — an `access(assignee, assignee)` call in the function is redundant. Granting a *role* this way (`access(["role:admin"], channel)`) is documented as valid by Couchbase for the same engine App Services runs, with no stated Capella-specific carve-out -- but this skill has not independently verified it live, and uses a static role grant (below) regardless, since that only needs to happen once rather than per write.
2. **Statically, at principal creation** via the Admin REST API — set `admin_channels` on a User or Role. For **named scopes this goes inside `collection_access`** per scope/collection (flat `admin_channels` is ignored — see `role-channel-rules.md`).

### The `*` (star) channel — "all channels"

`*` is the special channel meaning **every channel**. A principal granted `*` receives documents in all channels. It is **never implicit** — it must be granted explicitly. This is the clean way to make an admin see *everything* without routing each document to a shared channel.

> For the full menu of admin designs (role vs user, `*` vs named vs selective channels, static vs dynamic grants) and how to choose, see `admin-access-patterns.md`.

So the admin role has two equally valid designs:
- **Named admin channel** (what this example uses): route docs with `channel("admin")` and grant the role the `admin` channel. Explicit about what admins receive.
- **Star channel**: grant the admin role `admin_channels: ["*"]` (inside `collection_access` for named scopes). Admins then receive all documents with no per-document `channel("admin")` routing needed. Simpler when admins should truly see all data.

### Role/user provisioning (App Services)

- Create the `admin` **role** with `collection_access` granting either the `admin` channel **or `*`** (and `!`) on the relevant scope/collections — see `role-channel-rules.md` and `couchbase-appservices-provisioning`.
- Create field-worker **App Users**; their username **is** their channel — no channel config needed on the user, the tasks function grants it dynamically via `access()`.

### Client-side reflection (iOS)

The client does not enforce access — it mirrors the model. From FieldTaskTracker's `AppConfig`:

```
publicChannel = "!"     // shared read-only
adminChannel  = "admin" // admin fan-out
adminRole     = "admin" // matches the App Role name (no "role:" prefix in app code)
```

Login uses the App User's username/password via `BasicAuthenticator`; the username doubles as the personal channel. Both collections are added to one replicator (`.pushAndPull`, continuous). Status-based locking (`closed`) is enforced server-side by the function above and reflected in the UI (`TaskStatus.isLocked`).

### Determining the user's role on the client (`isAdmin`)

The role-gated UI needs to know whether the signed-in user is an admin, but the Couchbase Lite SDK does not expose the App Services role list to the client. Don't hardcode it. Recommended approaches, best first:

1. **Synced profile document (recommended, offline-first).** Maintain a `profile::<username>` document routed to the user's own channel, containing `{ "roles": ["admin"] }` (or `"user"`). The app reads it from the local database after first sync and sets `isAdmin`. Works offline once synced, and the role travels with normal replication — no extra network call.

```swift
// after login + first sync
if let profile = try collection.document(id: "profile::\(username)"),
   let roles = profile.array(forKey: "roles")?.toArray() as? [String] {
    authState.isAdmin = roles.contains("admin")
}
```

2. **Convention (simple, weaker).** Treat specific usernames as admins (e.g. a `manager`/`admin` account). Fine for demos; brittle for production because role changes require an app change.

Whichever you choose, remember this only drives **UI affordances** — the access control function is the real enforcement, so a mis-derived `isAdmin` can hide/show buttons but cannot grant or deny actual data access.

### When to prefer this vs. store-isolation

Use this comprehensive model when a single endpoint must serve **an admin who sees everything + per-user private data + shared data**. If instead each tenant is fully isolated (like the Retail Demo's per-store scope + one user per store), the simpler endpoint/scope-isolation model is sufficient and needs little or no channel logic.
