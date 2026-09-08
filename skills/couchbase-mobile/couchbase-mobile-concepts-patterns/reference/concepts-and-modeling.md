## Terminology — App Services vs Sync Gateway

Capella App Services is a managed deployment of Sync Gateway. Users may use either Sync Gateway or App Services terms interchangeably — understand both and map them correctly. **Mirror the term the user uses** rather than forcing one vocabulary: if they say "sync function" or "Sync Gateway", respond in kind; if they say "Access Control Function" or "App Services", use those. Use the mapping below to translate silently between the two.

(Deployment note: a recipe that specifically targets App Services — e.g. `couchbase-mobile-cloud-edge-sync-app` — will naturally use App Services terms in its own workflow, script output, and generated artifacts, since that is the deployment target. This mirror-the-user guidance is about conversational explanation, not those fixed artifacts.)

| Sync Gateway term | App Services term |
|---|---|
| Sync Gateway (managed) | **App Services** |
| Sync Gateway Database | **App Endpoint** |
| Sync Function | **Access Control Function** (often abbreviated **ACF**) |
| SG Role | **App Role** |
| SG User / User | **App User** |
| SG Admin User | **App Services Admin Credential** |

**File and directory naming exception:** Use `sync-functions/` and `*-sync-function.js` as internal project artifact names only — these are code/file conventions, not user-facing terms. In all explanations, UI guidance, script output, and documentation, use App Services terminology.

---

## Core Concepts (explain simply to users)

**Couchbase Lite** = embedded NoSQL database inside the iOS app. Stores data as JSON documents. Works fully offline.

**Capella App Services** = managed cloud sync layer (built on Sync Gateway). Routes document changes between devices and the Capella cloud database over WebSocket.

**Replicator** = the sync engine inside Couchbase Lite. Runs in the background, pushes local changes up, pulls remote changes down. Reconnects automatically.

**Channel** = a named stream of documents. App Users subscribe to channels; documents are routed to channels by the Access Control Function. An App User only receives documents in channels they have access to.

**Two special channels:**
- **`!`** (the public channel) = every authenticated user automatically receives documents routed to `!`. Use it for shared read-only reference data.
- **`*`** (the star / "all channels" channel) = a principal granted `*` receives documents in **every** channel. Access to `*` is **never implicit — it must be granted explicitly**. Typical use: an admin/superuser who should see all data. (`*` grants read access to all channels; it is not a wildcard you route documents *to* — you still route each document to specific channels like `channel(assignee)`.) **Caveat:** `*` grants *reads* but does **not** satisfy `requireAccess("namedChannel")` — a `*`-only principal fails that check, so authorize an admin's writes via `requireRole()`, not `requireAccess()` (see the access-control skill, Rule 9).

Access to a channel can be granted **dynamically** in the Access Control Function via `access(user, channel)`, or **statically** at user/role creation via the Admin REST API (`admin_channels`, inside `collection_access` for named scopes). An admin can be given `*` either way; see `couchbase-mobile-access-control-function`.

**Access Control Function** = JavaScript function that runs on App Services for every document write. Controls which channels the document belongs to, who can read/write it, and validates data. Configured per collection on the App Endpoint.

**App Endpoint** = the App Services endpoint for your app. Each App Endpoint links to a bucket/scope and has Access Control Functions per collection.

**App User** = a mobile app user who syncs data with App Services via Couchbase Lite replication.

**App Role** = a named role assigned to App Users to control channel access (e.g. `admin` role grants the admin channel).

**App Services Admin Credential** = an admin user who can invoke the Admin REST API to create App Users and App Roles. This is NOT an App User — it does not sync data.

**Collections** = like tables (but schemaless JSON). Each collection has its own Access Control Function. Always placed inside a named scope.

**Scopes** = namespaces that group related collections, similar to schemas in a relational database. Every bucket has a `_default` scope (reserved for backward compatibility) and you can create named scopes.

---

## Data Modeling — Scopes and Collections (CRITICAL)

### Always use a named scope — never `_default`

The `_default` scope exists for backward compatibility with pre-7.0 Couchbase data. **New mobile apps must always use a named scope.**

**Why:**
- Named scopes provide secure isolation — per-scope access control in RBAC
- Efficient indexing — the Data Service can target specific collections
- Clean separation of app data from system/legacy data
- `_default` cannot be dropped and is a reserved namespace

**Naming convention:** Use the app domain or feature area as the scope name:

| App type | Recommended scope | Collections |
|---|---|---|
| Field task app | `fieldops` | `tasks`, `resources` |
| Todo app | `todo` | `items` |
| Insurance claims | `claims` | `submissions`, `assets` |
| Inventory | `inventory` | `items`, `categories` |

**In the script** (`COLLECTIONS` env var): always use `scope/collection` format with a named scope:
```bash
export COLLECTIONS='fieldops/tasks fieldops/resources'  # ✅ named scope
# NEVER:
export COLLECTIONS='_default/tasks'                     # ❌ _default scope
```

**In AppConfig.swift**: use the same named scope:
```swift
static let scopeName = "fieldops"   // ✅ matches COLLECTIONS scope
// NEVER:
static let scopeName = "_default"   // ❌
```

**In Couchbase Lite queries**: reference the named scope explicitly:
```swift
"SELECT META().id, * FROM fieldops.tasks WHERE type = 'task'"
```

---

## Architecture Pattern

```
[iOS App]
    ↕  local reads/writes (always fast, works offline)
[Couchbase Lite — embedded DB]
    ↕  WebSocket replication when online
[Capella App Services]
    ↕
[Couchbase Capella — cloud DB]
```

---

## Standard App Patterns

> **Every real mobile app needs at least two user types.** Someone creates and assigns work; someone does the work. Even a simple "todo" app needs an admin who can assign tasks to users — otherwise there's no way to get data onto a user's device. **Pattern 1 is the default for virtually all field/mobile apps.** Use Pattern 2 only as an addition for shared reference data.

### Pattern 1: Admin-Assigns (DEFAULT — use this for all document collections)

An admin creates documents and assigns them to users. The assigned user sees and updates their docs. Admin sees everything.

**Access matrix** (note create ≠ update):
- **Read:** the assignee (their own docs) + admin (all).
- **Create:** admin only (`requireRole("admin")` on create).
- **Update:** the assignee (their own doc) + admin. Reassign/close/delete: admin only (often with status-locking).

**Required fields on every document:** `type` (document type string), `assignee` (username of the person assigned the work).

**Document lifecycle:**
```
Admin creates doc with assignee = "alice"
  → Access Control Function: channel("alice") + channel("admin")
  → Alice's device pulls the doc (she's subscribed to her channel)
  → Alice updates status/notes
  → Admin sees the update in real time (subscribed to admin channel)
```

**Channel wiring:**

| Call | Purpose |
|---|---|
| `channel(assignee)` | Routes doc to the assignee's device |
| `channel("admin")` | Routes doc to all admin devices |
| `access(assignee, assignee)` | Dynamically grants assignee their channel |
| ~~`access("role:admin", "admin")`~~ | ❌ Not on App Services — the `role:` prefix works only on self-managed Sync Gateway (see access-control skill) |
| `requireAccess([assignee, "admin"])` | Only assignee or admin can read/write |

**Admin channel access — two valid patterns (pick one):**

**The correct place to grant channel access to a role is on the App Role itself** — set `admin_channels` when creating the role via the Admin REST API. Any user assigned that role will inherit the channels automatically. Do NOT rely solely on `admin_channels` on individual users, and do NOT use `access("role:admin", ...)` in the ACF.

**⚠️ CRITICAL — `collection_access` format required for named scopes:**
Flat top-level `admin_channels` in the role/user body is **Sync Gateway pre-collections syntax** and is silently ignored by App Services when your endpoint uses named scopes. The API returns 201/200 but the channels are never applied — nothing in the Capella UI or sync behavior will reflect them. **Always use `collection_access`.**

**Pattern A — explicit "admin" channel:**
```bash
# Scope and collection must match your COLLECTIONS env var (e.g. todo/todos → scope=todo, collection=todos)
# Role: collection_access grants admin channel to every user with this role
POST /_role/   {"name":"admin","collection_access":{"todo":{"todos":{"admin_channels":["admin"]}}}}

# Manager — admin_roles:["admin"] inherits collection_access from the role (no collection_access needed)
POST /_user/   {"name":"manager","password":"...","admin_roles":["admin"]}
# Regular user — collection_access channel must exactly match the username
POST /_user/   {"name":"alice","password":"...","collection_access":{"todo":{"todos":{"admin_channels":["alice"]}}}}
# ACF: channel(assignee); channel("admin"); access(assignee, assignee); requireAccess([assignee, "admin"]);
```

**Pattern B — star channel (`*`):**
```bash
# Role gets admin_channels: ["*"] — any user with this role receives ALL documents
POST /_role/   {"name":"admin","collection_access":{"todo":{"todos":{"admin_channels":["*"]}}}}
POST /_user/   {"name":"manager","password":"...","admin_roles":["admin"]}
POST /_user/   {"name":"alice","password":"...","collection_access":{"todo":{"todos":{"admin_channels":["alice"]}}}}
# ACF: channel(assignee); access(assignee, assignee);
#      then authorize: try { requireAccess([assignee]); } catch(e) { requireRole("admin"); }
# No channel("admin") needed — manager READS everything via * on the role.
# BUT "*" does NOT satisfy requireAccess() on a named channel, so gate the admin path
# with requireRole, not requireAccess([..,"admin"]). See access-control skill, Rule 9.
```

Build `collection_access` dynamically using the `build_collection_access()` helper (see `role-channel-rules.md` in the `couchbase-mobile-access-control-function` skill).

Either pattern is valid. Pattern A is more explicit; Pattern B is simpler if admin needs to see all documents without explicitly routing each doc to the admin channel.

### Pattern 2: Shared Read-Only Documents (optional addition)
Use when: all users need the same reference data (manuals, price lists, lookup tables).
- Channel = `"!"` (public channel — all authenticated users receive automatically)
- `requireRole("admin")` restricts writes to admins only
- Field users receive these automatically — no `admin_channels` needed

**Access matrix:**
- **Read:** everyone (all authenticated users, via `!`).
- **Create:** admin only.
- **Update:** admin only. (All writes — create and update — are admin-only; everyone else is read-only.)

### Pattern 3: Team/Group Documents
Use when: a group of users shares a workspace (a project, a store, a team).
- Channel = group ID (e.g., `"team-northeast"`)
- Grant members the team channel statically (`collection_access` / `admin_channels` on a team role or per user), not per-run `access()`.

**Access matrix:**
- **Read:** every member of the team + admin.
- **Create:** any team member (collaborative default) — or restrict to a lead (variant below).
- **Update:** any team member (on the team's docs) + admin. Delete: admin/lead.

**Who creates? Decide explicitly — this is the key choice for this pattern:**
- **Collaborative (default):** any team **member** can create documents in the team channel; the whole team (and admins) then sees them. The function routes `channel(teamId)` and gates with `requireAccess([teamId])` — no create restriction. This is what distinguishes Team/Group from Admin-Assigns.
- **Lead-creates variant:** restrict creation to a team lead/admin with `requireRole(...)` on create, while members read/update. This is Admin-Assigns applied at team granularity — combine the two patterns.

In both, an admin role normally sees across all teams (via `*` or by holding every team channel). State the creation rule in the generated function's header so it's unambiguous.

---

