### Access Control Function Template — Admin-Assigns Pattern (DEFAULT)

Use this for every document collection. The `manager` App User (with `admin` App Role) creates and assigns documents; regular App Users can only update their own assigned documents.

> **How admin channel access works — critical linkage:**
> The ACF routes documents to `channel("admin")` (Pattern A) or relies on `*` (Pattern B).
> `requireAccess(["admin"])` passes for the manager because the **`admin` App Role is created with `admin_channels: ["admin"]`** (Pattern A) or `admin_channels: ["*"]` (Pattern B) via the Admin REST API.
> The role is what grants the manager access to the admin channel — NOT anything in the ACF.
> **When generating the ACF, you MUST also generate the matching role creation:**
> - Pattern A ACF → `POST /_role/ {"name":"admin","admin_channels":["admin"]}`
> - Pattern B ACF → `POST /_role/ {"name":"admin","admin_channels":["*"]}`

**Pattern A — explicit "admin" channel (DEFAULT — use this unless told otherwise):**

The complete, fully-annotated template is `assets/admin-assigns-sync-function.js` — copy it and follow its `ADAPT:` comments (replace `"task"` with your document type, `assignee` with your ownership field if different, and add your schema's required/immutable-field checks). In outline: creates and deletes require `requireRole("admin")` (no `role:` prefix on App Services — Rule A); reassigning the `assignee` field or editing a locked/`closed` doc also requires it; the doc is routed with `channel(assignee)` and `channel("admin")`; no `access(assignee, assignee)` call is needed — the assignee already has their own channel from user creation, and admin channel access likewise comes from the role's `admin_channels`, not from `access()` here (Rule B); the gate is `requireAccess([assignee, "admin"])`, which passes for either principal (Rule 7 — OR, not AND).

**Corresponding role + user creation (MUST match Pattern A ACF — use `collection_access`, not flat `admin_channels`):**
```bash
# Flat admin_channels is silently ignored for named scopes — use collection_access
POST /_role/  {"name":"admin","collection_access":{"todo":{"todos":{"admin_channels":["admin"]}}}}
POST /_user/  {"name":"manager","password":"...","admin_roles":["admin"]}  # inherits from role
POST /_user/  {"name":"alice","password":"...","collection_access":{"todo":{"todos":{"admin_channels":["alice"]}}}}
# Use build_collection_access() in the script to build this dynamically from COLLECTIONS env var
```

---

**Pattern B — star channel (use when admin should see ALL documents without explicit routing):**

> This is the only complete copy of the star-channel design in this skill — there is no matching `.js` asset for it (only Design A is shipped, as `assets/admin-assigns-sync-function.js`). If this pattern turns out to be used often enough to warrant one, add `assets/admin-assigns-star-sync-function.js` mirroring the code below rather than copying it to a third place.

```javascript
function(doc, oldDoc) {
  if (doc.type == "YOUR_TYPE" || (doc._deleted && oldDoc && oldDoc.type == "YOUR_TYPE")) {

    var assignee = oldDoc ? oldDoc.assignee : doc.assignee;

    if (!assignee) throw({forbidden: "assignee is required"});

    if (!oldDoc) { requireRole("admin"); }

    if (doc._deleted) {
      requireRole("admin");
      return;
    }

    if (!doc.title)  throw({forbidden: "title is required"});
    if (!doc.status) throw({forbidden: "status is required"});

    if (oldDoc && !oldDoc._deleted) {
      if (doc.type     !== oldDoc.type)     throw({forbidden: "type cannot be changed"});
      if (doc.assignee !== oldDoc.assignee) requireRole("admin");
    }

    // Route only to assignee's channel — no channel("admin") needed.
    // Manager receives ALL docs via admin_channels: ["*"] on the role (read/replication).
    channel(assignee);
    // NOTE: no access(assignee, assignee) call here — the assignee's own channel grant
    // comes from user creation (admin_channels/collection_access set to their username —
    // see below), so a per-document access() call would be redundant on every write.

    // IMPORTANT: a "*" grant does NOT satisfy requireAccess() on a named channel (Rule 9).
    // So the manager cannot pass requireAccess([assignee]) via "*". Authorize the two
    // paths separately: the assignee by channel, the admin by role.
    try {
      requireAccess([assignee]);   // assignee reads/writes their own doc
    } catch (e) {
      requireRole("admin");        // manager/admin ("*") authorized by role instead
    }
  }
}
```

**Corresponding role + user creation (MUST match Pattern B ACF — use `collection_access`, not flat `admin_channels`):**
```bash
# Flat admin_channels is silently ignored for named scopes — use collection_access
POST /_role/  {"name":"admin","collection_access":{"todo":{"todos":{"admin_channels":["*"]}}}}
POST /_user/  {"name":"manager","password":"...","admin_roles":["admin"]}
POST /_user/  {"name":"alice","password":"...","collection_access":{"todo":{"todos":{"admin_channels":["alice"]}}}}
# Use build_collection_access() in the script to build this dynamically from COLLECTIONS env var
```

### Access Control Function Template — Shared Reference Documents

For read-only reference data visible to all App Users (manuals, lookup tables, etc.). The complete,
fully-annotated template is `assets/shared-reference-sync-function.js` — copy it and follow its
`ADAPT:` comments (replace `"resource"` with your document type, add your schema's field validation).
In outline: only `requireRole("admin")` gates create/edit/delete; deletes return immediately
(tombstones need no field validation); documents route only to the public `channel("!")`, which every
authenticated App User already receives — there is no `channel("admin")` and no `requireAccess()` call
in this pattern, since nothing here needs gating beyond the create/edit/delete check above.

---

