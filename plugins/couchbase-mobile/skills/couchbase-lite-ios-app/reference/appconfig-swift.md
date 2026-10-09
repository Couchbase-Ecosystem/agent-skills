### Generated AppConfig.swift — required constants

```swift
enum AppConfig {
    static let databaseName    = "FieldOpsDB"

    // Named scope — NEVER "_default" for app data
    static let scopeName       = "fieldops"   // matches COLLECTIONS env var scope

    // One constant per collection
    static let tasksCollection = "tasks"
    static let assetsCollection = "assets"

    // Channels
    static let adminChannel    = "admin"      // channel for App Users with admin App Role

    // The manager App User has the admin App Role and sees all documents.
    // Must match MANAGER_USER env var used in setup-capella.sh (default: "manager").
    // Distinct from the App Services Admin Credential (infrastructure only — not a mobile user).
    static let managerUsername = "manager"
}
```

**`isAdmin` in `AuthState` must use `AppConfig.managerUsername`**, not hardcoded `"admin"`:
```swift
// WRONG — "admin" is the App Services Admin Credential, not an App User:
self.isAdmin = (username == "admin")

// CORRECT — "manager" is the App User with admin App Role:
self.isAdmin = (username == AppConfig.managerUsername)
```

The `scopeName` in `AppConfig.swift` must exactly match the scope used in:
- `COLLECTIONS` env var for `setup-capella.sh` (e.g. `fieldops/tasks fieldops/assets`)
- CBL queries: `"SELECT META().id, * FROM fieldops.tasks WHERE ..."`
- CBL collection open: `database.createCollection(name: "tasks", scope: "fieldops")`
- Access Control Function header comment

Domain examples with correct scope naming:

| Domain | Scope | Collections | COLLECTIONS env var | Endpoint name |
|---|---|---|---|---|
| Insurance claims | `claims` | `submissions`, `assets` | `claims/submissions claims/assets` | `claims-app` |
| Field inspection | `fieldops` | `inspections`, `assets` | `fieldops/inspections fieldops/assets` | `fieldtracker` |
| Todo / task app | `todo` | `todos` | `todo/todos` | `todosync` |
| Inventory | `inventory` | `products`, `categories` | `inventory/products inventory/categories` | `inventory-app` |

