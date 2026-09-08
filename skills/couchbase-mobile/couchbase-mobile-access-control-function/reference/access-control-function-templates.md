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

```javascript
function(doc, oldDoc) {
  if (doc.type == "YOUR_TYPE" || (doc._deleted && oldDoc && oldDoc.type == "YOUR_TYPE")) {

    // Read stable fields from oldDoc — never trust doc on update
    var assignee = oldDoc ? oldDoc.assignee : doc.assignee;

    if (!assignee) throw({forbidden: "assignee is required"});

    // Creates: manager (admin App Role) only — regular App Users cannot create
    if (!oldDoc) {
      requireRole("admin");   // NO role: prefix — App Services ACF uses bare role name
    }

    // Deletes: admin only
    if (doc._deleted) {
      requireRole("admin");
      return;
    }

    // Required fields
    if (!doc.title)  throw({forbidden: "title is required"});
    if (!doc.status) throw({forbidden: "status is required"});

    // Immutable fields on update
    if (oldDoc && !oldDoc._deleted) {
      if (doc.type     !== oldDoc.type)     throw({forbidden: "type cannot be changed"});
      if (doc.assignee !== oldDoc.assignee) requireRole("admin");
      if (doc.createdAt && oldDoc.createdAt && doc.createdAt !== oldDoc.createdAt)
        throw({forbidden: "createdAt cannot be changed"});
    }

    // Route doc to assignee's channel AND admin channel
    channel(assignee);
    channel("admin");

    // Dynamically grant assignee access to their personal channel.
    // DO NOT call access("role:admin", ...) — role: prefix is invalid in App Services ACFs.
    // Admin gets "admin" channel access from the role's admin_channels — set at role creation, not here.
    access(assignee, assignee);

    // Gate: only the assignee or a user with access to "admin" channel can read/write.
    // Manager passes because the admin App Role has admin_channels: ["admin"].
    requireAccess([assignee, "admin"]);
  }
}
```

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
    access(assignee, assignee);

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

For read-only reference data visible to all App Users (manuals, lookup tables, etc.).

```javascript
function(doc, oldDoc) {
  if (doc.type == "REFERENCE_TYPE" || (doc._deleted && oldDoc && oldDoc.type == "REFERENCE_TYPE")) {

    // Only admin App Role can write reference documents
    requireRole("admin");

    if (doc._deleted) { return; }

    if (!doc.title) throw({forbidden: "title is required"});

    if (oldDoc && !oldDoc._deleted) {
      if (doc.type !== oldDoc.type) throw({forbidden: "type cannot be changed"});
    }

    channel("!");       // "!" = public channel — ALL authenticated App Users receive automatically
    channel("admin");

    // Admin_channels grants admin access to "admin" channel at user creation — no access() call needed.
    // No requireAccess() needed — "!" channel covers all authenticated App Users
  }
}
```

---

